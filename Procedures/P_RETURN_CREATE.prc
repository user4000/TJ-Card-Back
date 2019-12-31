
CREATE OR REPLACE PROCEDURE P_RETURN_CREATE
/* 
Процедура принимает на вход список диапазонов ICC. 
Если все диапазоны (и все остальные входные параметры) оказываются валидными, 
то процедура запишет в БД все указанные пользователем данные о Возврате (Заявке на возврат).

При успешном исполнении этой операции процедура вернёт значение O_CODE = 0.
Если операция не была выполнена, процедура вернёт значение O_CODE отличное от нуля.

GRANT EXECUTE ON CARD_BACK.P_RETURN_CREATE TO CARD_BACK_ROLE
*/
 ( 
 I_SET_OF_RANGES IN VARCHAR2, ---- список диапазонов ICC пример '0456888000-0456888002; 0466111002-0466111099; 0488000100-0488002222'
 
 I_ID_SESSION IN VARCHAR2,
 
 I_ID_VISITOR IN INTEGER, ---- ID посетителя
 
 I_SNAME IN VARCHAR2, ---- Фамилия
 I_FNAME IN VARCHAR2, ---- Имя
 I_PNAME IN VARCHAR2, ---- Отчество
 I_PASSPORT IN VARCHAR2, ---- Паспорт
 I_ADDRESS IN VARCHAR2, ---- Адрес
 I_BIRTH_DATE IN DATE, ---- Дата рождения
 I_ID_PAYMENT_TYPE IN INTEGER, ---- Тип платежа 
 
 I_ID_BANK IN INTEGER, ---- ID Банка из справочника
 I_BANK_ACCOUNT IN VARCHAR2, ---- Номер счёта посетителя в указанном банке
 I_PERSON_ACCOUNT IN VARCHAR2, ---- Номер личного счёта к которому привязана карта
 
 I_PHONE IN VARCHAR2, ---- Контактный телефон
 
 O_CODE  OUT  INTEGER, 
 O_MESSAGE OUT VARCHAR2,
 O_REFCURSOR OUT SYS_REFCURSOR
 ) 
 
 IS 
 
C_DELIMITER CHAR;
V_RAW_STRING VARCHAR2(4000); 
X_RANGE VARCHAR2(30);

X_J INTEGER;
X_K INTEGER;
X_L INTEGER;
X_N INTEGER;
X_MIN INTEGER;
X_MAX INTEGER;

S_TEMP VARCHAR2(4000);
X_ID_RETURN INTEGER;
X_ID_VISITOR INTEGER;

X_CODE INTEGER; 
X_MESSAGE VARCHAR2(2000);

V_BANK_ACCOUNT VARCHAR2(100);
V_PERSON_ACCOUNT  VARCHAR2(100);
V_BALANCE INTEGER; 

V_ID_SESSION VARCHAR2(200);


   TYPE Type_String_Range IS TABLE OF VARCHAR2(30) INDEX BY Binary_Integer;  ---- Одномерная строковая коллекция ----
   TYPE Type_Integer_Range IS TABLE OF INTEGER INDEX BY Binary_Integer;          ---- Одномерная числовая коллекция ----
   
   S_RANGE Type_String_Range; 
   A_MIN Type_Integer_Range; 
   A_MAX Type_Integer_Range;
   
BEGIN

  O_CODE := 0; O_MESSAGE := '';
  
---------------------------------------------------------------------------------------------------------------------------------------------------
IF CB.F_RESTRICTED_MODE(O_CODE, O_MESSAGE) != 0 THEN
    RETURN;
