CREATE OR REPLACE VIEW CARD_BACK.V_RETURN_REPORT_ICC AS
SELECT /* 1 строка = 1 КЭО (ICC)  Представление является денормализованной заготовкой для построения отчёта */
    A.ID_RETURN,  
    A.F_ID_USER,
    U.DEF as F_USER,
    A.F_ID_STATUS,
    SF.NAME_STATUS as F_STATUS,
    A.F_DATE,
    A.L_ID_USER,
    A.L_ID_STATUS,
    SL.NAME_STATUS as L_STATUS,
    A.L_DATE,
    B.RANGE_MIN,
    B.RANGE_MAX,
    B.F_BALANCE,
    RM.F_RETURN_MONEY,
    RM.F_CARD_COUNT,
    B.ICC
FROM 
    V_RETURN_FIRST_AND_LAST A
    INNER JOIN V_RANGE_DETAIL_01 B
        ON A.ID_RETURN = B.ID_RETURN
    INNER JOIN T_RETURN_STATUS SF
        ON A.F_ID_STATUS = SF.ID_STATUS
    INNER JOIN T_RETURN_STATUS SL
        ON A.L_ID_STATUS = SL.ID_STATUS
    INNER JOIN XMASTER.XCARD_USER U
        ON A.F_ID_USER = U.USER_ID    
    INNER JOIN V_RETURN_MONEY RM
        ON A.ID_RETURN = RM.ID_RETURN
ORDER BY B.ID_RETURN, B.ICC