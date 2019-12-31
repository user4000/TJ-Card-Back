CREATE OR REPLACE PROCEDURE CARD_BACK.P_WAREHOUSE_CHECK_STATUS_V2 (  O_CODE  OUT  INTEGER,  O_MESSAGE OUT VARCHAR2 )
/* 
Дано:

В таблице TD_RANGE_WAREHOUSE
задано множество непересекающихся отрезков [ ICC_START; ICC_END ]
являющихся подмножеством всех КЭО из XMASTER.XCARD

Результат:

Данная процедура вычисляет статус КЭО из каждого отрезка и выводит их в таблицу TD_RANGE_WAREHOUSE_STATUS
*/
IS

V_MIN INTEGER;
V_MAX INTEGER;

V_MIN_PREVIOUS INTEGER;
V_MAX_PREVIOUS INTEGER;

A1 INTEGER;
B1 INTEGER;

N INTEGER;
J INTEGER;
S_E VARCHAR2(100);

CURSOR  CUR_RANGE IS     
    SELECT ICC_START, ICC_END 
            FROM CARD_BACK.TD_RANGE_WAREHOUSE 
                ORDER BY ICC_START;

BEGIN

O_CODE := 0; O_MESSAGE := '';

DBMS_OUTPUT.PUT_LINE('Процедура вычисления начала...');

J := 0;

SELECT COUNT(*) INTO N FROM CARD_BACK.TD_RANGE_WAREHOUSE;

IF N=0 THEN
    raise_application_error( -20001, 'Таблица TD_RANGE_WAREHOUSE пуста!' );
END IF;

V_MIN :=  0;
V_MAX := 0;

DELETE FROM TD_RANGE_WAREHOUSE_STATUS;

OPEN CUR_RANGE; 
LOOP

    FETCH CUR_RANGE INTO V_MIN, V_MAX;
    EXIT WHEN CUR_RANGE%NOTFOUND;
   
    J := J + 1;
   
    INSERT INTO TD_RANGE_WAREHOUSE_STATUS
        SELECT J, V_MIN, V_MAX, A.XCST_XCST_ID, COUNT(*)   
            FROM XMASTER.XCARD A
                WHERE TO_NUMBER(A.ICC) BETWEEN V_MIN AND V_MAX
            GROUP BY A.XCST_XCST_ID
    ORDER BY A.XCST_XCST_ID;
        
    DBMS_OUTPUT.PUT_LINE(J || '   ' || CARD_BACK.F_RANGE(V_MIN,V_MAX));

END LOOP;
CLOSE CUR_RANGE;

DBMS_OUTPUT.PUT_LINE('Процедура вычисления завершила.');

COMMIT;

EXCEPTION 
        WHEN OTHERS THEN
                 ROLLBACK;
                 O_CODE := 1;
                 O_MESSAGE := 'Произошла ошибка! ' || SQLERRM;
     
END;
/
