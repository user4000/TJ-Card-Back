CREATE OR REPLACE PROCEDURE CARD_BACK.P_WAREHOUSE_CHECK_STATUS ( I_XCST_ID INTEGER, O_CODE  OUT  INTEGER,  O_MESSAGE OUT VARCHAR2 )
/* 

Дано:

В таблице TD_RANGE_WAREHOUSE
задана система непересекающихся отрезков [ICC_START; ICC_END]
являющихся подмножеством всех КЭО из XMASTER.XCARD

Результат:

Данная процедура вычисляет количество КЭО из каждого отрезка
которые находятся НЕ в статусе I_XCST_ID
и выводит их  в DBMS_OUTPUT

*/
IS

X_MIN_ICC INTEGER;
X_MAX_ICC INTEGER;

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


X_MIN_ICC := 1;
X_MAX_ICC := 1000;



SELECT COUNT(*) INTO J FROM CARD_BACK.TD_RANGE_WAREHOUSE;

IF J=0 THEN
    raise_application_error( -20001, 'Таблица TD_RANGE_WAREHOUSE пуста!' );
END IF;

V_MIN :=  0;
V_MAX := 0;

OPEN CUR_RANGE; 
LOOP



    FETCH CUR_RANGE INTO V_MIN, V_MAX;
    EXIT WHEN CUR_RANGE%NOTFOUND;
    
    SELECT COUNT(*) INTO N FROM XMASTER.XCARD 
        WHERE XCST_XCST_ID != I_XCST_ID AND TO_NUMBER(ICC) BETWEEN V_MIN AND V_MAX;
        
    J := V_MAX - V_MIN + 1;    
    
    IF N=0 THEN
        S_E := '';
    ELSE
        S_E := ' !!! ';
    END IF;
    
    DBMS_OUTPUT.PUT_LINE( S_E || 'Диапазон ' || V_MIN || ' - ' || V_MAX || ' кол-во=' || J || ' из них НЕ в заданном статусе=' || N );


END LOOP;
CLOSE CUR_RANGE;


DBMS_OUTPUT.PUT_LINE('Процедура вычисления завершила.');




EXCEPTION 
        WHEN OTHERS THEN
                 ROLLBACK;
                 O_CODE := 1;
                 O_MESSAGE := 'Произошла ошибка! ' || SQLERRM;
     
END;
/