/* 
GRANT EXECUTE ON CARD_BACK.P_CHECK_RANGE TO CARD_BACK_ROLE
*/
CREATE OR REPLACE PROCEDURE CARD_BACK.P_CHECK_RANGE
 ( 
 ICC_MIN IN VARCHAR2, 
 ICC_MAX IN VARCHAR2,
 O_CODE  OUT  INTEGER,
 O_MESSAGE OUT VARCHAR2,
 O_REFCURSOR OUT SYS_REFCURSOR
 ) 
/* 
Процедура проверяет диапазон карт по ICC.
Если все карты подходят для возврата (пройдя проверку множества логических условий), то процедура вернёт значение O_CODE=0.
Если НЕ все карты подходят для возврата, то процедура вернёт значение O_CODE > 0.
В переменной O_REFCURSOR процедура вернёт список всех карт указанного диапазона (ICC, Статус, Номинал, Подозрение на мошенническую карту).
В переменной O_MESSAGE в случае если O_CODE=0 содержится информация о статусах карт указанного Диапазона.
*/

IS 

V_MIN INTEGER; 
V_MAX INTEGER;  

X_CODE INTEGER; 
X_MESSAGE VARCHAR2(2000);
U_MESSAGE VARCHAR2(2000);

V_BALANCE INTEGER; 
V_COUNT INTEGER;  W_COUNT INTEGER;
V_PARTY INTEGER;  W_PARTY INTEGER;

V_STATUS_MIN INTEGER; 
V_STATUS_MAX INTEGER; 
V_PARTY_MIN INTEGER; W_PARTY_MIN INTEGER;
V_PARTY_MAX INTEGER; W_PARTY_MAX INTEGER;

S_STATUS VARCHAR2(500);
S_WARNING VARCHAR2(500); ---- Если вдруг будут найдены те карты которые есть на складе, то эта переменная выведет тревожное сообщение. 
V_GOOD_ACTION INTEGER;

D_DEBUG TIMESTAMP;
V_CHECK_ROLE INTEGER;

                PROCEDURE P_DEBUG(V_MESSAGE VARCHAR2)
                IS D_TIME TIMESTAMP;
                BEGIN
                    D_TIME := SYSTIMESTAMP();
                    --DBMS_OUTPUT.PUT_LINE( D_TIME - D_DEBUG || ' --- ' || V_MESSAGE );
                    NULL;
                END;


               PROCEDURE P_OPEN_REFCURSOR(I_VARIANT IN INTEGER, INNER_REFCURSOR OUT SYS_REFCURSOR)
               IS
               BEGIN ---- Вернём набор данных для пользователя. Покажем диапазоны в развёрнутом (каждая карта выйдет на экран) виде. ----
               
                     CASE I_VARIANT 
                     
                         WHEN 1000 THEN ---- Пустой рефкурсор - начальная инициализация ----
                            
                            OPEN INNER_REFCURSOR FOR
                              SELECT  0 as ICC, '?' as STATUS, 0 as BALANCE, 1 as AMOUNT, 0 as MANAT, '' as SUSPECT
                                 FROM DUAL
                                   WHERE  1=1;      
                                       
                         WHEN 2000 THEN ---- Основной вариант - выводим ICC, Статус, Номинал, Подозрение на мошенническую карту для каждой Карты  ----
                            
                            OPEN INNER_REFCURSOR FOR 
                            
                                    SELECT ICC, STATUS, BALANCE, SUSPECT FROM
                                    (
                                        SELECT A.ICC, B.DEF as STATUS, NVL(A.BALANCE_$,0) as BALANCE, 1 as AMOUNT,  NVL(A.BALANCE_$,0) as MANAT, '' as SUSPECT
                                            FROM XMASTER.XCARD A
                                                LEFT JOIN XMASTER.XCARD_STATUS B
                                                    ON A.XCST_XCST_ID = B.XCST_ID  
                                                LEFT JOIN TD_FRAUD_CARD F
                                                    ON A.ICC = F.ICC   
                                                        WHERE 
                                                        (TO_NUMBER(A.ICC) BETWEEN V_MIN AND V_MAX) 
                                                        AND 
                                                        (F.ICC IS NULL)
                                                        
                                        UNION
                                         
                                        SELECT B.ICC, B.STATUS , B.PRICE as BALANCE, 1 as AMOUNT, B.PRICE as MANAT, 'Мошенническая' as SUSPECT
                                            FROM TD_FRAUD_CARD_BALANCE B
                                                    WHERE TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX   
                                     )                                                                
                                     ORDER BY 1;   
                                                    
                                                                                                           
                         ELSE
                             
                             ---- Пустой рефкурсор  ----               
                            OPEN INNER_REFCURSOR FOR
                              SELECT  0 as ICC, '?' as STATUS, 0 as BALANCE, 1 as AMOUNT, 0 as MANAT, '' as SUSPECT
                                 FROM DUAL
                                   WHERE  1=1;  
                         
                     END CASE;
                 
               END;
               
               
               
