CREATE OR REPLACE FUNCTION CARD_BACK.F_RANGE_STATUS_INFO (V_MIN INTEGER, V_MAX INTEGER)
RETURN VARCHAR2 
IS
F VARCHAR2(500);   

/*
Если функция вернула значение = пустая строка (в Оракл это IS NULL) - то диапазон возврату не подлежит
Иначе = возврат возможен
*/

S_USER_IMPERFECT_MAKER VARCHAR2(100);
V_USER_IMPERFECT_MAKER INTEGER;
S_DATE_IMPERFECT VARCHAR2(50);
V_DATE_IMPERFECT DATE;

N_COUNT INTEGER; ---- Число КЭО в указанном пользователем диапазоне
V_COUNT1 INTEGER; ---- Число КЭО не мошеннических - статус - Продана
V_COUNT2 INTEGER; ---- Число КЭО  мошеннических - статус - Любой
V_COUNT3 INTEGER; ---- Число КЭО не мошеннических - статус - Дефектная, Подлежащая Возврату и Не Мошенническая



D_DEBUG TIMESTAMP;

                PROCEDURE P_DEBUG(V_MESSAGE VARCHAR2)
                IS D_TIME TIMESTAMP;
                BEGIN
                    --D_TIME := SYSTIMESTAMP();
                    --DBMS_OUTPUT.PUT_LINE( D_TIME - D_DEBUG || ' --- ' || V_MESSAGE );
                    NULL;
                END;

BEGIN


F := ''; D_DEBUG := SYSTIMESTAMP();

S_DATE_IMPERFECT :=  CB.F_PARAMETER('REQUEST','IMPERFECT_DATE');
V_DATE_IMPERFECT := TO_DATE(S_DATE_IMPERFECT, 'YYYY/MM/DD' );
S_USER_IMPERFECT_MAKER := CB.F_PARAMETER('REQUEST','IMPERFECT_MAKER'); /* Пользователь, который переводит КЭО в "Дефектные" по заявкам полоьзователей */
V_USER_IMPERFECT_MAKER := CARD_BACK.F_GET_USER_ID(S_USER_IMPERFECT_MAKER);


N_COUNT := V_MAX-V_MIN+1;

/*=======================================================================================*/

P_DEBUG('F_RANGE_STATUS_INFO 1');
-------------------------------------------------------------------------------------------------------
SELECT 
    COUNT(*)   
INTO
    V_COUNT1 ---- Число КЭО не мошеннических - статус - Продана
FROM 
(SELECT * FROM  Xmaster.Xcard WHERE XCST_XCST_ID=5 AND TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX) A
        LEFT JOIN TD_FRAUD_CARD F
            ON A.ICC = F.ICC 
WHERE  F.ICC IS NULL ;
P_DEBUG('F_RANGE_STATUS_INFO 2');
-------------------------------------------------------------------------------------------------------
SELECT 
    COUNT(*)   
INTO
    V_COUNT2 ---- Число КЭО  мошеннических - статус - Любой
FROM 
TD_FRAUD_CARD
WHERE  TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX;
P_DEBUG('F_RANGE_STATUS_INFO 3');
-------------------------------------------------------------------------------------------------------
SELECT 
    COUNT(*)   
INTO
    V_COUNT3 ---- Число КЭО не мошеннических - статус - Дефектная, Подлежащая Возврату
FROM 
CARD_BACK.TD_IMPERFECT_NOT_FRAUD  /* Раньше было V_IMPERFECT_NOT_FRAUD  */
WHERE  TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX;
P_DEBUG('F_RANGE_STATUS_INFO 4');
-------------------------------------------------------------------------------------------------------

/*=======================================================================================*/
    

IF N_COUNT = (V_COUNT1+V_COUNT2+V_COUNT3) THEN ---- Диапазон карт подходит для возврата.

    IF V_COUNT1 > 0 THEN
    F := F || 'Продана+';
    END IF;
    
    IF V_COUNT2 > 0 THEN
    F := F || 'Мошенническая+';
    END IF;
    
    IF V_COUNT3 > 0 THEN
    F := F || 'Дефектная+';
    END IF;
    
    F := SUBSTR(F,1, LENGTH(F)-1);

END IF;

/*=======================================================================================*/


RETURN(F);

EXCEPTION 
    WHEN OTHERS THEN 
           RETURN('');
     
END;