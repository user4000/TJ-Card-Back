CREATE OR REPLACE VIEW CARD_BACK.V_RETURN_FIRST_AND_LAST AS /* Покажем первый и последний статус Заявки на Возврат */
WITH 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
    H_FIRST AS ---- Первый статус и дата ----
    (
    SELECT A.ID_RETURN, A.ID_USER as F_ID_USER, A.ID_STATUS as F_ID_STATUS, A.HISTORY_DATE as F_DATE FROM T_RETURN_HISTORY A
    INNER JOIN 
    ( SELECT ID_RETURN, MIN(ID_HISTORY) as H_MIN FROM T_RETURN_HISTORY GROUP BY ID_RETURN ) B
    ON A.ID_RETURN = B.ID_RETURN AND A.ID_HISTORY=B.H_MIN
    ORDER BY A.ID_RETURN
    ),
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
    H_LAST AS ---- Текущий статус и дата ----
    (
    SELECT A.ID_RETURN, A.ID_USER as L_ID_USER, A.ID_STATUS as L_ID_STATUS, A.HISTORY_DATE as L_DATE FROM T_RETURN_HISTORY A
    INNER JOIN 
    ( SELECT ID_RETURN, MAX(ID_HISTORY) as H_MAX FROM T_RETURN_HISTORY GROUP BY ID_RETURN ) B
    ON A.ID_RETURN = B.ID_RETURN AND A.ID_HISTORY=B.H_MAX
    ORDER BY A.ID_RETURN
    )
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT F.ID_RETURN, F_ID_USER, F_ID_STATUS, F_DATE, L_ID_USER, L_ID_STATUS, L_DATE FROM H_FIRST F
    INNER JOIN H_LAST L
        ON F.ID_RETURN=L.ID_RETURN
    WHERE F_ID_USER NOT IN (SELECT USER_ID FROM T_USER_DEVELOPER)