CREATE OR REPLACE FUNCTION F_INTERSECTION(A1 INTEGER, B1 INTEGER, A2 INTEGER, B2 INTEGER)
RETURN INTEGER 
IS
F INTEGER;   
BEGIN
/*
Функция вернет значение =1 если пересечение лежащих на одной координатной прямой отрезков [A1;B1] и [A2;B2] является непустым множеством
Иначе функция вернёт значение =0
*/
   
    IF ( A2 BETWEEN A1 AND B1 ) OR ( A1 BETWEEN A2 AND B2 ) THEN 
        F := 1;
    ELSE
        F := 0;    
    END IF;

    RETURN(F);

EXCEPTION 
    WHEN OTHERS THEN 
           RETURN(1);
     
END;