------------------------------------------------------------------------------------------------------------------------------------------------------
---- Проверим, имеются ли пересечения с уже существующими "Возвратами" (не находящимися в статусе = "Заявка отменена")     ----
------------------------------------------------------------------------------------------------------------------------------------------------------    
               PROCEDURE P_INNER_CHECK_INTERSECTION (U_MIN IN INTEGER, U_MAX IN INTEGER, INNER_RETURN_CODE OUT INTEGER)
               IS           
               BEGIN
               
                       INNER_RETURN_CODE := 0;
                       
                       P_RANGE_INTERSECTION(U_MIN, U_MAX, INNER_RETURN_CODE, X_MESSAGE);
                       
                       IF INNER_RETURN_CODE > 0 THEN
                       
                            O_CODE := 1E4 + 101;
                            O_MESSAGE := 'Ошибка! ' || X_MESSAGE;
                            P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE); 
                       
                       END IF;
                       
                                
               END;
                 
---------------------------------------------------------------------------------------------------------------------------------------------------               
               

---------------------------------------------------------------------------------------------------------------------------------------------------                           

BEGIN

---------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------|                         Блок инициализации переменных                               |------------------------------- 
---------------------------------------------------------------------------------------------------------------------------------------------------

S_STATUS := '?'; S_WARNING := '';
O_CODE  := 0; O_MESSAGE := '';
D_DEBUG := SYSTIMESTAMP();

P_DEBUG('Start');
---------------------------------------------------------------------------------------------------------------------------------------------------
IF CB.F_RESTRICTED_MODE(O_CODE, O_MESSAGE) != 0 THEN
    RETURN;
END IF;
---------------------------------------------------------------------------------------------------------------------------------------------------

P_OPEN_REFCURSOR (1000, O_REFCURSOR);

SELECT COUNT(*) INTO V_CHECK_ROLE FROM CARD_BACK.T_ROLE WHERE Card_back.F_ROLE_MEMBER(ID_ROLE,NULL)>0; /* У пользователя вообще есть какая-либо активная роль ? */

IF V_CHECK_ROLE=0 THEN /* У данного пользователя нет ни одной активной роли */
    O_CODE := 1E4 + 109;
    O_MESSAGE := 'Ошибка! Доступ к запуску данной команды для вас заблокирован.' ;
    P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
    RETURN; 
END IF;



P_APPLICATION_LOG(300, 0, 'Пользователь задал диапазон: ' || F_RANGE(ICC_MIN, ICC_MAX),   X_CODE, X_MESSAGE);
V_GOOD_ACTION := 400; ---- ID_USER_ACTION в случае если диапазон подходит для возврата ----



V_MIN := ICC_MIN; 

IF (TRIM(ICC_MAX)='') OR (ICC_MAX IS NULL) THEN 
    V_MAX := V_MIN;
ELSE 
    V_MAX := ICC_MAX;
END IF;

IF V_MAX = 0 THEN V_MAX := V_MIN; END IF;

IF V_MIN IS NULL THEN V_MIN := V_MAX; END IF;

---------------------------------------------------------------------------------------------------------------------------------------------------
IF V_MAX < V_MIN THEN
     O_CODE := 1E4 + 2;
     O_MESSAGE := 'Ошибка! Некорректно задан диапазон. Нижняя граница не должна быть больше верхней границы.';
     P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
     RETURN;
