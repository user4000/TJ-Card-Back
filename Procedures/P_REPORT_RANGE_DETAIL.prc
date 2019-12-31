CREATE OR REPLACE PROCEDURE CARD_BACK.P_REPORT_RANGE_DETAIL /*  */
 ( 
 I_LEVEL IN INTEGER, ---- Уровень детализации отчёта - целое число от 1 до 4 ----
 D_START IN DATE, ---- Дата начала периода ----
 D_END IN DATE, ---- Дата окончания периода  ----
 O_CODE  OUT  INTEGER,
 O_MESSAGE OUT VARCHAR2,
 O_REFCURSOR OUT SYS_REFCURSOR ---- Выдаем на выходе требуемый клиентским приложением набор строк ----
 ) IS  
 
 S_PERIOD VARCHAR2(100);
 S_FORMAT_DATE VARCHAR2(10);
  S_FORMAT_NUM VARCHAR2(10);
 
 BEGIN 
 
  O_CODE := 0; O_MESSAGE := ''; 
  S_FORMAT_DATE := 'YYYY/MM/DD';
  S_FORMAT_NUM := '0000000000';
  S_PERIOD := TO_CHAR(D_START, S_FORMAT_DATE) || ' - ' || TO_CHAR(D_END, S_FORMAT_DATE);
 
  OPEN O_REFCURSOR FOR
  WITH T_DATA AS (SELECT * FROM V_RETURN_REPORT_ICC WHERE TRUNC(F_DATE) BETWEEN D_START AND D_END)

--SELECT OBJECT_LEVEL, RANK, C_INFO, C_COUNT, C_BALANCE, C_SUM FROM
--SELECT null as OBJECT_LEVEL1, null as RANK1, C_INFO, C_COUNT, C_BALANCE, C_SUM FROM
SELECT C_INFO, C_COUNT, C_BALANCE, C_SUM FROM
(

    SELECT
    1 AS OBJECT_LEVEL,
    TO_CHAR(0, S_FORMAT_NUM) AS RANK,
    'Всего Заявок (возвратов) за период ' || S_PERIOD  AS C_INFO,
    SUM(1) AS C_COUNT,
    NULL AS C_BALANCE,
    SUM(F_RETURN_MONEY) AS C_SUM,
    NULL AS F_DATE,
    NULL AS L_DATE
    FROM
    (
    SELECT DISTINCT
        ID_RETURN,
        F_USER,
        F_STATUS,
        F_DATE,
        L_STATUS,
        L_DATE,
        F_CARD_COUNT,
        F_RETURN_MONEY
    FROM
        T_DATA 
    ORDER BY 
        ID_RETURN
    ) L1
    UNION --------------------------------------------------------------------------------------------
    SELECT
    2 AS OBJECT_LEVEL,
    TO_CHAR(ID_RETURN, S_FORMAT_NUM) || '-'  AS RANK,
    '№ ' || ID_RETURN || ' ' || F_STATUS || ' ' || TO_CHAR(F_DATE, S_FORMAT_DATE)  || ' ' || F_USER  || ' (' || L_STATUS  || ')'   AS C_INFO,
    F_CARD_COUNT AS C_COUNT,
    NULL AS C_BALANCE,
    F_RETURN_MONEY AS C_SUM,
    F_DATE,
    L_DATE
    FROM
    (
    SELECT DISTINCT
        ID_RETURN,
        F_USER,
        F_STATUS,
        F_DATE,
        L_STATUS,
        L_DATE,
        F_CARD_COUNT,
        F_RETURN_MONEY
    FROM
        T_DATA
     WHERE I_LEVEL >= 2    
    ORDER BY 
        ID_RETURN
    ) L2
    UNION -----------------------------------------------------------------------------------------------
    SELECT
    3 AS OBJECT_LEVEL,
    TO_CHAR(ID_RETURN, S_FORMAT_NUM) || '-' || TO_CHAR(F_BALANCE,'000') || '-' || TO_CHAR(RANGE_MIN,S_FORMAT_NUM)  AS RANK,
    'Диапазон ' || F_RANGE(RANGE_MIN, RANGE_MAX) AS C_INFO,
    RANGE_MAX - RANGE_MIN + 1 AS C_COUNT,
    F_BALANCE AS C_BALANCE,
    (RANGE_MAX - RANGE_MIN + 1) * F_BALANCE AS C_SUM,
    F_DATE,
    L_DATE
    FROM
    (
    SELECT DISTINCT
        ID_RETURN,
        RANGE_MIN,
        RANGE_MAX,
        F_BALANCE,
        F_DATE,
        L_DATE
    FROM
        T_DATA
    WHERE I_LEVEL >= 3    
    ORDER BY 
        ID_RETURN
    ) L3
    UNION -----------------------------------------------------------------------------------------------
    SELECT
    4 AS OBJECT_LEVEL,
    TO_CHAR(ID_RETURN, S_FORMAT_NUM) || '-' || TO_CHAR(F_BALANCE,'000') || '-' ||  TO_CHAR(ICC, S_FORMAT_NUM) || '-ICC' AS RANK,
    'ICC = ' || TO_CHAR(ICC, S_FORMAT_NUM)  AS C_INFO,
    1 AS C_COUNT,
    F_BALANCE AS C_BALANCE,
    F_BALANCE AS C_SUM,
    F_DATE,
    L_DATE
    FROM
    (
    SELECT DISTINCT
        ID_RETURN,
        ICC,
        F_BALANCE,
        F_DATE,
        L_DATE 
    FROM
        T_DATA 
    WHERE I_LEVEL >= 4   
    ORDER BY 
        ID_RETURN
    ) L4
) R1
ORDER BY RANK;
   
EXCEPTION 
        WHEN OTHERS THEN
                 O_CODE := 1;
                 O_MESSAGE := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 4000);   

END;