END IF;
---------------------------------------------------------------------------------------------------------------------------------------------------


  C_DELIMITER := ';';
  X_J := 0;
  V_RAW_STRING := REPLACE(I_SET_OF_RANGES,' ','');
  S_TEMP := '';
  V_ID_SESSION := TRIM( I_ID_SESSION );
  
  IF CARD_BACK.F_ROLE_MEMBER(CB.ROLE_SALES) != 1 THEN
            O_CODE := 2E4 + 14;
            O_MESSAGE := 'Ошибка! У вас нет разрешения для создания заявки на возврат.' ;
            P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
            RETURN;     
  END IF;
  
  
  
  OPEN O_REFCURSOR FOR   SELECT  DUMMY as ID_SESSION  FROM DUAL  WHERE  1=1;    
  
  P_APPLICATION_LOG(1100, 0,  SUBSTR(V_RAW_STRING, 1, 4000) ,   X_CODE, X_MESSAGE);
  
  -------------------------------------------------------------------------------------------------------------------------------------
  -- Разбор входной строки на множество отдельных диапазонов, то есть строк вида   'xxxxxxxxxx-yyyyyyyyyy'
  -------------------------------------------------------------------------------------------------------------------------------------
  FOR ONE_RANGE IN 
  (
      SELECT REGEXP_SUBSTR (V_RAW_STRING,'[^' || C_DELIMITER || ']+',1, LEVEL)  TXT
      FROM DUAL
      CONNECT BY REGEXP_SUBSTR (V_RAW_STRING,  '[^' || C_DELIMITER || ']+',1, LEVEL) IS NOT NULL
  )
           LOOP
              X_J := X_J + 1; 
              X_RANGE := TRIM(ONE_RANGE.TXT);
              S_RANGE(X_J) := X_RANGE;
              S_TEMP := S_TEMP || X_RANGE;
           END LOOP;
   
 -------------------------------------------------------------------------------------------------------------------------------------
  
   X_N := X_J;  ---- Запомним количество диапазонов ----

   IF (S_TEMP IS NULL) /* OR (X_N < 1) */ THEN
      O_CODE := 2E4 + 2; 
      O_MESSAGE := 'Вы указали некорректные входные данные.';
      P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
      P_APPLICATION_LOG(2001, 0, V_RAW_STRING,          X_CODE, X_MESSAGE);
      RETURN;
   END IF;
   
  -------------------------------------------------------------------------------------------------------------------------------------
  -- Разбор каждого диапазона на отдельные числа  X_MIN и X_MAX
  -------------------------------------------------------------------------------------------------------------------------------------
  
   S_TEMP := '';
  
    FOR X_J IN 1..X_N
    LOOP

             X_MIN  := REGEXP_SUBSTR ( S_RANGE (X_J),   '[^-]+',   1,   1 ); ---- Начальное значение диапазона ICC
             X_MAX := REGEXP_SUBSTR ( S_RANGE (X_J),   '[^-]+',   1,   2 ); ---- Конечное значение диапазона ICC
             
             X_MIN := NVL(X_MIN,0);
             X_MAX := NVL(X_MAX, X_MIN);
             
             IF (X_MIN > X_MAX) OR (X_MIN=0) THEN
                O_CODE := 2E4 + 3;
                O_MESSAGE := 'Диапазон номер ' || X_J || ' указан некорректно ' || S_RANGE (X_J);
                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                RETURN;           
             END IF;
               
             A_MIN(X_J) := X_MIN; 
             A_MAX(X_J) := X_MAX;
             
             S_TEMP := S_TEMP || F_RANGE(A_MIN(X_J), A_MAX(X_J) ) || '; ' ;
             
             P_RANGE_INTERSECTION(X_MIN, X_MAX, X_CODE, X_MESSAGE); ---- Проверим на пересечение с уже имеющимися в БД диапазонами ----
             
             IF X_CODE > 0 THEN
             
                    O_CODE := 2E4 + 11;
                    O_MESSAGE := 'Ошибка! ' || X_MESSAGE;
                    P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                    RETURN;  
                    
             END IF;
             
    END LOOP;

    P_APPLICATION_LOG(500, 0,  'Разбор диапазонов: ' || S_TEMP,   X_CODE, X_MESSAGE);
   
   -------------------------------------------------------------------------------------------------------------------------------------
   -- Проверим (указанные во входном аргументе) диапазоны на попарные пересечения.
   -------------------------------------------------------------------------------------------------------------------------------------
   
    FOR X_J IN 1..(X_N-1) ---- Вложенный цикл для проверки попарного пересечения диапазонов ----
    LOOP
    
                X_K := X_J+1;
    
                FOR X_L IN X_K..(X_N)
                LOOP
                            
                            X_CODE := F_INTERSECTION(A_MIN(X_J) , A_MAX(X_J) , A_MIN(X_L), A_MAX(X_L) );
                                        
                            IF X_CODE > 0 THEN
                                O_CODE := 2E4 + 4;
                                O_MESSAGE := 'Ошибка! Диапазон = ' || F_RANGE(A_MIN(X_J), A_MAX(X_J) ) || ' пересекается с диапазоном = ' || F_RANGE(A_MIN(X_L), A_MAX(X_L) ) ;
                                P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,   X_CODE, X_MESSAGE);
                                RETURN;                     
                            END IF;
                            
                ----DBMS_OUTPUT.PUT_LINE( A_MIN(X_J) || '-' || A_MAX(X_J) || ' *** ' || A_MIN(X_L) || '-' || A_MAX(X_L)  );
                            
                END LOOP;
                            
    END LOOP;
   

   -------------------------------------------------------------------------------------------------------------------------------------
   -- Создадим новый объект "Посетитель"
   -------------------------------------------------------------------------------------------------------------------------------------
      
   SELECT COUNT(*) INTO X_ID_VISITOR FROM  T_VISITOR WHERE ID_VISITOR = I_ID_VISITOR; 
   
   IF X_ID_VISITOR = 1 THEN ---- Если задан ID существующего посетителя, то создавать его не нужно
   
           X_ID_VISITOR := I_ID_VISITOR;
   
   ELSE
   
           INSERT INTO T_VISITOR (SNAME, FNAME, PNAME, PASSPORT, ADDRESS, BIRTH_DATE, PHONE)
           VALUES 
           (
             I_SNAME ,
             I_FNAME ,
             I_PNAME ,
             I_PASSPORT ,
             I_ADDRESS ,
             I_BIRTH_DATE,
             I_PHONE
           )
           RETURNING ID_VISITOR INTO X_ID_VISITOR;
           
           S_TEMP := 'Создан новый объект "Посетитель" ID_VISITOR = ' || X_ID_VISITOR || '; ' || I_SNAME || ' ' || I_FNAME || ' '  || I_PNAME || '; ' || I_PASSPORT || '; ' || I_ADDRESS || '; ' || I_PHONE; 
           P_APPLICATION_LOG(700, 0,  S_TEMP,   X_CODE, X_MESSAGE);
     
   END IF; 
   
   -------------------------------------------------------------------------------------------------------------------------------------
   -- Дополнительные проверки банка
   -------------------------------------------------------------------------------------------------------------------------------------
   
  V_BANK_ACCOUNT := TRIM ( NVL(I_BANK_ACCOUNT, '?') ); 
  V_PERSON_ACCOUNT :=  TRIM ( I_PERSON_ACCOUNT ); 
  
  IF ( NVL(LENGTH( V_BANK_ACCOUNT) , 0) != CB.C_BANK_ACCOUNT_LENGTH ) AND ( I_ID_PAYMENT_TYPE=1 ) THEN
      O_CODE := 2E4 + 5; 
      O_MESSAGE := 'Ошибка! Вы указали некорректный номер счёта = ' || V_BANK_ACCOUNT;
      P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
      ROLLBACK;
      RETURN;
  END IF;
  
    IF (I_ID_BANK = 0) AND (I_ID_PAYMENT_TYPE=1) THEN
      O_CODE := 2E4 + 6; 
      O_MESSAGE := 'Ошибка! Вы указали некорректный код банка = ' || I_ID_BANK;
      P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
      ROLLBACK;
      RETURN;
  END IF;
  
   -------------------------------------------------------------------------------------------------------------------------------------
   -- Создадим новый объект "Возврат карт"
   -------------------------------------------------------------------------------------------------------------------------------------

  INSERT INTO CARD_BACK.T_RETURN 
  (
      ID_VISITOR,
      ID_BANK,
      BANK_ACCOUNT,
      PERSON_ACCOUNT,
      ID_STATUS,
      ID_PAYMENT_TYPE 
  ) 
  VALUES 
  ( 
      X_ID_VISITOR,
      I_ID_BANK,
      V_BANK_ACCOUNT,
      V_PERSON_ACCOUNT,
      CB.ST_START, ---- Заявка принята ----
      I_ID_PAYMENT_TYPE
  ) 
  RETURNING ID_RETURN INTO X_ID_RETURN;
  
  
  
  P_RETURN_INTERSECTION(X_ID_RETURN, X_CODE, X_MESSAGE);
  
  IF X_CODE != 0 THEN
  
            O_CODE := 2E4 + X_CODE * 2 + 55; 
            O_MESSAGE := X_MESSAGE;
            P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
            ROLLBACK;
            RETURN;  
             
  END IF;
  
  
  P_APPLICATION_LOG(1200, 0, 'Создан новый объект "Возврат" ID_RETURN = ' || X_ID_RETURN ,  X_CODE, X_MESSAGE);
  
  P_RETURN_SAVE_HISTORY(X_ID_RETURN, X_CODE); ---- Сохраним историю создания нового объекта ----
  
   ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   ---- Заполним таблицу "Диапазоны данного возврата T_RETURN_RANGE" - т.е. для каждого возвращённого диапазона создаётся отдельная строка ----
   ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
    FOR X_J IN 1..X_N 
    LOOP
   
        V_BALANCE := F_GET_CARD_BALANCE(A_MIN(X_J));
        
        IF V_BALANCE < 1 THEN        
            O_CODE := 2E4 + 7; 
            O_MESSAGE := 'Произошла ошибка! Номинал карты с ICC = ' || LPAD(A_MIN(X_J),10,'0') || ' является некорректным!' ;
            P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
            ROLLBACK;
            RETURN;       
        END IF;
        
   
        INSERT INTO CARD_BACK.T_RETURN_RANGE (ID_RETURN,        RANGE_MIN,   RANGE_MAX,   F_BALANCE)
                                                                VALUES (X_ID_RETURN,     A_MIN(X_J),   A_MAX(X_J),   V_BALANCE);
       
   END LOOP;
   ------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
   
   
   
   
   
   