END IF; 
---------------------------------------------------------------------------------------------------------------------------------------------------
S_WARNING := F_RANGE_IS_ILLEGAL(V_MIN, V_MAX);
---------------------------------------------------------------------------------------------------------------------------------------------------
IF (V_MAX - V_MIN + 1) > 10000 THEN
    O_CODE := 1E4 + 3;
    O_MESSAGE := 'Ошибка! Заданный вами диапазон слишком велик. Попробуйте уменьшить количество карт.' || S_WARNING ;
    P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
    RETURN;       
END IF;
--=====================================================================================
SELECT ---- Запрос № 1. Попытаемся найти все (НЕ-мошеннические) карты из диапазона (не только в статусе Продана, чтобы показать на экран статус карты, даже если он не равен Продана)
    MAX(A.XCST_XCST_ID), 
    MIN(A.XCST_XCST_ID),
    MAX(A.PRTY_PRTY_ID),
    MIN(A.PRTY_PRTY_ID),
    COUNT(*)   
INTO
    V_STATUS_MAX, --- Если таких нет, здесь будет NULL
    V_STATUS_MIN, --- Если таких нет, здесь будет NULL
    V_PARTY_MAX,
    V_PARTY_MIN,
    V_COUNT ---- Число КЭО не мошеннических - статус - Любой
FROM 
(SELECT ICC, XCST_XCST_ID, PRTY_PRTY_ID FROM  Xmaster.Xcard WHERE TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX) A
    LEFT JOIN V_FRAUD_CARD F
        ON A.ICC = F.ICC 
WHERE F.ICC IS NULL; ---- проверяем только те карты, которые не являются мошенническими ----


P_DEBUG('Point #1');

/*
IF (1+V_MAX-V_MIN)=V_COUNT THEN

    NULL; ---- Все карты из указанного диапазона нашлись в первом запросе ----
    W_PARTY_MAX := NULL;
    W_PARTY_MIN := NULL;
    W_COUNT := 0;

ELSE

    SELECT ----  Запрос № 2. Попытаемся найти все Мошеннические карты из диапазона
        MAX(PRTY_ID),
        MIN(PRTY_ID),
        COUNT(*)   
    INTO
        W_PARTY_MAX,
        W_PARTY_MIN,
        W_COUNT
    FROM V_FRAUD_CARD_BALANCE
    WHERE TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX;

END IF;
*/

SELECT ----  Запрос № 2. Попытаемся найти все Мошеннические карты из диапазона. Это самый тяжёлый запрос в процедуре.
    MAX(PRTY_ID),
    MIN(PRTY_ID),
    COUNT(*)   
INTO
    W_PARTY_MAX,
    W_PARTY_MIN,
    W_COUNT ---- Число КЭО мошеннических - статус - Любой
FROM TD_FRAUD_CARD_BALANCE  /* Раньше было V_FRAUD_CARD_BALANCE */
WHERE TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX;

P_DEBUG('Point #2');

------------------------------------------------------------------------------------------------------------------------------------------------------
IF (V_COUNT + W_COUNT) < 1 THEN

    O_CODE := 1E4 + 1;
    O_MESSAGE := 'Ошибка! Не найдена ни одна карта по вашему запросу.';
    P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
    RETURN;  
            
END IF;


IF (1+V_MAX-V_MIN) != (V_COUNT+W_COUNT) THEN

    O_CODE := 1E4 + 12;
    O_MESSAGE := 'Ошибка! Обнаружено несоответствие числа найденных карт размеру диапазона. Число карт в диапазоне = ' || (1+V_MAX-V_MIN) || ' из них найдено = ' || (V_COUNT+W_COUNT);
    O_MESSAGE := O_MESSAGE || S_WARNING;
    P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
    P_OPEN_REFCURSOR (2000, O_REFCURSOR);    
    RETURN;  
            
END IF;


IF (V_COUNT + W_COUNT) > 10000 THEN
    O_CODE := 1E4 + 5;
    O_MESSAGE := 'Ошибка! Найдено слишком много карт (более 10000) по вашему запросу.';
    O_MESSAGE := O_MESSAGE || S_WARNING;
    P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
    RETURN;          
END IF;

------------------------------------------------------------------------------------------------------------------------------------------------------

--DBMS_OUTPUT.PUT_LINE(V_STATUS_MIN || ' - ' || V_STATUS_MAX || ' --- ' || V_COUNT);

