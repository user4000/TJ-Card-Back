CREATE OR REPLACE PROCEDURE P_RETURN_COMMIT 
( 
 I_ID_RETURN IN INTEGER, ---- ID Заявки (Возврата)
 I_IMPERFECT IN BOOLEAN, ---- Если TRUE - то делаем карты Дефектными, если FALSE - исправим статус из Дефектной на предыдущий.
 O_CODE  OUT  INTEGER, 
 O_MESSAGE OUT VARCHAR2
)
/* 
Процедура меняет статус карт (которые подлежат возврату) на "Дефектная".
Эта же процедура может наоборот, вернуть "Дефектным" картам предыдущий статус. 
*/
IS

    CURSOR  CUR_RANGE IS SELECT RANGE_MIN, RANGE_MAX FROM T_RETURN_RANGE WHERE ID_RETURN=I_ID_RETURN ORDER BY RANGE_MIN;
    
    V_MIN INTEGER;
    V_MAX INTEGER;
    X_CODE INTEGER;
    X_MESSAGE  VARCHAR2(4000);
    S_TEMP VARCHAR2(4000);
    V_COUNT INTEGER;
    V_ID_USER INTEGER;
     
    V_TARGET INTEGER;
    V_NOTHING INTEGER;
    V_RANGE_LENGTH INTEGER;
    
    W_TARGET INTEGER;
    W_NOTHING INTEGER;
    W_RANGE_LENGTH INTEGER;
    
               
                PROCEDURE P_SET_IMPERFECT( I_XCRD_ID IN INTEGER, INNER_CODE OUT INTEGER )
                 /* Процедура изменяет статус НА Дефектная  одной НЕ Дефектной карты */
                IS
                BEGIN
                
                ----DBMS_OUTPUT.PUT_LINE(  ' P_SET_IMPERFECT ' || I_XCRD_ID  );
                    P_APPLICATION_LOG(500, 0, ' P_SET_IMPERFECT ' || I_XCRD_ID,    X_CODE, X_MESSAGE);
                
                    XMASTER.XADMIN.SET_IMPERFECT_ONE(I_XCRD_ID, V_ID_USER, X_CODE, X_MESSAGE);

    
                            
                END;
 ----^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                            
                PROCEDURE P_SET_PREVIOUS( I_XCRD_ID IN INTEGER,  INNER_CODE OUT INTEGER )
                 /* Процедура изменяет статус НА Предыдущий одной Дефектной карты */
                IS
                BEGIN
                
                ----DBMS_OUTPUT.PUT_LINE(  ' P_SET_PREVIOUS ' || I_XCRD_ID  );
                    P_APPLICATION_LOG(500, 0, ' P_SET_PREVIOUS ' || I_XCRD_ID,    X_CODE, X_MESSAGE);
                
                    XMASTER.XADMIN.SET_PREVIOUS_ONE(I_XCRD_ID, V_ID_USER, X_CODE, X_MESSAGE);   
        
                            
                END;
 ----^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                            
                PROCEDURE P_ONE_RANGE_COMMIT(U_MIN IN INTEGER, U_MAX IN INTEGER, INNER_CODE OUT INTEGER, O_RANGE_LENGTH OUT INTEGER, O_NOTHING OUT INTEGER, O_TARGET OUT INTEGER)
                /* Процедура изменяет статус (Дефектная / Не дефектная) одного диапазона карт */
                IS
                U_ICC INTEGER;
                U_XCST_ID INTEGER;
                U_XCRD_ID INTEGER;
                U_CODE INTEGER;
                U_NOTHING INTEGER;
                U_TARGET INTEGER;  
                U_COMMITED INTEGER;       
                U_NOTE VARCHAR2(4000);       
                
                
                                        PROCEDURE P_IMPERFECT_FIRST_CYCLE
                                        IS
                                        BEGIN
                                        
                                                P_APPLICATION_LOG(500, 0, '>> Изменение статуса всех карт диапазона (на "Дефектная") >> ID_RETURN=' || I_ID_RETURN || '; Range=' || F_RANGE(U_MIN, U_MAX),   X_CODE, X_MESSAGE);
                                                
                                                FOR U_ICC IN U_MIN..U_MAX ---- Первый прогон цикла: Изменение статуса всех карт диапазона ----
                                                LOOP
                                                            
                                                        P_GET_CARD_ID ( U_ICC , U_XCRD_ID , U_XCST_ID ); ---- Находим ID карты и Статус карты по ICC ----
                                                        
                                                            
                                                        IF U_XCST_ID = CB.CA_IMPERFECT THEN ---- Если статус карты итак уже дефектный то .... -----
                                                                
                                                               U_NOTHING := U_NOTHING + 1; ---- Считаем, сколько карт уже были дефектными, так что даже не пришлось их изменять ----
                                                                    
                                                        ELSE
                                                                
                                                                IF U_XCRD_ID > 0 THEN
                                                                        
                                                                    P_SET_IMPERFECT ( U_XCRD_ID, INNER_CODE );
                                                                            
                                                                ELSE
                                                                        
                                                                    U_NOTE := 'Ошибка! Не удалось найти XCRD_ID для карты ICC = ' || LPAD(U_ICC,10,'0');
                                                                    P_APPLICATION_LOG(2001, 50881, U_NOTE,    X_CODE, X_MESSAGE);
                                                                            
                                                                END IF;    
                                                                    
                                                        END IF;
                                                                               
                                                END LOOP;   
                                                                        
                                        END;
                                        
                                        PROCEDURE P_IMPERFECT_SECOND_CYCLE
                                        IS
                                        BEGIN       
                                        
                                                P_APPLICATION_LOG(500, 0, '>> Проверка изменения статуса всех карт диапазона (на "Дефектная") >> ID_RETURN=' || I_ID_RETURN || '; Range=' || F_RANGE(U_MIN, U_MAX),   X_CODE, X_MESSAGE);
                                                
                                                IF U_NOTHING = ( U_MAX - U_MIN + 1 ) THEN ---- Если количество карт, для которых мы ничего не сделали равно числу карт всего в диапазоне ----
                                                
                                                        U_TARGET := ( U_MAX - U_MIN + 1 );
                                                
                                                ELSE
                                            
                                                        FOR U_ICC IN U_MIN..U_MAX ---- Второй прогон цикла: Проверка - имеет ли карта требуемый нам статус "Дефектная" (или даже "Архивная" ) ----
                                                        LOOP
                                                        
                                                                
                                                                P_GET_CARD_ID ( U_ICC , U_XCRD_ID , U_XCST_ID ); ---- Находим ID карты и Статус карты по ICC ----
                                                                    
                                                                IF (U_XCST_ID = CB.CA_IMPERFECT) OR (U_XCST_ID = CB.CA_ARCHIVED) THEN
                                                                    
                                                                    U_COMMITED := 1;
                                                                    U_TARGET := U_TARGET + 1;
                                                                        
                                                                ELSE 
                                                                    
                                                                    U_COMMITED := 0;   
                                                                              
                                                                END IF;
                                                                                          
                                                                P_CARD_CHANGE(I_ID_RETURN, U_XCRD_ID, U_XCST_ID,  U_ICC,  U_COMMITED,  X_CODE, X_MESSAGE);                   
                                                                              
                                                        END LOOP;  
                                                                                                            
                                                 END IF;          
                                                                                    
                                        END;      
                                        
                
                                        PROCEDURE P_PREVIOUS_FIRST_CYCLE
                                        IS
                                        BEGIN
                                        
                                                P_APPLICATION_LOG(500, 0, '>> Изменение статуса всех карт диапазона (на предыдущий) >> ID_RETURN=' || I_ID_RETURN || '; Range=' || F_RANGE(U_MIN, U_MAX),   X_CODE, X_MESSAGE);

                                                FOR U_ICC IN U_MIN..U_MAX ---- Первый прогон цикла: Изменение статуса всех карт диапазона ----
                                                LOOP
                                                        
                                                        P_GET_CARD_ID ( U_ICC , U_XCRD_ID , U_XCST_ID ); ---- Находим ID карты и Статус карты по ICC ----
                                                            
                                                        IF U_XCST_ID = CB.CA_IMPERFECT THEN ---- Если статус карты дефектный то вернём предыдущий статус -----
                                                                
                                                                IF U_XCRD_ID > 0 THEN
                                                                        
                                                                    P_SET_PREVIOUS ( U_XCRD_ID, INNER_CODE );
                                                                            
                                                                ELSE
                                                                        
                                                                    U_NOTE := 'Ошибка! Не удалось найти XCRD_ID для карты ICC = ' || LPAD(U_ICC,10,'0');
                                                                    P_APPLICATION_LOG(2001, 50882, U_NOTE,    X_CODE, X_MESSAGE);
                                                                            
                                                                END IF;                                                                    
                                                                
                                                        ELSE
                                                                
                                                               U_NOTHING := U_NOTHING + 1; ---- Считаем, сколько карт НЕ были дефектными, так что даже не пришлось их изменять ----
                                                                    
                                                        END IF;
                                                                             
                                                END LOOP;   
                                                                        
                                        END;                
                
                
                
                                        PROCEDURE P_PREVIOUS_SECOND_CYCLE
                                        IS
                                        BEGIN       
                                        
                                                P_APPLICATION_LOG(500, 0, '>> Проверка изменения статуса всех карт диапазона (на предыдущий) >> ID_RETURN=' || I_ID_RETURN || '; Range=' || F_RANGE(U_MIN, U_MAX),   X_CODE, X_MESSAGE);

                                                IF U_NOTHING = ( U_MAX - U_MIN + 1 ) THEN ---- Если количество карт, для которых мы ничего не сделали равно числу карт всего в диапазоне ----
                                                
                                                        U_TARGET := ( U_MAX - U_MIN + 1 );
                                                
                                                ELSE
                                                        
                                                        FOR U_ICC IN U_MIN..U_MAX ---- Второй прогон цикла: Проверка - имеет ли карта требуемый нам статус НЕ РАВНЫЙ "Дефектная" ----
                                                        LOOP
                                                            
                                                                P_GET_CARD_ID ( U_ICC , U_XCRD_ID , U_XCST_ID ); ---- Находим ID карты и Статус карты по ICC ----
                                                                    
                                                                IF (U_XCST_ID = CB.CA_IMPERFECT)  THEN
                                                                    
                                                                    U_COMMITED := 0;   
                                                                        
                                                                ELSE 
                                                                    
                                                                    U_COMMITED := 1;
                                                                    U_TARGET := U_TARGET + 1;                                                                    
                                                                              
                                                                END IF;
                                                                                          
                                                                P_CARD_CHANGE(I_ID_RETURN, U_XCRD_ID, U_XCST_ID,  U_ICC,  U_COMMITED,  X_CODE, X_MESSAGE);                   
                                                                                  
                                                        END LOOP;  
                                                                                                            
                                                 END IF;          
                                                                                    
                                        END; 
                
