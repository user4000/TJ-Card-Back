/* GRANT EXECUTE ON P_RANGE_SELECT TO CARD_BACK_ROLE */
CREATE OR REPLACE PROCEDURE P_RANGE_REVISION ( I_ID_SESSION IN VARCHAR2,  I_ID_RETURN INTEGER,  O_CODE  OUT  INTEGER,  O_MESSAGE OUT VARCHAR2)
IS
/* Сравним все диапазоны из TB_RANGE с диапазонами, записанными в T_RETURN_RANGE */
X_CODE INTEGER; 
X_MESSAGE VARCHAR2(4000);

I_CODE_SESSION INTEGER;
I_DATE DATE;

I_COUNT1 INTEGER;
I_COUNT2 INTEGER;
I_COUNT3 INTEGER;


BEGIN

O_CODE := 0; O_MESSAGE := '';



SELECT CODE_SESSION INTO I_CODE_SESSION FROM TB_SESSION WHERE ID_SESSION =  I_ID_SESSION AND LOGON_DATE >= TRUNC(sysdate);


SELECT COUNT(*) INTO I_COUNT3 FROM
T_RETURN_RANGE A
INNER JOIN 
TB_RANGE B
ON A.RANGE_MIN=B.RANGE_MIN AND A.RANGE_MAX=B.RANGE_MAX
WHERE A.ID_RETURN = I_ID_RETURN AND B.CODE_SESSION = I_CODE_SESSION;


SELECT COUNT(*) INTO I_COUNT2 
FROM T_RETURN_RANGE A
WHERE A.ID_RETURN = I_ID_RETURN;



SELECT COUNT(*) INTO I_COUNT1 FROM
TB_RANGE B
WHERE B.CODE_SESSION = I_CODE_SESSION;


IF (I_COUNT1=I_COUNT2) AND (I_COUNT1=I_COUNT3) AND (I_COUNT3) > 0 THEN
    NULL;
ELSE

    O_CODE := 82002;
    O_MESSAGE := 'Произошла ошибка при контроле вводимой пользователем информации о диапазонах КЭО.';

END IF;    






EXCEPTION 
        WHEN OTHERS THEN
                 O_CODE := 82001;
                 O_MESSAGE := '';
     
END;