CREATE OR REPLACE PROCEDURE P_RETURN_CHANGE_STATUS /* GRANT EXECUTE ON P_RETURN_CHANGE_STATUS  TO CARD_BACK_ROLE */
 /*
Процедура позволяет изменять статус сущности "Заявка на Возврат". Это обёртка к процедуре P_RETURN_CHANGE
*/
 ( 
 I_ID_RETURN IN INTEGER,  ---- Идентификатор Заявки (Возврата) ----
 /*
 I_ID_BANK IN INTEGER DEFAULT -1, ---- ID банка посетителя ----
 I_BANK_ACCOUNT IN VARCHAR2 DEFAULT '?' , ---- Номер счёта посетителя в указанном банке 
 I_PERSON_ACCOUNT IN VARCHAR2 DEFAULT '?' , ---- Номер личного счёта к которому привязана карта
 I_ID_PAYMENT_TYPE IN INTEGER DEFAULT -1,  ---- Тип платежа ----
 */
 I_ID_STATUS IN INTEGER DEFAULT -1, ---- Статус Заявки (Возврата) ----

 O_CODE  OUT  INTEGER, 
 O_MESSAGE OUT VARCHAR2,
 O_REFCURSOR OUT SYS_REFCURSOR
 ) IS 
 BEGIN
 
    P_RETURN_CHANGE 
    ( 
    I_ID_RETURN => I_ID_RETURN,
    I_ID_STATUS => I_ID_STATUS,
    O_CODE => O_CODE,
    O_MESSAGE => O_MESSAGE,
    O_REFCURSOR => O_REFCURSOR
    );
 
 END;

 