/***********************************************************************************************************************************************************/                         
                              
                BEGIN
                
                        INNER_CODE := 0;                        
                        U_NOTHING := 0; ---- Число карт для которых не нужно вызывать процедуру, так как они уже (до изменений) имеют нужный нам статус ----
                        U_TARGET := 0;  ---- Число карт, которые после первого прогона (цикла) имеют нужный нам статус ----
                        U_COMMITED := 0;  ---- Признак - имеет ли карта требуемый в итоге статус ----
                                              
                        --------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                        IF    I_IMPERFECT   THEN ---- Необходимо сделать карты Дефектными ----
                        --------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                        
                                P_IMPERFECT_FIRST_CYCLE;
                                            
                                ---- /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
                        
                                P_IMPERFECT_SECOND_CYCLE;
                                    
                                 ---- /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
                                 
                                O_MESSAGE :='Диапазон ' || F_RANGE(U_MIN, U_MAX) || ' Кол-во карт = ' || (U_MAX - U_MIN + 1) || '; Из них: "Дефектные" и "Архивированные" = ' || U_TARGET || '; Были "Дефектными" до начала операции = ' || U_NOTHING;
                                
                                IF  (U_MAX - U_MIN + 1) = U_TARGET   THEN
                                     P_APPLICATION_LOG(1400, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
                                ELSE 
                                    O_CODE := 50915;
                                    O_MESSAGE := 'Ошибка! ' || O_MESSAGE;
                                    P_APPLICATION_LOG(1451, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
                                END IF; 
                                
                                                    
                        --------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                        ELSE ---- Необходимо дефектным картам вернуть предыдущий статус ----
                        --------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                        
                        
                                P_PREVIOUS_FIRST_CYCLE;
                                            
                                ---- /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
                        
                                P_PREVIOUS_SECOND_CYCLE;
                                    
                                 ---- /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
                                 
                                O_MESSAGE := 'Диапазон ' || F_RANGE(U_MIN, U_MAX) || ' Кол-во карт = ' || (U_MAX - U_MIN + 1) || '; Из них: НЕ являющиеся "Дефектными"  = ' || U_TARGET || '; НЕ были "Дефектными" до начала операции = ' || U_NOTHING;
                                
                                IF  (U_MAX - U_MIN + 1) = U_TARGET   THEN
                                     P_APPLICATION_LOG(1500, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
                                ELSE 
                                    O_CODE := 50916;
                                    O_MESSAGE := 'Ошибка! ' || O_MESSAGE;
                                    P_APPLICATION_LOG(1551, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
                                END IF;                
                        
                        END IF;--------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                          
                        O_RANGE_LENGTH := U_MAX - U_MIN + 1;
                        O_NOTHING := U_NOTHING;
                        O_TARGET := U_TARGET;
                        
                END;               
                
BEGIN

O_CODE := 0; O_MESSAGE := '';


V_ID_USER := F_GET_CURRENT_USER_ID;

    V_TARGET := 0;
    V_NOTHING := 0;
    V_RANGE_LENGTH := 0;
    
    W_TARGET := 0;
    W_NOTHING := 0;
    W_RANGE_LENGTH := 0;


SELECT 
    COUNT(*) 
    INTO V_COUNT 
FROM T_RETURN_RANGE A
INNER JOIN T_RETURN B 
    ON A.ID_RETURN = B.ID_RETURN 
WHERE A.ID_RETURN = I_ID_RETURN AND B.ID_STATUS != CB.ST_CANCELED;


IF V_COUNT = 0 THEN
    O_CODE := 50901;
    O_MESSAGE := 'Не найдены диапазоны для Заявки ID = ' || I_ID_RETURN ;
    P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
    RETURN;
END IF;







----******************************************************************************************************************************
OPEN CUR_RANGE; ----//\\//\\//\\//\\ Цикл по всем диапазонам данного возврата //\\//\\//\\//\\----
LOOP

    FETCH CUR_RANGE INTO V_MIN, V_MAX;
    EXIT WHEN CUR_RANGE%NOTFOUND;

    S_TEMP := 'Заявка ID = ' || I_ID_RETURN || '; Начало операции изменения статуса карт диапазона ' || F_RANGE(V_MIN, V_MAX)   ;
    P_APPLICATION_LOG(2001, 50500, S_TEMP,    X_CODE, X_MESSAGE);
    
    P_ONE_RANGE_COMMIT(V_MIN, V_MAX, X_CODE, W_RANGE_LENGTH, W_NOTHING, W_TARGET);
    
    V_RANGE_LENGTH := V_RANGE_LENGTH + W_RANGE_LENGTH;
    V_NOTHING := V_NOTHING + W_NOTHING;
    V_TARGET := V_TARGET + W_TARGET;
    

END LOOP;
CLOSE CUR_RANGE;
----******************************************************************************************************************************





----============================
IF   I_IMPERFECT   THEN
    O_MESSAGE :='Кол-во карт = ' || V_RANGE_LENGTH || '; Из них: "Дефектные" (или "Архивированные") = ' || V_TARGET || '; Были "Дефектными" до начала операции = ' || V_NOTHING;
ELSE
    O_MESSAGE := 'Кол-во карт = ' || V_RANGE_LENGTH || '; Из них: НЕ являющиеся "Дефектными"  = ' || V_TARGET || '; НЕ были "Дефектными" до начала операции = ' || V_NOTHING;
END IF;
----============================
IF O_CODE=0 THEN
    O_MESSAGE := 'Операция завершилась успешно. ' || O_MESSAGE;
ELSE
    O_MESSAGE := 'Произошла ошибка! ' || O_MESSAGE;
END IF;
 ----============================         


------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
---- COMMIT; В данной процедуре не предполагается использование COMMIT и ROLLBACK;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   

EXCEPTION      
        WHEN OTHERS THEN
     
                 O_CODE := 50991;
                 O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
                 P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
                 ---- ROLLBACK; В данной процедуре не предполагается использование COMMIT и ROLLBACK;          

END;

 

 