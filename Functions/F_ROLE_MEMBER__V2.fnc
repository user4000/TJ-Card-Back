CREATE OR REPLACE FUNCTION F_ROLE_MEMBER(I_ID_ROLE IN VARCHAR2, S_USER_UNIT_TEST IN VARCHAR2 DEFAULT NULL)
   RETURN INTEGER
   IS 
   F INTEGER;
   X INTEGER;
   S_USER VARCHAR2(100);
    /* Если текущий пользователь является членом роли I_ID_ROLE (или роли ADMIN) то функция вернет значение = 1 иначе = 0 */

BEGIN
   
   F := 0;

   IF S_USER_UNIT_TEST IS NULL THEN  ---- Вызов функции был в рабочем режиме
        SELECT SYS_CONTEXT ('USERENV', 'SESSION_USER')  INTO S_USER FROM DUAL;
   ELSE                                             ---- Вызов функции был в тестовом режиме
        S_USER := S_USER_UNIT_TEST;
   END IF;
      
   SELECT 
   COUNT(*) INTO X 
   FROM T_ROLE_MEMBER
   WHERE  
       UPPER(LOGIN) = UPPER(S_USER)
       AND
       (
       UPPER(ID_ROLE) = UPPER(I_ID_ROLE)
       OR
       UPPER(ID_ROLE) = UPPER('ADMIN')
       )
       AND
       IS_ACTIVE > 0;
   
   IF (X > 0) THEN
        F := 1;
   END IF;
   
   RETURN (F);

EXCEPTION 
    WHEN OTHERS THEN 
           RETURN(0);
     
END;
