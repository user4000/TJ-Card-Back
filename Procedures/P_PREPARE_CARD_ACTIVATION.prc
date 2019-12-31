/* GRANT EXECUTE ON P_PREPARE_CARD_ACTIVATION  TO CARD_BACK_ROLE */
CREATE OR REPLACE PROCEDURE P_PREPARE_CARD_ACTIVATION 
( I_ID_RETURN IN INTEGER, I_MSISDN IN INTEGER, O_CODE  OUT  INTEGER,  O_MESSAGE OUT VARCHAR2)
/* 
Запишем все карты для которых необходима активации в таблицу TA_CARD 
В дальнейшем их "подхватит" JOB SLR-a с помощью функции F_ACTIVATION_REQUEST
*/
IS

CURSOR  CUR_RANGE IS SELECT RANGE_MIN, RANGE_MAX FROM T_RETURN_RANGE WHERE ID_RETURN=I_ID_RETURN ORDER BY RANGE_MIN;

V_ID_USER INTEGER;
V_ID_ACTIVATION INTEGER;
V_ICC INTEGER;
V_MIN INTEGER;
V_MAX INTEGER;

U_XCRD_ID  INTEGER;
U_XCST_ID INTEGER;
U_ID_RETURN_EXIST INTEGER;
U_COUNT INTEGER;

S_TEMP VARCHAR2(4000);
X_CODE INTEGER;
X_MESSAGE  VARCHAR2(4000);

BEGIN

 O_CODE := 0; O_MESSAGE := ''; 
 
 V_ID_USER := F_GET_CURRENT_USER_ID; 
 
---------------------------------------------------------------------------------------------------------------------------------------------------
IF CB.F_RESTRICTED_MODE(O_CODE, O_MESSAGE) != 0 THEN
    RETURN;
END IF;
---------------------------------------------------------------------------------------------------------------------------------------------------

 
  IF ( I_MSISDN BETWEEN 66000000 AND 69999999 ) THEN
                NULL;
 ELSE
                O_CODE := 7E4 + 6; 
                O_MESSAGE := ' Ошибка! Указанный вами номер абонента не является корректным.'  ;
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                RETURN;
 END IF;    
 
 
 P_INVOICE_GLOBAL(I_MSISDN, X_CODE, X_MESSAGE);
 
 IF X_CODE != 0 THEN
                O_CODE := 7E4 + 7; 
                O_MESSAGE := ' Ошибка при поиске абонента в Биллинге! ' || X_MESSAGE  ;
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                RETURN;
 END IF;  
 
 
 IF I_MSISDN NOT IN (99999999969404005) THEN
 
                O_CODE := 7E4 + 99; 
                O_MESSAGE := ' Предупреждение! Возможность Активации КЭО на номер в настоящее время отключена.'  ;
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                RETURN;
                
 END IF;
 
 
 

 /* На всякий случай пере-проверим пересечение диапазонов перед активацией КЭО */
 P_RETURN_INTERSECTION(I_ID_RETURN, X_CODE, X_MESSAGE);
  
  IF X_CODE != 0 THEN
  
            O_CODE := 7E4 + 8;  
            O_MESSAGE := X_MESSAGE;
            P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
            RETURN;  
             
  END IF;
 
 
 
 
 
 
 
 
 
 
 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 SELECT COUNT(*) INTO U_COUNT 
 FROM TA_ACTIVATION 
 WHERE 
 ID_RETURN = I_ID_RETURN
 AND
 ( ABS( SYSDATE - START_DATE ) < 30 * CB.C_ONE_SECOND ); ----   Прошло меньше 30 секунд с момента предыдущей попытки активации КЭО данной Заявки ----
 
 
  IF U_COUNT > 0 THEN
 
                O_CODE := 7E4 + 5; 
                O_MESSAGE := 'Предупреждение! С момента предыдущей попытки активации данной Заявки прошло менее 30 секунд. Попробуйте снова через несколько секунд.'  ;
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                RETURN;
                
 END IF;
 
 
 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 SELECT COUNT(*) INTO U_COUNT 
 FROM T_RETURN
 WHERE 
 ID_RETURN = I_ID_RETURN 
 AND 
 ID_STATUS IN ( CB.ST_APPROVED );
 
 
 IF U_COUNT != 1 THEN
 
                O_CODE := 7E4 + 3; 
                O_MESSAGE := 'Ошибка! Активировать КЭО можно только для Заявки в статусе "Согласовано с Департаментом Безопасности" '  ;
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                RETURN;
                
 END IF;
 
 
 
  IF F_RETURN_IS_ACTIVATED(I_ID_RETURN) = 1 THEN
 
                O_CODE := 7E4 + 4; 
                O_MESSAGE := 'Ошибка! Заявка номер ' || I_ID_RETURN || ' Все карты данной заявки уже были успешно активированы ранее. '  ;
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                RETURN;
                
 END IF;
 
 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

 INSERT INTO TA_ACTIVATION (ID_RETURN, MSISDN, ID_USER)
    VALUES (I_ID_RETURN, I_MSISDN, V_ID_USER)
        RETURNING ID_ACTIVATION INTO V_ID_ACTIVATION;

 
