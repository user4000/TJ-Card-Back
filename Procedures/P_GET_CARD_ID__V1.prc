/* Находим ID карты и Статус карты по ICC */
CREATE OR REPLACE PROCEDURE CARD_BACK.P_GET_CARD_ID (I_ICC IN INTEGER, O_XCRD_ID OUT INTEGER, O_XCST_ID OUT INTEGER)
IS 
X_CODE INTEGER;
X_MESSAGE VARCHAR2(4000);
BEGIN
   
/*
 
  BEGIN ---- Попробуем определить ID и статус из XCARD ----
      SELECT XCRD_ID, XCST_XCST_ID INTO O_XCRD_ID, O_XCST_ID FROM XMASTER.XCARD WHERE ICC=LPAD(I_ICC,10,'0');
  EXCEPTION WHEN OTHERS THEN 
    O_XCRD_ID:=0;
  END;
   

   
   IF NVL(O_XCRD_ID,0)=0 THEN ---- Если не удалось определить ID и  статус из XCARD то попробуем определить  ID и статус из таблицы XCARD_ARCHIVE ----
    
      BEGIN   
          SELECT XCRD_ARCH_ID, XCST_XCST_ID INTO O_XCRD_ID,  O_XCST_ID FROM XMASTER.XCARD_ARCHIVE WHERE  ICC=LPAD(I_ICC,10,'0') AND END_DATE > sysdate + 1 ; 
       EXCEPTION WHEN OTHERS THEN 
            O_XCRD_ID:=0;
       END;          
   
   END IF;
   
*/


  BEGIN ---- Попробуем определить ID и статус из XCARD ----
      SELECT XCRD_ID, XCST_XCST_ID INTO O_XCRD_ID, O_XCST_ID FROM XMASTER.XCARD WHERE ICC=LPAD(I_ICC,10,'0');
  EXCEPTION WHEN OTHERS THEN ---- Если не удалось определить ID и  статус из XCARD то попробуем определить  ID и статус из таблицы XCARD_ARCHIVE ----
      SELECT XCRD_ARCH_ID, XCST_XCST_ID INTO O_XCRD_ID,  O_XCST_ID FROM XMASTER.XCARD_ARCHIVE WHERE  ICC=LPAD(I_ICC,10,'0') AND END_DATE > sysdate + 1 ;
  END;


EXCEPTION 
    WHEN OTHERS THEN 

        O_XCRD_ID:=0;
        O_XCST_ID:=0;
   
END;