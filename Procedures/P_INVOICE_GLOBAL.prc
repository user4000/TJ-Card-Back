CREATE OR REPLACE PROCEDURE P_INVOICE_GLOBAL(I_MSISDN IN INTEGER, O_CODE OUT  INTEGER, O_MESSAGE OUT VARCHAR2 )

IS

  o_clnt_id        number;
  o_subs_id        number;
  o_trpl_id        number;
  o_type_id        number;
  o_reliab_id      number;
  o_stat_id        number;
  o_balance        number;
  o_curr_id        number;
  o_name           varchar2(500);
  o_trpl_name      varchar2(500);
  o_bal_date       varchar2(50);
  o_lang_id        number;
  o_phone1         varchar2(200);
  o_contact_phone  varchar2(500);
  o_sign_date      VARCHAR2(50);
  o_account        VARCHAR2(50);
  o_branch_id      number;
  o_parent_clnt_id NUMBER;
  o_result         number;
  o_err_msg        varchar2(500);
  o_stat_name      varchar2(200);  



BEGIN

O_CODE := 0; O_MESSAGE := '';


  bcsc_interface.global@BILLING
  (
    I_MSISDN,
    1,
    o_clnt_id,
    o_subs_id,
    o_trpl_id,
    o_type_id,
    o_reliab_id,
    o_stat_id,  
    o_balance,  
    o_curr_id,  
    o_name,     
    o_trpl_name, 
    o_bal_date,  
    o_lang_id,   
    o_phone1,    
    o_contact_phone,
    o_sign_date,   
    o_account,      
    o_branch_id,    
    o_parent_clnt_id,
    o_result,
    o_err_msg
  );      

O_CODE := o_result;
O_MESSAGE := o_err_msg;

EXCEPTION 
    WHEN OTHERS THEN 
           O_CODE := 1;
           O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
     
END;