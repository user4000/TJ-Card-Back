CREATE OR REPLACE PROCEDURE CARD_BACK.P_RETURN_INTERSECTION(I_ID_RETURN IN INTEGER, O_CODE OUT  INTEGER, O_MESSAGE OUT VARCHAR2 )
 ---- Вернёт значение=1 если данный Возврат пересекается с уже имеющимися в БД диапазонами (И даже сам с собой) . Если нет пересечений вернёт значение=0 ----
IS

U_COUNT  INTEGER; 
U_ID_RETURN  INTEGER;

I_MIN  INTEGER;
I_MAX  INTEGER;

U_MIN  INTEGER;
U_MAX  INTEGER;


BEGIN

O_CODE := 0; O_MESSAGE := '';


---- Сначала проверим пересечение диапазонов внутри Заявки ----

WITH T1 AS
(select ROWNUM as N, A.*  FROM V_ACTIVE_RANGE  A WHERE ID_RETURN=I_ID_RETURN  ORDER BY 2,1)

SELECT COUNT(*) INTO U_COUNT FROM
(
    SELECT B.RANGE_MIN as A1, B.RANGE_MAX as B1, C.RANGE_MIN as A2, C.RANGE_MAX as B2 FROM T1 B INNER JOIN T1 C 
    ON B.N < C.N
    WHERE F_INTERSECTION(B.RANGE_MIN, B.RANGE_MAX, C.RANGE_MIN, C.RANGE_MAX) > 0
    AND ROWNUM = 1
);
                     

IF U_COUNT > 0 THEN ---- Имеет место пересечение с уже имеющимися диапазонами той же Заявки ----
                       

                WITH T1 AS
                (select ROWNUM as N, A.*  FROM V_ACTIVE_RANGE  A WHERE ID_RETURN=I_ID_RETURN  ORDER BY 2,1)

                SELECT A1, B1, A2, B2 INTO I_MIN, I_MAX, U_MIN, U_MAX FROM
                (
                    SELECT B.RANGE_MIN as A1, B.RANGE_MAX as B1, C.RANGE_MIN as A2, C.RANGE_MAX as B2 FROM T1 B INNER JOIN T1 C 
                    ON B.N < C.N
                    WHERE F_INTERSECTION(B.RANGE_MIN, B.RANGE_MAX, C.RANGE_MIN, C.RANGE_MAX) > 0
                    AND ROWNUM = 1
                );
               
                O_CODE := 1;
                O_MESSAGE := 'Ошибка! Диапазон ' || F_RANGE(I_MIN, I_MAX) || ' пересекается с диапазоном '  || F_RANGE(U_MIN, U_MAX) || ' Оба эти диапазона из Заявки номер ' || I_ID_RETURN || ' ' ; 
                
END IF;                

---- Теперь проверим пересечение диапазонов снаружи Заявки ----

WITH 
T1 AS
(select A.*  from V_ACTIVE_RANGE  A WHERE ID_RETURN = I_ID_RETURN  ORDER BY 1,2),
T2 AS
(select A.*  from V_ACTIVE_RANGE  A WHERE ID_RETURN != I_ID_RETURN  ORDER BY 1,2)

SELECT COUNT(*) INTO U_COUNT FROM
(
    SELECT T1.RANGE_MIN as A1, T1.RANGE_MAX as B1, T2.RANGE_MIN as A2, T2.RANGE_MAX as B2 FROM T1 , T2 
    WHERE F_INTERSECTION(T1.RANGE_MIN, T1.RANGE_MAX, T2.RANGE_MIN, T2.RANGE_MAX) > 0
    AND ROWNUM = 1
);


IF U_COUNT > 0 THEN ---- Имеет место пересечение с уже имеющимися диапазонами других Заявок ----
                       

                WITH 
                T1 AS
                (select A.*  from V_ACTIVE_RANGE  A WHERE ID_RETURN = I_ID_RETURN  ORDER BY 1,2),
                T2 AS
                (select A.*  from V_ACTIVE_RANGE  A WHERE ID_RETURN != I_ID_RETURN  ORDER BY 1,2)

                SELECT  A1, B1, A2, B2, X  INTO I_MIN, I_MAX, U_MIN, U_MAX, U_ID_RETURN FROM
                (
                    SELECT T1.RANGE_MIN as A1, T1.RANGE_MAX as B1, T2.RANGE_MIN as A2, T2.RANGE_MAX as B2, T2.ID_RETURN as X FROM T1 , T2 
                    WHERE F_INTERSECTION(T1.RANGE_MIN, T1.RANGE_MAX, T2.RANGE_MIN, T2.RANGE_MAX) > 0
                    AND ROWNUM = 1
                );
               
                O_CODE := 2;
                O_MESSAGE := 'Ошибка! Диапазон ' || F_RANGE(I_MIN, I_MAX) || ' пересекается с диапазоном '  || F_RANGE(U_MIN, U_MAX) || ' из Заявки номер ' || U_ID_RETURN || ' ' ; 
                
END IF;  




EXCEPTION 
    WHEN OTHERS THEN 
           O_CODE := 1;
           O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
     
END;