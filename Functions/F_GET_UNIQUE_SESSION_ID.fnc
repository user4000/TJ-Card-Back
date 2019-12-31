CREATE OR REPLACE FUNCTION CARD_BACK.F_GET_UNIQUE_SESSION_ID
   RETURN VARCHAR2 
   IS 
   S_SESSION VARCHAR2(500);
   TS NUMBER;

BEGIN
   
   ----TS := round( (sysdate - to_date('20170101 000000', 'YYYYMMDD HH24MISS'))*86400 )  ;
   TS := round( (sysdate - trunc(sysdate) )*86400 )  ;

   SELECT 
       SYS_CONTEXT ('USERENV', 'SESSION_USER') || '-' || 
       SYS_CONTEXT('USERENV', 'SESSIONID')         || '-' || 
       SUBSTR(dbms_random.value(0,1), 3, 10)      || '-' || 
       LPAD( TS,  5, '0')
       
   INTO S_SESSION FROM DUAL;
   
   RETURN (S_SESSION);

EXCEPTION 
    WHEN OTHERS THEN 
           ROLLBACK;
           RETURN('0');
     
END;
