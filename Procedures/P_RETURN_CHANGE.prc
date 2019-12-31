CREATE OR REPLACE PROCEDURE P_RETURN_CHANGE /* GRANT EXECUTE ON P_RETURN_CREATE  TO CARD_BACK_ROLE */
 /*
Процедура позволяет вносить изменения значений некоторых атрибутов сущности "Возврат".
*/
 ( 
 I_ID_RETURN IN INTEGER,  ---- Идентификатор Заявки (Возврата) ----
 I_ID_BANK IN INTEGER DEFAULT -1, ---- ID банка посетителя ----
 I_BANK_ACCOUNT IN VARCHAR2 DEFAULT '?' , ---- Номер счёта посетителя в указанном банке 
 I_PERSON_ACCOUNT IN VARCHAR2 DEFAULT '?' , ---- Номер личного счёта к которому привязана карта
 I_ID_PAYMENT_TYPE IN INTEGER DEFAULT -1,  ---- Тип платежа ----
 I_ID_STATUS IN INTEGER DEFAULT -1, ---- Статус Заявки (Возврата) ----

 O_CODE  OUT  INTEGER, 
 O_MESSAGE OUT VARCHAR2,
 O_REFCURSOR OUT SYS_REFCURSOR
 ) IS 
 
 V_ID_BANK  INTEGER ; ---- Новый ID_BANK
 V_BANK_ACCOUNT  VARCHAR2(200) ; ---- Новый BANK ACCOUNT
 V_PERSON_ACCOUNT  VARCHAR2(200) ; ---- Новый PERSON ACCOUNT
 V_ID_PAYMENT_TYPE INTEGER ; ---- Новый ID_PAYMENT_TYPE
 V_ID_STATUS INTEGER ; ---- Новый ID_STATUS
 
 W_ID_BANK  INTEGER ; ---- Текущий ID_BANK
 W_BANK_ACCOUNT  VARCHAR2(200) ; ---- Текущий BANK ACCOUNT
 W_PERSON_ACCOUNT  VARCHAR2(200) ; ---- Текущий PERSON ACCOUNT
 W_ID_PAYMENT_TYPE INTEGER ; ---- Текущий ID_PAYMENT_TYPE
 W_ID_STATUS INTEGER ; ---- Текущий ID_STATUS
 
 X_COUNT INTEGER; 
 X_CODE INTEGER; 
 X_MESSAGE VARCHAR2(2000);
 


                                    /* Проверим, если заявка закрыта, то можно ли её переоткрыть */
                                    PROCEDURE P_CHECK_REOPEN (INNER_CODE OUT INTEGER)
                                    IS
                                    
                                    U_ID_STATUS INTEGER; U_ID_RETURN INTEGER; U_MIN INTEGER; U_MAX INTEGER;
                                    
                                    BEGIN
                                    
                                        SELECT ID_STATUS INTO U_ID_STATUS FROM T_RETURN WHERE ID_RETURN =  I_ID_RETURN;
                                     
                                        INNER_CODE := 0;
                                        U_ID_RETURN := -1; 
                                        
                                        /*  Проверим, нет ли пересечения диапазонов вновь открываемой Заявки с уже имеющимися */
                                        
                                         IF (U_ID_STATUS = CB.ST_CANCELED) AND (V_ID_STATUS != CB.ST_CANCELED) THEN
                                         
                                                    SELECT MAX(ID_RETURN), MAX(RANGE_MIN), MAX(RANGE_MAX) 
                                                    INTO U_ID_RETURN, U_MIN, U_MAX
                                                    FROM
                                                    (
                                                            SELECT ID_RETURN, RANGE_MIN, RANGE_MAX FROM
                                                            (
                                                            
                                                                        SELECT A.* FROM 
                                                                        (
                                                                            SELECT E.* 
                                                                                FROM 
                                                                                    T_RETURN_RANGE E
                                                                                        INNER JOIN T_RETURN F
                                                                                            ON E.ID_RETURN = F.ID_RETURN
                                                                                                WHERE E.ID_RETURN != I_ID_RETURN and F.ID_STATUS != CB.ST_CANCELED
                                                                        ) A,
                                                                        
                                                                        (
                                                                            SELECT * FROM T_RETURN_RANGE WHERE ID_RETURN = I_ID_RETURN
                                                                        ) B
                                                                        WHERE F_INTERSECTION(A.RANGE_MIN, A.RANGE_MAX, B.RANGE_MIN, B.RANGE_MAX) > 0 
                                                                        ORDER BY A.ID_RETURN
                                                                
                                                            ) H
                                                            WHERE ROWNUM=1
                                                            UNION
                                                            SELECT -1E7, -1, -1 FROM DUAL
                                                    );               
                                                            
                                                                             
                                         END IF;
                                         
                                         
                                         IF U_ID_RETURN > 0 THEN
                                         
                                              INNER_CODE := 1;
                                              O_CODE := 3E4 + 11; 
                                              O_MESSAGE := 'Ошибка! Не удалось изменить статус заявки номер=' || I_ID_RETURN || '. Пересечение с диапазоном ' || F_RANGE(U_MIN, U_MAX) || ' из другой заявки. Номер заявки=' || U_ID_RETURN;
                                              P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                                         
                                         END IF;
                                         
                                         

                                    END;
 
 
 
 BEGIN
 
 O_CODE := 0; O_MESSAGE := ''; 

 ---------------------------------------------------------------------------------------------------------------------------------------------------
