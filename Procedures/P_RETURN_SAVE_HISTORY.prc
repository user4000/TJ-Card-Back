CREATE OR REPLACE PROCEDURE P_RETURN_SAVE_HISTORY
 /* 
 Сохраняем в историю текущие значения атрибутов сущности "Возврат" 
 (предполагается использовать ПОСЛЕ вставки или изменения Атрибутов заявки - для того, чтобы в истории были актуальные данные) 
 */
 ( 
 I_ID_RETURN IN INTEGER,
 O_CODE  OUT  INTEGER
 ) IS
 V_ID_USER INTEGER;
 
 BEGIN ---- Процедура предназначена для вызова из других процедур. Обработка ошибок, COMMIT и ROLLBACK здесь не предполагаются ----
 
 V_ID_USER := F_GET_CURRENT_USER_ID;
  
 O_CODE := 1;
   
 INSERT INTO CARD_BACK.T_RETURN_HISTORY 
  (
      ID_USER, 
      ID_RETURN,
      ID_BANK,
      BANK_ACCOUNT,
      PERSON_ACCOUNT,
      ID_STATUS,
      ID_PAYMENT_TYPE 
  ) 
  SELECT 
      V_ID_USER,
      ID_RETURN,
      ID_BANK,
      BANK_ACCOUNT,
      PERSON_ACCOUNT,
      ID_STATUS,
      ID_PAYMENT_TYPE
  FROM CARD_BACK.T_RETURN
  WHERE ID_RETURN = I_ID_RETURN; 
  
  O_CODE := 0;
 
 END;