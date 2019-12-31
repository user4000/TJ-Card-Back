
CREATE OR REPLACE PROCEDURE P_CARD_CHANGE
(
I_ID_RETURN IN INTEGER, 
I_XCRD_ID IN INTEGER,  
I_XCST_ID IN INTEGER,   
I_ICC IN INTEGER,  
I_COMMITED IN INTEGER, 

O_CODE  OUT  INTEGER, 
O_MESSAGE OUT VARCHAR2
)
/* Процедура сохраняет в T_CARD актуальный статус карты */
IS

    X_CODE INTEGER;
    X_MESSAGE  VARCHAR2(4000);      
    V_COUNT INTEGER;

BEGIN

O_CODE := 0; O_MESSAGE := '';

SELECT 
COUNT(*) INTO V_COUNT 
FROM T_CARD 
WHERE 
ID_RETURN != I_ID_RETURN 
AND 
XCRD_ID = I_XCRD_ID; ---- Существует ли такая карта по другой Заявке ----

IF V_COUNT > 0 THEN

    O_CODE := 60001;
    O_MESSAGE := 'Ошибка! Данная карта уже проходит по другой заявке. ID карты = ' || I_XCRD_ID || '; ICC = ' || I_ICC;
    P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
    RETURN;
    
END IF;

SELECT COUNT(*) INTO V_COUNT FROM T_CARD WHERE ID_RETURN = I_ID_RETURN AND XCRD_ID = I_XCRD_ID; ---- Существует ли такая карта по данной Заявке ----

IF V_COUNT > 0 THEN

    UPDATE T_CARD 
    SET
    XCST_ID = I_XCST_ID,
    FLAG_COMMITED = I_COMMITED
    WHERE  ID_RETURN = I_ID_RETURN AND XCRD_ID = I_XCRD_ID;
    
ELSE

    INSERT INTO 
    T_CARD (ID_RETURN,   XCRD_ID,     XCST_ID,      ICC,     FLAG_COMMITED)
    VALUES (I_ID_RETURN, I_XCRD_ID, I_XCST_ID,  I_ICC,  I_COMMITED);     

END IF;



EXCEPTION 
      
        WHEN OTHERS THEN
      
                 O_CODE := 60991;
                 O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
                 --------ROLLBACK;    Здесь не нужно делать ROLLBACK. Это сделает внешняя процедура при необходимости.        


END;