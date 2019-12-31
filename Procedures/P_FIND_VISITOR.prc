/*
GRANT EXECUTE ON CARD_BACK.P_FIND_VISITOR TO CARD_BACK_ROLE
*/
CREATE OR REPLACE PROCEDURE P_FIND_VISITOR 
 ( 
 I_MSISDN VARCHAR2, ---- Номер телефона абонента
 I_ID_VISITOR INTEGER, ---- Идентификатор из таблицы T_VISITOR
 O_CODE  OUT  INTEGER,
 O_MESSAGE OUT VARCHAR2,
 O_REFCURSOR OUT SYS_REFCURSOR
 ) 
 
/*
Пробуем найти данные посетителя по номеру телефона или по ID_VISITOR.
*/
 
 IS 
 
V_SNAME VARCHAR2(100);
V_FNAME VARCHAR2(100);
V_PNAME VARCHAR2(100); 
V_ADDRESS VARCHAR2(500);
V_PASSPORT VARCHAR2(500);
V_MSISDN VARCHAR2(11);

V_CLNT_ID INTEGER;
V_SUBS_ID INTEGER;
V_CUSTOMER_ID INTEGER;

X_CODE INTEGER;
X_MESSAGE VARCHAR2(2000);

BEGIN

O_CODE  := 0; O_MESSAGE := '';
V_MSISDN := TRIM(I_MSISDN);

OPEN O_REFCURSOR FOR 
SELECT 
    V_SNAME as SNAME,
    V_FNAME as FNAME,
    V_PNAME as PNAME,
    V_ADDRESS as ADDRESS,
    V_PASSPORT as PASSPORT 
FROM DUAL;


        BEGIN ---- В этом блоке попробуем найти данные в БД INVOICE ----
     
            SELECT sh.CLNT_ID, SH.SUBS_ID, CL.CUSTOMER_ID 
            INTO V_CLNT_ID, V_SUBS_ID, V_CUSTOMER_ID
            FROM 
                SMASTER.subs_history@BILLING sh, 
                SMASTER.phone@BILLING ph, 
                SMASTER.client@BILLING cl 
            WHERE 1=1
                and sysdate BETWEEN sh.stime and sh.etime-1/(24*60*60) 
                and sh.PHONE_ID=ph.PHONE_ID 
                and sh.CLNT_ID = cl.CLNT_ID
                and PH.MSISDN=V_MSISDN;


            SELECT MAX(SNAME), MAX(FNAME), MAX(PNAME) 
            INTO V_SNAME, V_FNAME, V_PNAME
            FROM
            (
                SELECT                
                CASE CN_DICT_CODE WHEN 'surname' THEN CN_VALUE ELSE '' END as SNAME,
                CASE CN_DICT_CODE WHEN 'name' THEN CN_VALUE ELSE '' END as FNAME,
                CASE CN_DICT_CODE WHEN 'patronymic' THEN CN_VALUE ELSE '' END as PNAME                 
                FROM SMASTER.CUSTOMER_NAME_TRN@BILLING CN
                WHERE customer_id=V_CUSTOMER_ID and LANG_ID=1
            );
            
            V_PASSPORT := INV_CUSTOMER.GET_CURRENT_CUST_IDDOC_STR@BILLING (V_CUSTOMER_ID, X_CODE, X_MESSAGE);
            
            V_ADDRESS :=  INV_CUSTOMER.Get_Cust_Addr_Full@BILLING (V_CUSTOMER_ID, 1);
            
            ----O_MESSAGE := V_CUSTOMER_ID;

        EXCEPTION ---- В БД Invoice не удалось найти данные ----
                WHEN OTHERS THEN
     
                     O_CODE := 2;
                     O_MESSAGE := '';

        END;
        
        
IF O_CODE = 2 THEN ---- Если не удалось найти данные в БД Invoice то возможно данные о посетителе есть в текущей схеме ----

    O_CODE := 0;

    SELECT COUNT(*) INTO X_CODE 
    FROM T_VISITOR 
    WHERE ID_VISITOR = I_ID_VISITOR;
    
    IF X_CODE=1 THEN
    
        SELECT SNAME, FNAME, PNAME, ADDRESS, PASSPORT
        INTO V_SNAME, V_FNAME, V_PNAME, V_ADDRESS, V_PASSPORT
        FROM T_VISITOR
        WHERE ID_VISITOR = I_ID_VISITOR;
    
    ELSE
        
        O_CODE := 3;
        O_MESSAGE := 'Данные посетителя не найдены';
    
    END IF;


END IF;        


OPEN O_REFCURSOR FOR 
SELECT 
    V_SNAME as SNAME,
    V_FNAME as FNAME,
    V_PNAME as PNAME,
    V_ADDRESS as ADDRESS,
    V_PASSPORT as PASSPORT 
FROM DUAL;


EXCEPTION 
        WHEN OTHERS THEN          
             O_CODE := 1;
             O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);            

END;

 