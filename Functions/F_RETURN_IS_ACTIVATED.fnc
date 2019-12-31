CREATE OR REPLACE FUNCTION CARD_BACK.F_RETURN_IS_ACTIVATED(I_ID_RETURN IN INTEGER)
   RETURN INTEGER 
   IS 
   F INTEGER;
   
BEGIN  /* Функция вернет значение =1 если данная заявка активирована. В противном случае функция вернёт значение не равное 1 */
   
    SELECT COUNT(*) INTO F
    FROM V_RETURN_ACTIVATED
    WHERE ID_RETURN = I_ID_RETURN  AND C_TOTAL = C_ACTIVATED;
  
    RETURN(F);

EXCEPTION 
    WHEN OTHERS THEN 
           RETURN(0);
     
END;