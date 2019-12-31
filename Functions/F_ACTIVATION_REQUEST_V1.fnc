CREATE OR REPLACE FUNCTION F_ACTIVATION_REQUEST RETURN SYS_REFCURSOR
/* 
Данная функция выводит (для JOB-a SLR) список карт, для которых требуется активация.
Эту функцию JOB SLR-a вызывает каждые N секунд.
*/

IS

   F SYS_REFCURSOR;
   U_ID_RETURN INTEGER;
   
BEGIN

    P_CHECK_ACTIVATED_RETURN; ---- Отметим те Заявки, которые уже были завершены успешной активацией ----

    /* Выбираем наименьший ID Заявки  (готовый к активации),  еще не все карты которого активировались */
   SELECT MIN(ID_RETURN) INTO U_ID_RETURN FROM TA_ACTIVATION 
   WHERE 
   /* FLAG_COMMITED IS NULL   and */
            ID_ACTIVATION IN 
           (
           /* Находим наименьший ID активации где КЭО ещё не были в процессе активации */
           SELECT MIN(ID_ACTIVATION) FROM TA_CARD WHERE (R_CODE IS NULL) OR (R_MESSAGE IS NULL) 
           );

   OPEN F FOR
   
        SELECT MSISDN, PIN, ICC, XCRD_ID FROM
        (
            SELECT A.MSISDN, F_GET_PIN(B.ICC) as PIN, B.ICC, B.XCRD_ID 
                FROM TA_ACTIVATION A
                INNER JOIN TA_CARD B
                    ON A.ID_ACTIVATION = B.ID_ACTIVATION
                        WHERE A.ID_RETURN = U_ID_RETURN
                            ORDER BY B.ICC 
        )
        WHERE ROWNUM <= 10; ---- выдаём для SLR не более 10 КЭО за 1 раз ----

   
   
   
   
   FOR one_card in F
   LOOP
   
      UPDATE TA_CARD 
        SET LAST_SELECTED = sysdate 
            WHERE XCRD_ID = one_card.XCRD_ID;
            
   END LOOP;
   
   
   
   
   RETURN F;

EXCEPTION 
    WHEN OTHERS THEN
        NULL;   
   
END;