----******************************************************************************************************************************
OPEN CUR_RANGE; ----//\\//\\//\\//\\ Цикл по всем диапазонам данного возврата //\\//\\//\\//\\----
LOOP

    FETCH CUR_RANGE INTO V_MIN, V_MAX;
    EXIT WHEN CUR_RANGE%NOTFOUND;

    S_TEMP := 'Заявка ID = ' || I_ID_RETURN || '; Подготовка к активации карт диапазона ' || F_RANGE(V_MIN, V_MAX)   ;
    P_APPLICATION_LOG(500, 70500, S_TEMP,    X_CODE, X_MESSAGE);
    
  


        FOR V_ICC IN V_MIN..V_MAX
        LOOP
                                                                                                        
            P_GET_CARD_ID ( V_ICC , U_XCRD_ID , U_XCST_ID ); ---- Найдём XCRD_ID и Статус карты ----
            
            U_ID_RETURN_EXIST := NULL;
            
                    IF U_XCST_ID = CB.CA_SOLD THEN 
                    
                               SELECT COUNT(*) INTO U_COUNT FROM  TA_CARD WHERE XCRD_ID = U_XCRD_ID;
                                
                                IF U_COUNT > 0 THEN
                                
                                    SELECT ID_RETURN INTO U_ID_RETURN_EXIST 
                                        FROM TA_ACTIVATION 
                                            WHERE ID_ACTIVATION = 
                                                (  SELECT ID_ACTIVATION FROM TA_CARD WHERE XCRD_ID = U_XCRD_ID );

                        
                                END IF;                     
                                
                                
                                
                                IF I_ID_RETURN = U_ID_RETURN_EXIST THEN
                                
                                       DELETE FROM  TA_CARD WHERE XCRD_ID = U_XCRD_ID AND ( (R_CODE IS NULL) OR (R_MESSAGE IS NULL) ) ;
                               
                                ELSE
                                    
                                        IF U_COUNT > 0 THEN
                                        
                                            O_CODE := 7E4 + 1; 
                                            O_MESSAGE := 'Ошибка! Карта ICC=' || LPAD(V_ICC,'0',10) || ' не может быть активирована, так как она участвует в активации по другой Заявке номер ' || U_ID_RETURN_EXIST  ;
                                            P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
                                            ROLLBACK; 
                                            RETURN;
                                        
                                        END IF;     
                                
                                END IF;
                                
                                
                                INSERT INTO TA_CARD (ID_ACTIVATION, XCRD_ID, ICC)
                                VALUES (V_ID_ACTIVATION, U_XCRD_ID, V_ICC);
                                
                      ELSE
                            
                                O_CODE := 7E4 + 2; 
                                O_MESSAGE := 'Ошибка! Карта ICC=' || LPAD( V_ICC, '0' , 10 ) || ' не может быть активирована, так как статус карты = ' || U_XCST_ID ;
                                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                                ROLLBACK; 
                                RETURN;
                    
                    END IF;                
            
        END LOOP;
        
END LOOP;
CLOSE CUR_RANGE;
----******************************************************************************************************************************

O_MESSAGE := 'Процесс активации КЭО Заявки ' || I_ID_RETURN || ' на номер ' || I_MSISDN || ' запущен. Пожалуйста, ожидайте результата ...';

COMMIT;




  UPDATE CARD_BACK.T_RETURN
  SET 
      ID_STATUS = CB.ST_CA_START
  WHERE
      ID_RETURN = I_ID_RETURN;
      
   P_RETURN_SAVE_HISTORY(I_ID_RETURN, X_CODE);

COMMIT;



EXCEPTION 
        WHEN OTHERS THEN
                 O_CODE := 70991;
                 O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
                 ROLLBACK;            

END;