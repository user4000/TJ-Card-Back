
CREATE OR REPLACE FUNCTION F_SUSPECT_RANGE(I_MIN IN INTEGER, I_MAX IN INTEGER)
RETURN VARCHAR2 
IS
F VARCHAR2(100);   
I_COUNT INTEGER;
BEGIN

   
    SELECT COUNT(*) INTO I_COUNT FROM V_FRAUD_CARD WHERE ICC BETWEEN I_MIN AND I_MAX;
    
    IF I_COUNT = 0 THEN
        F := '';
    ELSE
        F := 'Имеются мошеннические ' || I_COUNT || ' шт.'; 
    END IF;

    RETURN(F);

EXCEPTION 
    WHEN OTHERS THEN 
           RETURN('');
     
END;