S_STATUS := CARD_BACK.F_RANGE_STATUS_INFO(V_MIN, V_MAX);
--S_STATUS := 'Тест!';

IF (V_STATUS_MAX = V_STATUS_MIN) AND (V_STATUS_MAX=CB.CA_SOLD ) THEN ---- Проверим, все ли карты (не являющиеся мошенническими) имеют один и тот же статус = Продана
    NULL; ---- Все карты имеют один и тот же статус и этот статус = Продана
ELSE

P_DEBUG('Point #3');

    ----IF ( V_COUNT > 0 ) THEN ---- Не все карты имеют статус = Продана. Нужно разбираться подробнее.
    
        /*
        2018.07.05 поступило распоряжение - Карты подлежат возврату, если выполняются условия:
        1. КЭО находятся в статусе "Дефектная"
        2. Предыдущий статус = "Продана"
        3. Статус "Дефектная" КЭО получили после даты указанной в T_PARAMETER
        4. Перевел карты в Статус "Дефектная" пользователь UTILIZATOR
        Или же попроще - те Дефектные карты, которые есть в таблице T_COMPLETED_TASK_6
        */
        
        /*
        IF CARD_BACK.F_IS_LEGAL_IMPERFECT( V_MIN, V_MAX ) = 0 THEN 
        
                O_CODE := 1E4 + 6;
                O_MESSAGE := 'Предупреждение! Обнаружены карты не имеющие статус "Продана" (при этом указанные карты не являются мошенническими).';
                P_APPLICATION_LOG(651, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);   
                P_OPEN_REFCURSOR (2000, O_REFCURSOR);                
                RETURN;     
        
        END IF;
        */
        
        IF S_STATUS IS NULL THEN
        
                O_CODE := 1E4 + 6;                
                O_MESSAGE := 'Предупреждение! Обнаружены карты не подлежащие возврату!'  ;
                O_MESSAGE := O_MESSAGE || S_WARNING;
                P_APPLICATION_LOG(651, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);   
                P_OPEN_REFCURSOR (2000, O_REFCURSOR);                
                RETURN;    
                
        END IF;
           
    ----END IF;    
             
END IF;

------------------------------------------------------------------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT ---- Все ли карты были распределены в партию ? ----
    (SELECT COUNT(*) FROM XMASTER.PARTY WHERE PRTY_ID=V_PARTY_MIN)
     +
    (SELECT COUNT(*) FROM XMASTER.PARTY WHERE PRTY_ID=V_PARTY_MAX)
INTO V_PARTY FROM DUAL;

---- Если хотя бы 1 карта не добавлена в партию, то эта сумма не будет равна 2. ----

IF ( V_PARTY != 2 ) AND ( V_COUNT > 0 ) THEN 

        O_CODE := 1E4 + 7;
        O_MESSAGE := 'Ошибка! Не все карты из указанного диапазона были распределены в партию.';
        O_MESSAGE := O_MESSAGE || S_WARNING;

        P_OPEN_REFCURSOR (2000, O_REFCURSOR);       
        P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);               
        RETURN;     
      
END IF;

P_DEBUG('Point #4');

------------------------------------------------------------------------------------------------------------------------------------------------------
IF ( V_PARTY_MAX != V_PARTY_MIN ) AND ( V_COUNT > 0 )  THEN ---- Проверим, все ли (НЕ мошеннические) карты принадлежат к одной и той же Партии.

    O_CODE := 1E4 + 81;
    O_MESSAGE := 'Ошибка! Не все карты принадлежат одной и той же партии.';
    O_MESSAGE := O_MESSAGE || S_WARNING;

    P_OPEN_REFCURSOR (2000, O_REFCURSOR);    
    P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);               
    RETURN;         
       
END IF;
------------------------------------------------------------------------------------------------------------------------------------------------------
IF ( W_PARTY_MAX != W_PARTY_MIN ) AND ( W_COUNT > 0 )  THEN ---- Проверим, все ли (Мошеннические) карты принадлежат к одной и той же Партии.

    O_CODE := 1E4 + 82;
    O_MESSAGE := 'Ошибка! Не все карты принадлежат одной и той же партии.';
    O_MESSAGE := O_MESSAGE || S_WARNING;

    P_OPEN_REFCURSOR (2000, O_REFCURSOR);    
    P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);               
    RETURN;         
       
