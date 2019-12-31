CREATE OR REPLACE FUNCTION F_ACTIVATION_REQUEST RETURN SYS_REFCURSOR
IS 
/* 
Данная функция выводит (для SCHEDULER-a SLR) список карт, для которых требуется активация. Эту функцию SCHEDULER SLR-a вызывает каждые N секунд. 
Функция также рассчитана на одновременное использование несколькими SLR-ами, выдавая каждому из них свой набор КЭО
для параллельной обработки стоящих в очереди на активацию наборов строк (КЭО).
При этом исключена возможность попадания одной и той же КЭО нескольким SLR-ам.
*/

   CURSOR_CARDS      CB.REF_CURSOR;
   F_CARDS                 SYS_REFCURSOR;

   U_MSISDN               INTEGER; 
   U_ID_ACTIVATION    INTEGER;
   
   U_DATE                   DATE;
   U_ID_SELECTION     INTEGER;
   
   U_QUEUE_FOR_SCHEDULER  INTEGER;
   U_LAST_SECONDS INTEGER;
   
BEGIN

    P_CHECK_ACTIVATED_RETURN; ---- Отметим те Заявки, которые уже были завершены успешной активацией ----

    U_DATE := sysdate;
    U_LAST_SECONDS := 30; ---- Количество секунд, которое надо подождать, прежде чем выбирать строки, которые уже были выбраны ранее ----
    
    U_QUEUE_FOR_SCHEDULER := CB.CA_QUEUE_FOR_SCHEDULER; ---- Количество КЭО которое выдается для SLR за 1 проход SCHEDULER-а ----
    
    IF U_QUEUE_FOR_SCHEDULER < 1 THEN
        OPEN F_CARDS FOR select null from dual WHERE 0=1;
        RETURN(F_CARDS); 
    END IF;
    
    
    IF U_QUEUE_FOR_SCHEDULER > 100 THEN
        U_QUEUE_FOR_SCHEDULER := 100; 
    END IF;
    

    /* Находим наименьший ID активации где КЭО ещё не были в процессе активации */
    SELECT MIN(ID_ACTIVATION) INTO U_ID_ACTIVATION  
        FROM TA_CARD 
            WHERE 
                ( (R_CODE IS NULL) AND (R_MESSAGE IS NULL) )
                AND
                ( NVL(LAST_SELECTED, U_DATE - 1 ) < ( U_DATE - U_LAST_SECONDS * CB.C_ONE_SECOND ) );---- Последние N секунд эти карты не выбирались для активации ----
    
    /* Находим номер телефона для активации КЭО */
    SELECT MSISDN INTO U_MSISDN FROM TA_ACTIVATION WHERE ID_ACTIVATION = U_ID_ACTIVATION;
    
    
    IF ( NVL(U_ID_ACTIVATION, CB.C_MINUS_ONE ) = CB.C_MINUS_ONE ) OR (NVL(U_MSISDN, CB.C_MINUS_ONE) = CB.C_MINUS_ONE ) THEN
        OPEN F_CARDS FOR select null from dual WHERE 0=1;
        RETURN(F_CARDS); 
    END IF;
    
    /* Выбираем наименьший ID Заявки  (готовый к активации),  еще не все карты которого активировались */
   /*SELECT MIN(ID_RETURN) INTO U_ID_RETURN 
       FROM TA_ACTIVATION 
           WHERE ID_ACTIVATION = U_ID_ACTIVATION;*/    /*  and FLAG_COMMITED IS NULL   and */
                     
      U_ID_SELECTION := SEQ_CARD_ACTIVATION.nextval; 
   
      FOR CURSOR_CARDS 
      IN 
      (
      
        SELECT XCRD_ID FROM
        (
           SELECT  ICC, XCRD_ID 
           FROM TA_CARD 
           WHERE
           ID_ACTIVATION = U_ID_ACTIVATION
           AND
           ( (R_CODE IS NULL) AND (R_MESSAGE IS NULL) )
           AND
           ( NVL(LAST_SELECTED, U_DATE - 1) < ( U_DATE - U_LAST_SECONDS * CB.C_ONE_SECOND )  ) ---- Последние N секунд эти карты не выбирались для активации ----
           ORDER BY ICC
        )
       WHERE ROWNUM <= U_QUEUE_FOR_SCHEDULER  ---- выдаём для SLR не более N   КЭО за 1 раз ----

      )
      
      LOOP
      
            UPDATE TA_CARD 
                SET 
                    LAST_SELECTED = U_DATE,
                    ID_SELECTION  =  U_ID_SELECTION
                WHERE  
                    ID_ACTIVATION = U_ID_ACTIVATION 
                    AND 
                    XCRD_ID = CURSOR_CARDS.XCRD_ID;
                
      END LOOP;   
           
      COMMIT;     
           
           

   OPEN F_CARDS FOR 
   
   SELECT U_MSISDN as MSISDN, F_GET_PIN(ICC) as PIN, ICC, XCRD_ID 
        FROM TA_CARD 
            WHERE 
                ID_SELECTION = U_ID_SELECTION
                AND
                ID_ACTIVATION = U_ID_ACTIVATION
    ORDER BY ICC;            
   
   

   

   


   
  RETURN F_CARDS;

EXCEPTION 
    WHEN OTHERS THEN

        ROLLBACK;   
        OPEN F_CARDS FOR select null from dual WHERE 0=1;
        RETURN(F_CARDS); 
   
END;
