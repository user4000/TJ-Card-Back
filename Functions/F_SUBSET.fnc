CREATE OR REPLACE FUNCTION CARD_BACK.F_SUBSET(BIG_A1 INTEGER, BIG_B1 INTEGER, A2 INTEGER, B2 INTEGER)
RETURN INTEGER 
IS
F INTEGER;   
BEGIN
/*
Функция вернет значение =1 если отрезок [A2;B2] является подмножеством отрезка [BIG_A1; BIG_B1]
Иначе функция вернёт значение =0
*/
   
    IF ( BIG_A1 <= A2 ) AND ( BIG_B1 >= B2 ) AND ( A2 <= B2 ) AND (BIG_A1<=BIG_B1) THEN 
        F := 1;
    ELSE
        F := 0;    
    END IF;

    RETURN(F);

EXCEPTION 
    WHEN OTHERS THEN 
           RETURN(1);
     
END;
