CREATE OR REPLACE PROCEDURE P_CARD_ACTIVATION_RESULT ( I_XCRD_ID IN INTEGER, I_CODE IN VARCHAR2, I_MESSAGE IN VARCHAR2, O_CODE  OUT  INTEGER,  O_MESSAGE OUT VARCHAR2)
/* Запишем код возврата и сообщение от SLR после активации карты. Процедура предназначена для вызова из сценария Card Activator  */
IS
BEGIN

O_CODE := 0; O_MESSAGE := '';

UPDATE TA_CARD 
SET 
R_CODE = I_CODE, 
R_MESSAGE = I_MESSAGE
WHERE XCRD_ID = I_XCRD_ID;

COMMIT;

EXCEPTION 
        WHEN OTHERS THEN
                 O_CODE := 80991;
                 O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
                 ROLLBACK;            

END;