IF CB.F_RESTRICTED_MODE(O_CODE, O_MESSAGE) != 0 THEN
    RETURN;
END IF;
---------------------------------------------------------------------------------------------------------------------------------------------------

 
 ---P_APPLICATION_LOG(500, 77777, I_ID_PAYMENT_TYPE,    X_CODE, X_MESSAGE);
   
SELECT DECODE ( I_ID_PAYMENT_TYPE , 0 , -1, I_ID_PAYMENT_TYPE ) INTO V_ID_PAYMENT_TYPE FROM DUAL;
 
 ---- Определим новые и текущие значения атрибутов ----
 SELECT 
 
     DECODE ( NVL(I_ID_BANK,-1),  -1, ID_BANK, I_ID_BANK ),
     DECODE ( NVL(I_BANK_ACCOUNT,'?'),  '?', BANK_ACCOUNT, I_BANK_ACCOUNT ),
     DECODE ( NVL(I_PERSON_ACCOUNT,'?'),  '?', PERSON_ACCOUNT, I_PERSON_ACCOUNT ),
     DECODE ( NVL(V_ID_PAYMENT_TYPE, -1), -1, ID_PAYMENT_TYPE, V_ID_PAYMENT_TYPE ),
     DECODE ( NVL(I_ID_STATUS,-1), -1, ID_STATUS, I_ID_STATUS ),    
     
     
     ID_BANK,
     BANK_ACCOUNT,
     PERSON_ACCOUNT,
     ID_PAYMENT_TYPE,
     ID_STATUS
     
 INTO
 
    V_ID_BANK,
    V_BANK_ACCOUNT,
    V_PERSON_ACCOUNT,
    V_ID_PAYMENT_TYPE,
    V_ID_STATUS,
    
    W_ID_BANK,
    W_BANK_ACCOUNT,
    W_PERSON_ACCOUNT,
    W_ID_PAYMENT_TYPE,
    W_ID_STATUS    
        
 FROM CARD_BACK.T_RETURN
 WHERE ID_RETURN = I_ID_RETURN;
 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 IF V_ID_STATUS = 0 THEN
    V_ID_STATUS := W_ID_STATUS;
 END IF;
 
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 SELECT COUNT(*) INTO X_COUNT 
    FROM CARD_BACK.T_RETURN
        WHERE 1=1
             and ID_RETURN = I_ID_RETURN
             and ID_BANK=V_ID_BANK 
             and BANK_ACCOUNT=V_BANK_ACCOUNT
             and NVL(PERSON_ACCOUNT,'?')=NVL(V_PERSON_ACCOUNT,'?')
             and ID_PAYMENT_TYPE=V_ID_PAYMENT_TYPE
             and ID_STATUS=I_ID_STATUS;
 
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     
    IF X_COUNT > 0 THEN

          O_CODE := 3E4 + 1; 
          O_MESSAGE := 'Ошибка! Изменение не произведено. Входные данные для изменения не отличаются от текущих данных. Номер заявки=' || I_ID_RETURN;
          P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
          RETURN;
        
    END IF;
    
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    IF ( W_ID_STATUS = CB.ST_CANCELED ) AND ( V_ID_STATUS = CB.ST_CANCELED ) THEN
    
            O_CODE := 3E4 + 21; 
            O_MESSAGE := 'Ошибка! Изменение не произведено. Нельзя менять атрибуты закрытой заявки.';
            P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
            RETURN;           
    
    END IF;
    
    
    IF ( W_ID_STATUS != CB.ST_START ) AND ( V_ID_STATUS = W_ID_STATUS ) THEN
    
            O_CODE := 3E4 + 22; 
            O_MESSAGE := 'Ошибка! Изменение не произведено. Изменять свойства можно только для тех заявок, которые находятся в статусе "Заявка принята"';
            P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
            RETURN;           
    
    END IF;    
    
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    IF ( V_ID_PAYMENT_TYPE = 2 ) AND  ( V_ID_STATUS = CB.ST_WAIT ) THEN

          O_CODE := 3E4 + 2; 
          O_MESSAGE := 'Ошибка! Изменение не произведено. Данный тип платежа не совместим со статусом "Заявка находится в работе.". Номер заявки=' || I_ID_RETURN;
          P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
          RETURN;
        
    END IF;
    
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    IF ( V_ID_PAYMENT_TYPE = 1 ) AND  ( V_ID_BANK = 0 ) THEN

          O_CODE := 3E4 + 3; 
          O_MESSAGE := 'Ошибка! Изменение не произведено. Для безналичного платежа нужно указать банк. Номер заявки=' || I_ID_RETURN;
          P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
          RETURN;
        
    END IF; 
    
    
    IF ( V_ID_PAYMENT_TYPE = 1 ) AND  ( LENGTH(V_BANK_ACCOUNT) != CB.C_BANK_ACCOUNT_LENGTH ) THEN

          O_CODE := 3E4 + 32; 
          O_MESSAGE := 'Ошибка! Изменение не произведено. Для безналичного платежа указание номера счёта (' || CB.C_BANK_ACCOUNT_LENGTH || ' цифры) обязательно . Номер заявки=' || I_ID_RETURN;
          P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
          RETURN;
        
    END IF; 
    
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    IF ( V_ID_STATUS != W_ID_STATUS ) THEN
    
     SELECT COUNT(*) INTO X_COUNT 
        FROM CARD_BACK.T_STATUS_CHANGE
            WHERE OLD_STATUS = W_ID_STATUS AND NEW_STATUS = V_ID_STATUS;
            
         IF 
             (X_COUNT = 0) ---- Изменение статуса не разрешено ----
             AND 
             (W_ID_STATUS IN (CB.ST_COMMITED, CB.ST_CANCELED) ) ---- Текущий статус = "Заявка подтверждена"  или "Заявка отменена."----
             AND
             (V_ID_STATUS IN (CB.ST_START, CB.ST_WAIT) )   ---- Предполагаемый статус = "Заявка принята" или "Заявка в работе" ----
             AND
             F_ROLE_MEMBER(CB.ROLE_IT)=1  ---- Текущий пользователь имеет роль "Департамент IT" ----
         THEN
            X_COUNT := 1; ---- При этих условиях нужно разрешить изменение статуса ----
         END IF;       
           
      
          IF X_COUNT = 0 THEN
          
            O_CODE := 3E4 + 4; 
            O_MESSAGE :=SYS_CONTEXT ('USERENV', 'SESSION_USER') ||  ' Ошибка! Изменение не произведено. Запрещённый переход со статуса ' || W_ID_STATUS || ' на статус ' || V_ID_STATUS;
            P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
            RETURN;        
          
          END IF;      
    
    END IF;
 
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
   IF (V_ID_STATUS = 0) THEN
   
            O_CODE := 3E4 + 33; 
            O_MESSAGE := 'Ошибка! Изменение не произведено. Запрещается присваивать заявке неопределенный статус.';
            P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
            RETURN;     
   
   END IF;
 
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    IF 
        (
            (     (V_ID_STATUS = CB.ST_START) AND (W_ID_STATUS = CB.ST_APPROVED)     )
            OR
            (     (V_ID_STATUS = CB.ST_APPROVED) AND (W_ID_STATUS = CB.ST_START)     ) 
        )
    THEN

         IF F_ROLE_MEMBER(CB.ROLE_SECURITY)=1 THEN
            NULL;
         ELSE
            NULL;
                O_CODE := 3E4 + 34; 
                O_MESSAGE := 'Ошибка! Смену статуса "Заявка Согласована"  могут производить только сотрудники Департамента Безопасности.';
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
                RETURN; 
         END IF;

    END IF;
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    IF 
            (     (V_ID_STATUS = CB.ST_WAIT) AND (W_ID_STATUS != V_ID_STATUS)     )
   
    THEN

         IF F_ROLE_MEMBER(CB.ROLE_FINANCE)=1 THEN
            NULL;
         ELSE
            NULL;
                O_CODE := 3E4 + 35; 
                O_MESSAGE := 'Ошибка! Смену статуса "Заявка взята в разработку" могут производить только сотрудники Финансовых подразделений.';
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
                RETURN; 
         END IF;

    END IF;

 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    IF 
            (     (V_ID_STATUS = CB.ST_COMMITED) AND (W_ID_STATUS != V_ID_STATUS)     )
   
    THEN

         IF (  (F_ROLE_MEMBER(CB.ROLE_SALES)=1) OR (F_ROLE_MEMBER(CB.ROLE_FINANCE)=1) ) THEN
            NULL;
         ELSE
            NULL;
                O_CODE := 3E4 + 36; 
                O_MESSAGE := 'Ошибка! Перевод карт в статус "Дефектная" могут производить только сотрудники ДРП или Финансов.';
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
                RETURN; 
         END IF;

    END IF;

 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    IF 
            (     (W_ID_STATUS = CB.ST_COMMITED) AND (W_ID_STATUS != V_ID_STATUS)     )
   
    THEN

         IF F_ROLE_MEMBER(CB.ROLE_SALES)=1 THEN
            NULL;
         ELSE
            NULL;
                O_CODE := 3E4 + 37; 
                O_MESSAGE := 'Ошибка! Возврат карт из статуса "Дефектная" в предыдущий статус могут производить только сотрудники Подразделения Продаж Департамента ПАО.';
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
                RETURN; 
         END IF;

    END IF;

 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------



















    P_CHECK_REOPEN(X_CODE);
    
    IF X_CODE > 0 THEN
        
           RETURN;   
    
    END IF;
    
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
 ----/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 IF (V_ID_STATUS = CB.ST_COMMITED) AND (W_ID_STATUS != CB.ST_COMMITED) THEN ---- Событие "Пользователь установил статус [Заявка подтверждена] " ----
 
        P_RETURN_COMMIT ( I_ID_RETURN, TRUE, X_CODE, X_MESSAGE );  /* Изменяем статус карт НА ДЕФЕКТНЫЕ */
 
        O_MESSAGE := X_MESSAGE;
        O_CODE := X_CODE;
 
         IF X_CODE = 0 THEN

            P_APPLICATION_LOG(500, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
            
         ELSE
         
         
             P_APPLICATION_LOG(2001, O_CODE, 'Ошибка! ' || O_MESSAGE,    X_CODE, X_MESSAGE);
             
             O_CODE := 3E4 + 51;
             O_MESSAGE := 'Ошибка! При попытке перевода карт в статус "Дефектная" произошла ошибка!';
             
             P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
            
             
             ROLLBACK;
             RETURN;
             
         END IF;
 
 END IF;
 
----/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
  IF ( V_ID_STATUS != CB.ST_COMMITED) AND ( W_ID_STATUS = CB.ST_COMMITED ) THEN ---- Событие "Пользователь отменил статус [Заявка подтверждена] " ----
 
        P_RETURN_COMMIT ( I_ID_RETURN, FALSE, X_CODE, X_MESSAGE ); /* Изменяем статус карт НА ПРЕДЫДУЩИЙ ( НЕ ДЕФЕКТНЫЙ ) */
 
        O_MESSAGE := X_MESSAGE;
        O_CODE := X_CODE;
 
         IF X_CODE = 0 THEN

            P_APPLICATION_LOG(500, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
            
         ELSE
         
         
             P_APPLICATION_LOG(2001, O_CODE, 'Ошибка! ' || O_MESSAGE,    X_CODE, X_MESSAGE);
             
             O_CODE := 3E4 + 52;
             O_MESSAGE := 'Ошибка! При попытке перевода карт в "предыдущий" статус произошла ошибка!';
             
             P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
            
             
             ROLLBACK;
             RETURN;
             
         END IF;
 
 END IF;

----/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 
 













 



  UPDATE CARD_BACK.T_RETURN
  SET 
      ID_BANK = V_ID_BANK,
      BANK_ACCOUNT = V_BANK_ACCOUNT,
      PERSON_ACCOUNT = V_PERSON_ACCOUNT,
      ID_PAYMENT_TYPE = V_ID_PAYMENT_TYPE,
      ID_STATUS = V_ID_STATUS
  WHERE
      ID_RETURN = I_ID_RETURN;
  
  /* Действуем по принципу "Изменил данные - после этого сразу сохранил в истории"*/
  P_RETURN_SAVE_HISTORY(I_ID_RETURN, X_CODE); ---- Сохраним историю изменения объекта ----


 /* Если работа по заявке прервана, то необходимо удалить детали заявки - т.е. строки из таблицы T_CARD */
  IF (V_ID_STATUS = CB.ST_CANCELED) AND (W_ID_STATUS != CB.ST_CANCELED) THEN
  
    DELETE FROM T_CARD WHERE ID_RETURN = I_ID_RETURN;
  
  END IF;

----[][][][][][][][][][][][]----
               COMMIT;
----[][][][][][][][][][][][]----

----O_MESSAGE := 'Выполнена смена свойств Заявки';
 
 EXCEPTION 
   
        WHEN OTHERS THEN
            BEGIN           
                 O_CODE := 30991;
                 O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
                 ROLLBACK;            
            END;
 END;