END IF;
------------------------------------------------------------------------------------------------------------------------------------------------------
IF  ( V_COUNT > 0 ) AND  ( W_COUNT > 0 ) AND (V_PARTY_MIN != W_PARTY_MAX) THEN
    
    O_CODE := 1E4 + 83;
    O_MESSAGE := 'Ошибка! Не все карты принадлежат одной и той же партии.';
    O_MESSAGE := O_MESSAGE || S_WARNING;

    P_OPEN_REFCURSOR (2000, O_REFCURSOR);    
    P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);               
    RETURN;         
       
END IF;
------------------------------------------------------------------------------------------------------------------------------------------------------





SELECT PRICE INTO V_BALANCE ---- Проверим баланс партии ----
    FROM XMASTER.PARTY 
        WHERE (PRTY_ID = V_PARTY_MAX) OR (PRTY_ID = W_PARTY_MIN) ; 

    IF (V_BALANCE > 0) THEN ---- Проверим, нормальный ли номинал имеет данная Партия.
        NULL; ---- Данная партия имеет нормальный номинал.
    ELSE
        O_CODE := 1E4 + 91;
        O_MESSAGE := 'Ошибка! Номинал партии указанных карт равен нулю.';
        O_MESSAGE := O_MESSAGE || S_WARNING;
            
        P_APPLICATION_LOG(1001, O_CODE, O_MESSAGE || ' PRTY_ID=' || V_PARTY_MAX,   X_CODE, X_MESSAGE);               
        RETURN;            
    END IF;
        
P_DEBUG('Point #5');
    
------------------------------------------------------------------------------------------------------------------------------------------------------
---- Проверим, имеются ли пересечения с уже существующими "Возвратами" (не находящимися в статусе = "Заявка отменена")     ----
------------------------------------------------------------------------------------------------------------------------------------------------------

P_INNER_CHECK_INTERSECTION( V_MIN, V_MAX, X_CODE);

IF X_CODE != 0 THEN

    RETURN;  

END IF; 

------------------------------------------------------------------------------------------------------------------------------------------------------

P_DEBUG('Point #6');
    
------------------------------------------------------------------------------------------------------------------------------------------------------

IF   (W_COUNT > 0) THEN
                    
        IF V_COUNT = 0 THEN ---- В диапазоне только те карты, которые активированы мошенническим путём ----
                                
                 V_GOOD_ACTION := 410; 
                 --S_STATUS := 'Мошеннические';
                                
            ELSE ---- В диапазоне имеются карты, которые активированы мошенническим путём. Есть также карты в статусе "Продана" ----
                                
                V_GOOD_ACTION := 420;
                --S_STATUS := 'Продана (не мошеннические) ' || V_COUNT || ' шт.  Мошеннические ' || W_COUNT || ' шт.';
                            
        END IF;
                    
END IF;   

--=====================================================================================
----                                                                        Диапазон карт подходит для возврата
--=====================================================================================
IF O_CODE=0 THEN
    O_MESSAGE :=  F_RANGE(V_MIN, V_MAX) || ';' ||  S_STATUS || ';' || V_BALANCE || ';' ||   (V_MAX-V_MIN+1)  || ';' ||  (V_MAX-V_MIN+1)*V_BALANCE; 
    /* Переменная O_MESSAGE затем парсится на веб-сервере. Изменять её не нужно. */
    P_OPEN_REFCURSOR (2000, O_REFCURSOR);         
    U_MESSAGE :=  F_RANGE(V_MIN, V_MAX) || ';' ||  S_STATUS || '; ' || V_BALANCE || ' (ман.) x ' ||   (V_MAX-V_MIN+1)  || ' (шт.) = ' ||  (V_MAX-V_MIN+1)*V_BALANCE; 
    P_APPLICATION_LOG(V_GOOD_ACTION, 0,  'Диапазон карт подходит для возврата: ' || U_MESSAGE ,   X_CODE, X_MESSAGE);
END IF;
--=====================================================================================

P_DEBUG('End');


EXCEPTION 
        WHEN OTHERS THEN
            BEGIN           
             O_CODE := 10991;
             O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);            
            END;
END;
/
