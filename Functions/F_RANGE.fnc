CREATE OR REPLACE FUNCTION CARD_BACK.F_RANGE(I_MIN IN INTEGER, I_MAX IN INTEGER)
   RETURN VARCHAR2 
   IS 
   F VARCHAR2(50);
BEGIN /* Форматируем строковое значение представляющее один диапазон КЭО */
     
   F := LPAD(I_MIN,10,'0') || ' - ' || LPAD(I_MAX,10,'0');
   
   RETURN( F );
   
EXCEPTION 
    WHEN OTHERS THEN 
           RETURN('?');
     
END;