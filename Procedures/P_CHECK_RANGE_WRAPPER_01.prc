CREATE OR REPLACE PROCEDURE CARD_BACK.P_CHECK_RANGE_WRAPPER_01
 ( 
 I_SESSION VARCHAR2,
 ICC_MIN IN VARCHAR2, 
 ICC_MAX IN VARCHAR2,
 O_CODE  OUT  INTEGER,
 O_MESSAGE OUT VARCHAR2,
 O_CARDS OUT SYS_REFCURSOR,   /* Список карт */
 O_RANGES OUT SYS_REFCURSOR  /* Список диапазонов */
 ) 
/* 
Процедура проверяет диапазон карт по ICC.
Если все карты подходят для возврата (пройдя проверку множества логических условий), то процедура вернёт значение O_CODE=0.
Если НЕ все карты подходят для возврата, то процедура вернёт значение O_CODE > 0.
В переменной O_REFCURSOR процедура вернёт список всех карт указанного диапазона (ICC, Статус, Номинал, Подозрение на мошенническую карту).
В переменной O_MESSAGE в случае если O_CODE=0 содержится информация о статусах карт указанного Диапазона.
GRANT EXECUTE ON CARD_BACK.P_CHECK_RANGE_WRAPPER_01 TO CARD_BACK_ROLE
*/

/*
Данная процедура является обёрткой над процедурой CARD_BACK.P_CHECK_RANGE 
реализуя дополнительное поведение, более удобное для пользователя:
Если указанный диапазон является подмножеством ранее указанного,
то он не выводится на экран веб-приложения в списке диапазонов-кандидатов на создание возврата (аналог "Корзины" в интернет-магазинах).
Если указанный диапазон является надмножеством ранее указанных,
то он выводится на экран веб-приложения, а "поглощаемые" им диапазоны уже не выводятся.
Список выводимых диапазонов указывается в O_RANGE_LIST
I_SESSION - уникальное значение для данного сочетания "Учётная запись" + "Вход в систему"
*/

IS 

V_SESSION VARCHAR2(500);
V_COUNT INTEGER;
V_CODE_SESSION INTEGER;

C_SESSION_DAY INTEGER := 7;
S_STATUS VARCHAR2(5000) := '?' ;
S_BALANCE  VARCHAR2(1000) := '?' ;
S_COUNT  VARCHAR2(1000) := '?' ;
S_SUM  VARCHAR2(1000) := '?' ;


               PROCEDURE P_OPEN_RANGES_REFCURSOR ( INNER_RANGES_REFCURSOR OUT SYS_REFCURSOR )
               IS
               BEGIN 
                   OPEN INNER_RANGES_REFCURSOR FOR
                        SELECT 
                            CARD_BACK.F_RANGE(RANGE_MIN, RANGE_MAX) as C_RANGE,
                            C_STATUS,
                            C_BALANCE,
                            C_COUNT,
                            C_SUM
                        FROM CARD_BACK.TB_RANGE_DRAFT
                        WHERE CODE_SESSION = V_CODE_SESSION
                        ORDER BY RANGE_MIN;       
                END;
                
                PROCEDURE P_PARSE_STRING ( I_STRING VARCHAR2 )
                IS /* Здесь парсим строку типа << 0   0519068820 - 0519068830;Продана;5;11;55 >> которую возвращает процедура CARD_BACK.P_CHECK_RANGE */
                J INTEGER := 0;
                BEGIN
                
                        FOR ONE_ROW IN 
                        (
                        SELECT  s_value
                          FROM  ( SELECT   TRIM (REGEXP_SUBSTR (string_data, '[^;]+', 1,   LEVEL))  s_value
                                       FROM   (    SELECT   I_STRING as string_data FROM DUAL)
                                        CONNECT BY   LEVEL <= regexp_count (string_data, ';', 1) + 1)
                            WHERE s_value IS NOT NULL
                         )
                       LOOP
                          J := J+1;
                          IF J=2 THEN S_STATUS  := ONE_ROW.s_value; END IF;
                          IF J=3 THEN S_BALANCE := ONE_ROW.s_value; END IF;
                          IF J=4 THEN S_COUNT    := ONE_ROW.s_value; END IF;                                      
                          IF J=5 THEN S_SUM       := ONE_ROW.s_value; END IF;                                      
                       END LOOP;        
                  
                END;