------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
 ---- Дополнительный контроль правильности введённых пользователем диапазонов ----  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
   
  P_RANGE_REVISION ( V_ID_SESSION ,  X_ID_RETURN ,  X_CODE  , X_MESSAGE );
  
  DELETE FROM TB_RANGE           WHERE CODE_SESSION = (SELECT CODE_SESSION FROM TB_SESSION WHERE ID_SESSION = V_ID_SESSION);
  
  DELETE FROM TB_RANGE_DRAFT WHERE CODE_SESSION = (SELECT CODE_SESSION FROM TB_SESSION WHERE ID_SESSION = V_ID_SESSION);

  IF X_CODE = 0 THEN
            NULL;
  ELSE
            
            O_CODE := 2E4 + 12; 
            O_MESSAGE := X_MESSAGE;
            P_APPLICATION_LOG(2001, O_CODE, O_MESSAGE,    X_CODE, X_MESSAGE);
            ROLLBACK;
            RETURN;  
            NULL;             

  END IF;
   
   
  O_MESSAGE := 'Операция завершена успешно. Создана новая << Заявка на возврат >> номер ' || X_ID_RETURN;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
  COMMIT;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   

  OPEN O_REFCURSOR FOR   SELECT  X_ID_RETURN as ID_RETURN  FROM DUAL  WHERE  1=1;    




EXCEPTION 

        WHEN DUP_VAL_ON_INDEX THEN
            BEGIN           
                 O_CODE := 20990;
                 O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
                 O_MESSAGE := 'Ошибка! Указанные вами карты уже были задействованы в процессе возврата. ' || LPAD(A_MIN(X_J),10,'0') || ' - ' || LPAD(A_MAX(X_J),10,'0') ;
                 ROLLBACK;            
            END;
            
        WHEN OTHERS THEN
            BEGIN           
                 O_CODE := 20991;
                 O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);
                 ROLLBACK;            
            END;
END;
/
