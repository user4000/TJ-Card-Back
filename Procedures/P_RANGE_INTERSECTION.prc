CREATE OR REPLACE PROCEDURE CARD_BACK.P_RANGE_INTERSECTION(I_MIN IN INTEGER, I_MAX IN INTEGER, O_CODE OUT  INTEGER, O_MESSAGE OUT VARCHAR2 )
 ---- Вернёт значение=1 если данный диапазон пересекается с уже имеющимися в БД диапазонами. Если нет пересечений вернёт значение=0 ----
IS

U_COUNT  INTEGER; 
U_ID_RETURN  INTEGER;
U_MIN  INTEGER;
U_MAX  INTEGER;

BEGIN

O_CODE := 0; O_MESSAGE := '';

SELECT COUNT(*), MIN(ID_RETURN) INTO U_COUNT, U_ID_RETURN
FROM V_ACTIVE_RANGE 
WHERE F_INTERSECTION ( RANGE_MIN, RANGE_MAX, I_MIN, I_MAX ) > 0; ---- Проверим пересечение отрезков с уже имеющимися диапазонами активных Возвратов ----
                       

IF U_COUNT > 0 THEN ---- Имеет место пересечение с уже имеющимися диапазонами ----
                       
   SELECT RANGE_MIN, RANGE_MAX INTO U_MIN, U_MAX
        FROM T_RETURN_RANGE 
            WHERE 
                ID_RETURN = U_ID_RETURN            
                and            
                F_INTERSECTION ( RANGE_MIN, RANGE_MAX, I_MIN, I_MAX ) > 0
                and
                ROWNUM=1; ---- Ровно одна строка должна быть выбрана ----
                
                O_CODE := 1;
                O_MESSAGE := 'Диапазон ' || F_RANGE(I_MIN, I_MAX) || ' пересекается с диапазоном '  || F_RANGE(U_MIN, U_MAX) || ' Заявка номер ' || U_ID_RETURN || ' ' ; 
                
END IF;                


EXCEPTION 
    WHEN OTHERS THEN 
           O_CODE := 1;
           O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
     
END;