/* ------------------------------------------------------------------------------------------------------------------------------------------------------------- */
BEGIN

    V_SESSION := TRIM (I_SESSION);
    
    IF V_SESSION = 'TEST' THEN ---- Выберем наиболее позднюю сессию пользователя TIMUR_J
        SELECT ID_SESSION INTO V_SESSION FROM CARD_BACK.TB_SESSION WHERE CODE_SESSION = (SELECT MAX(CODE_SESSION) FROM CARD_BACK.TB_SESSION WHERE ID_SESSION LIKE 'TIMUR_J%' );
    END IF;  
    
    SELECT COUNT(*) INTO V_COUNT FROM CARD_BACK.TB_SESSION S WHERE S.ID_SESSION = V_SESSION AND SYSDATE - S.LOGON_DATE <= C_SESSION_DAY;
    
    IF V_COUNT != 1 THEN
        O_CODE := -98003;
        O_MESSAGE := 'Ошибка! Ваш сеанс связи с программой был прерван. Выйдите из программы и войдите снова.';
        RETURN;
    END IF; 
    
    SELECT CODE_SESSION INTO V_CODE_SESSION FROM CARD_BACK.TB_SESSION S WHERE S.ID_SESSION = V_SESSION AND SYSDATE - S.LOGON_DATE <= C_SESSION_DAY;

    CARD_BACK.P_CHECK_RANGE
        (
         ICC_MIN,
         ICC_MAX,  
         O_CODE,    
         O_MESSAGE,  
         O_CARDS  
        );
    
    IF O_CODE != 0 THEN
        P_OPEN_RANGES_REFCURSOR(O_RANGES);
        RETURN;
    END IF;
    
    P_PARSE_STRING(O_MESSAGE);
    
    DELETE FROM CARD_BACK.TB_RANGE_DRAFT  ---- Удалим все отрезки - под_множества нового отрезка
    WHERE CODE_SESSION=V_CODE_SESSION AND CARD_BACK.F_SUBSET(ICC_MIN, ICC_MAX, RANGE_MIN, RANGE_MAX)=1;  
    
    SELECT COUNT(*) INTO V_COUNT FROM CARD_BACK.TB_RANGE_DRAFT ---- Есть ли над_множества нового отрезка ?
    WHERE CODE_SESSION=V_CODE_SESSION AND CARD_BACK.F_SUBSET(RANGE_MIN, RANGE_MAX, ICC_MIN, ICC_MAX)=1; 
        
    
    
    IF V_COUNT = 0 THEN
    
    S_STATUS := SUBSTR(S_STATUS,1,200);
    S_BALANCE := SUBSTR(S_BALANCE,1,10);
    S_COUNT := SUBSTR(S_COUNT,1,10);
    S_SUM := SUBSTR(S_SUM,1,10);
    
        INSERT INTO CARD_BACK.TB_RANGE_DRAFT  
        (CODE_SESSION, RANGE_MIN, RANGE_MAX, C_STATUS, C_BALANCE, C_COUNT, C_SUM )    
        VALUES 
        (V_CODE_SESSION, ICC_MIN, ICC_MAX, S_STATUS, S_BALANCE, S_COUNT, S_SUM);
    END IF;
    
    COMMIT;
    
    P_OPEN_RANGES_REFCURSOR(O_RANGES);
    
EXCEPTION
        WHEN NO_DATA_FOUND THEN
            O_CODE := -98002;
            O_MESSAGE := '';
        WHEN OTHERS THEN
            O_CODE := -98001;
            O_MESSAGE :=  SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
END;