CREATE OR REPLACE FUNCTION F_GET_PIN( I_ICC IN INTEGER )
RETURN VARCHAR2 
IS

F VARCHAR2(12);  
 
BEGIN
   
SELECT PIN INTO F FROM XMASTER.XCARD WHERE ICC = LPAD(I_ICC,10,'0');

RETURN (F);

EXCEPTION 
    WHEN OTHERS THEN 
           RETURN('0');
     
END;
