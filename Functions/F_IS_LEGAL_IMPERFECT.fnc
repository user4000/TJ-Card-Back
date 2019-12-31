
CREATE OR REPLACE FUNCTION CARD_BACK.F_IS_LEGAL_IMPERFECT (V_MIN INTEGER, V_MAX INTEGER)
RETURN INTEGER 
IS
F INTEGER;   

S_USER_IMPERFECT_MAKER VARCHAR2(100);
V_USER_IMPERFECT_MAKER INTEGER;
S_DATE_IMPERFECT VARCHAR2(50);
V_DATE_IMPERFECT DATE;

V_COUNT1 INTEGER; ---- Число КЭО не мошеннических - статус - Любой
V_COUNT2 INTEGER; ---- Число КЭО не мошеннических - статус - Продана
V_COUNT3 INTEGER; ---- Число КЭО не мошеннических - статус - Дефектная

BEGIN
/*
Функция вернет значение =1 если все карты данного диапазона,
которые не входят в список мошеннических V_FRAUD_CARD
имеют статусы из следующего списка:

1. Продана

2. Дефектная (но перевёл их в этот статус именно UTILIZATOR и только после определённой даты, указанной в T_PARAMETER)

Иначе функция вернёт значение =0
*/

F := 0;
S_DATE_IMPERFECT :=  CB.F_PARAMETER('REQUEST','IMPERFECT_DATE');
V_DATE_IMPERFECT := TO_DATE(S_DATE_IMPERFECT, 'YYYY/MM/DD' );
S_USER_IMPERFECT_MAKER := CB.F_PARAMETER('REQUEST','IMPERFECT_MAKER'); /* Пользователь, который переводит КЭО в "Дефектные" по заявкам полоьзователей */
V_USER_IMPERFECT_MAKER := CARD_BACK.F_GET_USER_ID(S_USER_IMPERFECT_MAKER);

/*=======================================================================================*/

SELECT 
    COUNT(*)   
INTO
    V_COUNT1 ---- Число КЭО не мошеннических - статус - Любой
FROM 
(SELECT * FROM  Xmaster.Xcard WHERE TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX) A
        LEFT JOIN V_FRAUD_CARD F
            ON A.ICC = F.ICC 
WHERE  F.ICC IS NULL ;

   
SELECT 
    COUNT(*)   
INTO
    V_COUNT2 ---- Число КЭО не мошеннических - статус - Продана
FROM 
(SELECT * FROM  Xmaster.Xcard WHERE XCST_XCST_ID=CB.CA_SOLD AND TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX) A
    LEFT JOIN V_FRAUD_CARD F
        ON A.ICC = F.ICC 
WHERE  F.ICC IS NULL ; 

    
SELECT 
    COUNT(*)   
INTO
    V_COUNT3 ---- Число КЭО не мошеннических - статус - Дефектная
FROM 
(SELECT * FROM  Xmaster.Xcard WHERE XCST_XCST_ID=CB.CA_IMPERFECT AND TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX) A
    INNER JOIN CARD_BACK.V_SOLD_AND_IMPERFECT B
    ON A.XCRD_ID=B.XCRD_ID
        LEFT JOIN V_FRAUD_CARD F
            ON A.ICC = F.ICC 
WHERE  1=1
AND B.START_DATE >= V_DATE_IMPERFECT ---- Дата должна быть больше указанной в таблице T_PARAMETER 
AND B.USER_ID = V_USER_IMPERFECT_MAKER ---- Перевод в статус "Дефектная" должен был выполнить определённый пользователь
AND  F.ICC IS NULL ; ---- КЭО не должна быть в списке Мошеннических

/*=======================================================================================*/
    

IF (V_COUNT1 = V_COUNT2 + V_COUNT3) AND (V_COUNT1 > 0) THEN
    F := 1; ---- Диапазон карт подходит для возврата.
END IF;

RETURN(F);

EXCEPTION 
    WHEN OTHERS THEN 
           RETURN(0);
     
END;
