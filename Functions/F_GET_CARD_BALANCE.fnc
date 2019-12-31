CREATE OR REPLACE FUNCTION CARD_BACK.F_GET_CARD_BALANCE(I_ICC IN INTEGER)
   RETURN INTEGER 
   IS 
   X INTEGER;
   ID_PARTY INTEGER;
BEGIN /* Определим номинал КЭО по ICC */
   

  BEGIN ---- Попробуем определить баланс из XCARD ----
       SELECT BALANCE_$, PRTY_PRTY_ID INTO X, ID_PARTY FROM XMASTER.XCARD WHERE TO_NUMBER(ICC)=I_ICC;
  EXCEPTION WHEN OTHERS THEN X:=0;
  END;
   
   

   IF NVL(X,0)=0 THEN ---- Если не удалось определить баланс из XCARD то попробуем определить баланс из таблицы PARTY ----
   
   
         BEGIN   
              SELECT PRICE INTO X FROM XMASTER.PARTY WHERE PRTY_ID=ID_PARTY; 
          EXCEPTION WHEN OTHERS THEN X:=0;
          END;          
          
            
           IF NVL(X,0)=0 THEN ---- Если не удалось определить баланс  то попробуем определить баланс из представления V_FRAUD_CARD_BALANCE ----
           
            
            SELECT PRICE INTO X FROM V_FRAUD_CARD_BALANCE WHERE TO_NUMBER(ICC) = I_ICC;
           
                       
           END IF;
   
   END IF;
   
   RETURN( NVL(X,0) );
   
  
EXCEPTION 
    WHEN OTHERS THEN 
           RETURN(-1);
     
END;
