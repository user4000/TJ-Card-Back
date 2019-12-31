CREATE OR REPLACE PROCEDURE CARD_BACK.P_CLASSIFICATOR
 ( 
 I_TYPE IN VARCHAR2, ---- Процедура принимает на вход названия типов BANK, VISITOR, STATUS, USER, RETURN и другие сущности Базы Данных ----
 I_ID_ENTITY INTEGER, ---- Идентификатор сущности ----
 O_CODE  OUT  INTEGER,
 O_MESSAGE OUT VARCHAR2,
 O_REFCURSOR OUT SYS_REFCURSOR ---- Выдаем на выходе требуемый клиентским приложением справочник или классификатор ----
 ) IS 
 
 V_TYPE VARCHAR2(100);
 
 BEGIN 
 
 O_CODE := 0; O_MESSAGE := '';
 
---------------------------------------------------------------------------------------------------------------------------------------------------
IF CB.F_RESTRICTED_MODE(O_CODE, O_MESSAGE) != 0 THEN
    RETURN;
END IF;
---------------------------------------------------------------------------------------------------------------------------------------------------

 V_TYPE := UPPER(I_TYPE);
  
 CASE V_TYPE
 
 WHEN 'BANK' THEN ---- Список банков ----
 
 OPEN O_REFCURSOR FOR
    SELECT B.ID_BANK, B.MFO, B.SHORT_NAME
        FROM T_BANK B
            ORDER BY B.SHORT_NAME, B.MFO;
 
 WHEN 'VISITOR' THEN ---- Список посетителей ----
  
  OPEN O_REFCURSOR FOR
    SELECT V.ID_VISITOR, V.SNAME, V.FNAME, V.PNAME, V.PASSPORT, V.ADDRESS
        FROM T_VISITOR V
            ORDER BY SNAME, FNAME, PNAME;
            
  
 WHEN 'STATUS' THEN ---- Список статусов ----
  
  OPEN O_REFCURSOR FOR
    SELECT S.ID_STATUS, S.NAME_STATUS
        FROM T_RETURN_STATUS S
        WHERE ID_STATUS NOT IN (500,600)
            ORDER BY 1,2;       
            
 WHEN 'STATUS_BY_RETURN' THEN ---- Список статусов в зависимости от конкретной заявки ----
  
    O_REFCURSOR := F_STATUS_LIST(I_ID_ENTITY) ;                
            
 WHEN 'RETURN' THEN ---- Список заявок на возврат ----
  
  OPEN O_REFCURSOR FOR
        SELECT 
            R.ID_RETURN, 
            R.ID_STATUS, 
            S.NAME_STATUS, 
            F_GET_USER_NAME(R.ID_USER) as CREATOR, 
            TO_CHAR(R.HISTORY_DATE,'yyyy-mm-dd  HH24:MI') as CREATE_DATE, 
            F_RETURN_SUM(R.ID_RETURN) as TOTAL_SUM, 
            V.SNAME, 
            V.FNAME, 
            V.PNAME, 
            V.PASSPORT, 
            V.ADDRESS, 
            V.PHONE, 
            R.ID_BANK, 
            B.MFO,
            B.SHORT_NAME,
            R.BANK_ACCOUNT,
            R.PERSON_ACCOUNT,
            R.ID_PAYMENT_TYPE,
            P.NAME_TYPE as PAYMENT_TYPE
                       
        FROM
        
        V_RETURN_FIRST_HISTORY R ---- В этом представлении только дата создания и юзер-creator из первой истории. Остальные данные - из текущей истории ----
        
        LEFT JOIN T_VISITOR V 
            ON R.ID_VISITOR = V.ID_VISITOR
        LEFT JOIN T_RETURN_STATUS S
            ON R.ID_STATUS = S.ID_STATUS   
        LEFT JOIN T_BANK B
            ON R.ID_BANK = B.ID_BANK 
        LEFT JOIN T_PAYMENT_TYPE P
            ON R.ID_PAYMENT_TYPE = P.ID_PAYMENT_TYPE
                       
        WHERE (I_ID_ENTITY=0) OR (R.ID_RETURN=I_ID_ENTITY)    
        ORDER BY R.ID_RETURN; 
        
 WHEN 'RETURN_BY_STATUS' THEN ---- Список заявок на возврат (конкретный статус) ----
  
  OPEN O_REFCURSOR FOR
        SELECT 
            R.ID_RETURN, 
            R.ID_STATUS, 
            S.NAME_STATUS, 
            F_GET_USER_NAME(R.ID_USER) as CREATOR, 
            TO_CHAR(R.HISTORY_DATE,'yyyy-mm-dd  HH24:MI') as CREATE_DATE, 
            F_RETURN_SUM(R.ID_RETURN) as TOTAL_SUM, 
            V.SNAME, 
            V.FNAME, 
            V.PNAME, 
            V.PASSPORT, 
            V.ADDRESS, 
            V.PHONE, 
            R.ID_BANK, 
            B.MFO,
            B.SHORT_NAME,
            R.BANK_ACCOUNT,
            R.PERSON_ACCOUNT,
            R.ID_PAYMENT_TYPE,
            P.NAME_TYPE as PAYMENT_TYPE
                       
        FROM
        
        V_RETURN_FIRST_HISTORY R ---- В этом представлении только дата создания и юзер-creator из первой истории. Остальные данные - из текущей истории ----
        
        LEFT JOIN T_VISITOR V 
            ON R.ID_VISITOR = V.ID_VISITOR
        LEFT JOIN T_RETURN_STATUS S
            ON R.ID_STATUS = S.ID_STATUS   
        LEFT JOIN T_BANK B
            ON R.ID_BANK = B.ID_BANK 
        LEFT JOIN T_PAYMENT_TYPE P
            ON R.ID_PAYMENT_TYPE = P.ID_PAYMENT_TYPE
                       
        WHERE  (R.ID_STATUS=I_ID_ENTITY)    
        ORDER BY R.ID_RETURN;      
                        
  WHEN 'RANGE' THEN ---- Список Диапазонов конкретного возврата (заявки на возврат) ---- 
                 
  OPEN O_REFCURSOR FOR 
    SELECT 
    ID_RETURN, 
    LPAD(RANGE_MIN,10,'0') as ICC_MIN, 
    LPAD(RANGE_MAX,10,'0') as ICC_MAX, 
    F_BALANCE, 
    RANGE_MAX-RANGE_MIN+1 as F_COUNT, 
    (RANGE_MAX-RANGE_MIN+1)*F_BALANCE as F_SUM, 
    F_SUSPECT_RANGE (RANGE_MIN, RANGE_MAX) as SUSPECT
        FROM T_RETURN_RANGE
            WHERE ID_RETURN = I_ID_ENTITY
                ORDER BY RANGE_MIN;


  WHEN 'PAYMENT' THEN ---- Список типов платежа ---- 
                 
  OPEN O_REFCURSOR FOR 
    SELECT ID_PAYMENT_TYPE, NAME_TYPE 
        FROM T_PAYMENT_TYPE
                ORDER BY ID_PAYMENT_TYPE;
                
  WHEN 'USER' THEN ---- Ф И О текущего пользователя ---- 
                 
  OPEN O_REFCURSOR FOR 
    SELECT DEF as USER_NAME
        FROM XMASTER.XCARD_USER
            WHERE DEL_DATE IS NULL  and USER_ID = F_GET_CURRENT_USER_ID;      
            
  
  WHEN 'PRICE' THEN ---- Особенная группировка диапазонов возврата по номиналу (для печати) ----
  
    OPEN O_REFCURSOR FOR 
  
            WITH TT_CARD as 
            (
                SELECT 
                ID_RETURN,
                RANGE_MIN,
                RANGE_MAX,
                (RANGE_MAX-RANGE_MIN+1) as AMOUNT,
                F_BALANCE
                FROM T_RETURN_RANGE a
                WHERE ID_RETURN=I_ID_ENTITY 
            ),
            TT_SUM as
            (
                SELECT ID_RETURN, F_BALANCE, SUM(AMOUNT) as S_AMOUNT FROM TT_CARD GROUP BY ID_RETURN, F_BALANCE 
            )
            SELECT * FROM TT_SUM
            ORDER BY 1,2,3;
            
            
            
  
  
     /*
              WITH TT_CARD as 
                (
                    SELECT 
                    ID_RETURN,
                    RANGE_MIN,
                    RANGE_MAX,
                    (RANGE_MAX-RANGE_MIN+1) as AMOUNT,
                    F_BALANCE
                    FROM T_RETURN_RANGE a
                    WHERE ID_RETURN=I_ID_ENTITY 
                ),
                TT_SUM as
                (
                    SELECT ID_RETURN, F_BALANCE, SUM(AMOUNT) as S_AMOUNT FROM TT_CARD GROUP BY ID_RETURN, F_BALANCE 
                )
                SELECT 
                B.F_BALANCE, B.S_AMOUNT, A.RANGE_MIN, A.RANGE_MAX, A.AMOUNT, A.F_BALANCE as CARD_BALANCE
                FROM TT_CARD A 
                    INNER JOIN TT_SUM B
                        ON A.F_BALANCE = B.F_BALANCE AND A.ID_RETURN = B.ID_RETURN
                ORDER BY A.ID_RETURN, A.F_BALANCE, S_AMOUNT;
    */                


  WHEN 'HISTORY' THEN ---- История Заявки на возврат  ----
  
    OPEN O_REFCURSOR FOR 
    
    SELECT 
    
        H.ID_RETURN,
        TO_CHAR(H.HISTORY_DATE,'yyyy-mm-dd  HH24:MI') as HISTORY_DATE, 
        F_GET_USER_NAME(ID_USER) as USER_NAME,
        H.ID_STATUS,
        S.NAME_STATUS as STATUS_NAME, 
        B.SHORT_NAME as BANK_NAME,
        H.BANK_ACCOUNT,
        V.VISITOR_NAME,
        M.F_AMOUNT
    
    FROM T_RETURN_HISTORY H
    
    INNER JOIN T_RETURN_STATUS S 
    ON H.ID_STATUS = S.ID_STATUS
    
    INNER JOIN T_BANK B 
    ON H.ID_BANK = B.ID_BANK
    
    INNER JOIN
    (
    SELECT A.ID_RETURN, B.SNAME || ' ' || B.FNAME || ' ' || B.PNAME as VISITOR_NAME 
        FROM T_RETURN A 
            INNER JOIN T_VISITOR B 
                ON A.ID_VISITOR=B.ID_VISITOR
    ) V
    ON H.ID_RETURN = V.ID_RETURN
    
    INNER JOIN  V_RETURN_BALANCE M
    ON H.ID_RETURN = M.ID_RETURN

    WHERE H.ID_RETURN = I_ID_ENTITY
    
    ORDER BY ID_HISTORY;



 ELSE
 
   OPEN O_REFCURSOR FOR
    SELECT DUMMY, DUMMY
        FROM DUAL;
 
 END CASE;
 
EXCEPTION 
        WHEN OTHERS THEN
                 O_CODE := 1;
                 O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);   

END;