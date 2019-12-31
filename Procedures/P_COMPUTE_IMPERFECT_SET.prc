CREATE OR REPLACE PROCEDURE CARD_BACK.P_COMPUTE_IMPERFECT_SET ( O_CODE  OUT  INTEGER,  O_MESSAGE OUT VARCHAR2 )
/* 
 
Дано:

В таблице TD_RANGE_WAREHOUSE
задана система непересекающихся отрезков [ICC_START; ICC_END]
являющихся подмножеством всех КЭО из XMASTER.XCARD

Результат:

Данная процедура вычисляет все остальные отрезки, 
которые также являются непересекающимися между собой и между отрезками таблицы TD_RANGE_WAREHOUSE
и записывает их в таблицу TD_RANGE_IMPERFECT (в дальнейшем они должны быть переведены в статус "Дефектная")

таким образом, что если ОБЪЕДИНИТЬ 
множество отрезков из TD_RANGE_WAREHOUSE
со 
множеством TD_RANGE_IMPERFECT 
то получим 
множество всех карт из таблицы XMASTER.XCARD


Таким образом число карт таблицы  XMASTER.XCARD = число карт TD_RANGE_WAREHOUSE + число карт TD_RANGE_IMPERFECT

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

J INTEGER;
N INTEGER;

CURSOR  CUR_RANGE IS     
    SELECT ICC_START, ICC_END 
            FROM CARD_BACK.TD_RANGE_WAREHOUSE 
                ORDER BY ICC_START;

BEGIN

O_CODE := 0; O_MESSAGE := 'Расчёт интервалов дефектных карт прошёл успешно';

--SELECT MIN( TO_NUMBER(ICC) ), MAX( TO_NUMBER(ICC) ) INTO X_MIN_ICC, X_MAX_ICC FROM XMASTER.XCARD;

X_MIN_ICC := 1;
X_MAX_ICC := 1000;

O_MESSAGE := O_MESSAGE || ' ' || X_MIN_ICC || ' ' || X_MAX_ICC;

J := 0;

SELECT COUNT(*) INTO N FROM CARD_BACK.TD_RANGE_WAREHOUSE;

IF N=0 THEN
    raise_application_error( -20001, 'Таблица TD_RANGE_WAREHOUSE пуста!' );
END IF;

V_MIN :=  0;
V_MAX := 0;

OPEN CUR_RANGE; 
LOOP

    J := J + 1;

    FETCH CUR_RANGE INTO V_MIN, V_MAX;
    EXIT WHEN CUR_RANGE%NOTFOUND;
    
    IF J=1 THEN
        A1 := X_MIN_ICC;
    ELSE
        A1 := V_MAX_PREVIOUS+1;
    END IF;
    
    B1 := V_MIN-1;
       
    
    V_MIN_PREVIOUS := V_MIN;
    V_MAX_PREVIOUS := V_MAX;
    
    DBMS_OUTPUT.PUT_LINE(A1 || ' ---  ' || B1);
    INSERT INTO CARD_BACK.TD_RANGE_IMPERFECT (ICC_START, ICC_END) VALUES (A1,B1);

END LOOP;
CLOSE CUR_RANGE;

    A1 := V_MAX+1;
    B1 := X_MAX_ICC;
    DBMS_OUTPUT.PUT_LINE(A1 || ' ---  ' || B1);
    INSERT INTO CARD_BACK.TD_RANGE_IMPERFECT (ICC_START, ICC_END) VALUES (A1,B1);

COMMIT;

EXCEPTION 
        WHEN OTHERS THEN
                 ROLLBACK;
                 O_CODE := 1;
                 O_MESSAGE := 'Произошла ошибка! ' || SQLERRM;
     
END;
  
