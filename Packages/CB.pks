/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE CB AS  /* Внимание! Изменение значений констант немедленно повлияет на работу программы "Возврат КЭО" */

   TYPE REF_CURSOR IS REF CURSOR; /* GRANT EXECUTE ON CB TO TEST3 */

   ST_UNKNOWN  CONSTANT INTEGER := 0;
   ST_START  CONSTANT INTEGER := 100;
   ST_APPROVED  CONSTANT INTEGER := 150;
   ST_WAIT  CONSTANT INTEGER := 200;
   ST_COMMITED  CONSTANT INTEGER := 300;
   ST_PAUSED  CONSTANT INTEGER := 350;
   ST_CANCELED  CONSTANT INTEGER := 400;
   ST_CA_START  CONSTANT INTEGER := 500;
   ST_CA_END  CONSTANT INTEGER := 600;
   
   CA_SOLD CONSTANT INTEGER          := 5; ---- Статус "Продана" ----
   CA_ARCHIVED CONSTANT INTEGER   := 9; ---- Статус "Архивирована" ----
   CA_IMPERFECT CONSTANT INTEGER  := 10; ---- Статус "Дефектная" ----


   C_BANK_ACCOUNT_LENGTH CONSTANT INTEGER  := 23;
   
   C_ONE_SECOND  CONSTANT NUMBER := 1/86400;
   C_MINUS_ONE  CONSTANT NUMBER := -1; ---- Минус единица ----
   C_EMPTY CONSTANT VARCHAR2(1) := '';
   
   CA_QUEUE_FOR_SCHEDULER CONSTANT INTEGER   := 10 ; ---- Сколько Строк (КЭО) выдавать SCHEDULER-у SLR-а за один просмотр ----

   RC_LOGOFF  CONSTANT INTEGER   := 9001001; ---- Код возврата, предписывающий приложению совершить выход ----
   RM_LOGOFF CONSTANT VARCHAR2(200)   := 'Уважаемый пользователь! В настоящее время приложение << Возврат КЭО >> обновляется и ваша работа будет прервана. Попробуйте зайти позже. ';


   PS_APPLICATION CONSTANT T_PARAMETER.PSECTION%TYPE   := 'APPLICATION';
   PN_RESTRICTED CONSTANT T_PARAMETER.PNAME%TYPE   := 'RESTRICTED_MODE';
   
   ROLE_RESTRICTED CONSTANT VARCHAR2(100)   := 'RESTRICTED_MODE';
   ROLE_SECURITY CONSTANT VARCHAR2(100)   := 'SECURITY';
   ROLE_FINANCE CONSTANT VARCHAR2(100)   := 'FINANCE';
   ROLE_SALES CONSTANT VARCHAR2(100)   := 'SALES';
   ROLE_IT CONSTANT VARCHAR2(100)   := 'IT';


   PV_RESTRICTED CONSTANT T_PARAMETER.PVALUE%TYPE   := 'YES';
   PV_NOT_RESTRICTED CONSTANT T_PARAMETER.PVALUE%TYPE   := 'NO';

   
   FUNCTION F_PARAMETER (I_SECTION IN VARCHAR2, I_NAME IN VARCHAR2) RETURN VARCHAR2; 
   FUNCTION F_RESTRICTED_MODE ( I_CODE OUT INTEGER, I_MESSAGE OUT VARCHAR2 ) RETURN INTEGER;
   FUNCTION F_RESTRICTED_MODE_SWITCH (I_ON IN INTEGER) RETURN INTEGER;
   
   
END CB;
/

/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE BODY CB AS 

FUNCTION F_PARAMETER (I_SECTION IN VARCHAR2, I_NAME IN VARCHAR2) RETURN VARCHAR2
IS /* Получим значение параметра по названию и разделу */
F T_PARAMETER.PVALUE%TYPE ;
BEGIN


SELECT PVALUE INTO F FROM T_PARAMETER WHERE  UPPER(PSECTION) = UPPER(I_SECTION) AND UPPER(PNAME)=UPPER(I_NAME);
RETURN(F);

EXCEPTION 
    WHEN OTHERS THEN
    RETURN('');

END;


FUNCTION F_RESTRICTED_MODE( I_CODE OUT INTEGER, I_MESSAGE OUT VARCHAR2 ) RETURN INTEGER
IS  
/* 
Если включен режим ограничения то функция вернёт значение =1 иначе вернёт значение =0 
Если текущий пользователь включен в роль RESTRICTED_MODE
то такой пользователь имеет иммунитет к ограниченному режиму и для него функция всегда вернёт значение =0
*/
F INTEGER;
BEGIN

F := 0;

    I_CODE := 0;
    I_MESSAGE := CB.C_EMPTY ;
    
IF ( F_PARAMETER(CB.PS_APPLICATION, CB.PN_RESTRICTED) = CB.PV_RESTRICTED) AND ( F_ROLE_MEMBER(CB.ROLE_RESTRICTED) = 0 ) THEN
    F := 1;
    I_CODE := CB.RC_LOGOFF;
    I_MESSAGE := CB.RM_LOGOFF;
END IF;

RETURN(F);

EXCEPTION 
    WHEN OTHERS THEN
    RETURN(0);

END;


FUNCTION F_SAVE_PARAMETER (I_SECTION IN VARCHAR2, I_NAME IN VARCHAR2, I_VALUE IN T_PARAMETER.PVALUE%TYPE) RETURN INTEGER
IS  /* Сохраним значение параметра в таблицу настроек T_PARAMETER */
F INTEGER; X INTEGER;
BEGIN

F := 0;

SELECT COUNT(*) INTO X FROM T_PARAMETER WHERE  UPPER(PSECTION) = UPPER(I_SECTION) AND UPPER(PNAME)=UPPER(I_NAME);

IF X = 1 THEN
    UPDATE T_PARAMETER SET PVALUE = I_VALUE  WHERE  UPPER(PSECTION) = UPPER(I_SECTION) AND UPPER(PNAME)=UPPER(I_NAME);
END IF;

IF X = 0 THEN 
    INSERT INTO T_PARAMETER (PSECTION, PNAME, PVALUE) VALUES (UPPER(I_SECTION), UPPER(I_NAME), I_VALUE);
END IF;

COMMIT;

RETURN(F);

EXCEPTION 
    WHEN OTHERS THEN
    ROLLBACK;
    RETURN(1);

END;


FUNCTION F_RESTRICTED_MODE_SWITCH (I_ON IN INTEGER) RETURN INTEGER
IS 
/* 
Изменение значения параметра "Режим ограничения включен". Если входной параметр =0 то выключаем режим, иначе включаем. 
При этом функция вернёт результат, показывающий текущее состояние параметра "Режим ограничения включен".
Если включен режим ограничения то функция вернёт значение =1 иначе вернёт значение =0.
Если текущий пользователь включен в роль RESTRICTED_MODE
то такой пользователь имеет иммунитет к ограниченному режиму и для него функция всегда вернёт значение =0
*/
F INTEGER; P T_PARAMETER.PVALUE%TYPE;
X_CODE INTEGER; X_MESSAGE VARCHAR2(1000);
BEGIN

F := 1001;

IF I_ON = 0 THEN
    P := CB.PV_NOT_RESTRICTED;
ELSE
    P := CB.PV_RESTRICTED;
END IF;

IF F_SAVE_PARAMETER(CB.PS_APPLICATION, CB.PN_RESTRICTED, P)=0 THEN
    F := F_RESTRICTED_MODE(X_CODE, X_MESSAGE);
END IF;

RETURN(F);

EXCEPTION 
    WHEN OTHERS THEN
    RETURN(2001);

END;


END;
/
