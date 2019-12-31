CREATE OR REPLACE FUNCTION  F_STATUS_LIST(I_ID_RETURN IN INTEGER) RETURN SYS_REFCURSOR
AS /* Функция возвращает статусы, в которые может перейти данная Заявка о Возврате */

        V_ID_STATUS INTEGER;
        V_ID_PAYMENT_TYPE INTEGER;
        F SYS_REFCURSOR;

BEGIN

    SELECT 
        ID_STATUS,
        ID_PAYMENT_TYPE
    INTO
        V_ID_STATUS,
        V_ID_PAYMENT_TYPE   
    FROM T_RETURN 
    WHERE ID_RETURN = I_ID_RETURN;
 
      OPEN F FOR
        SELECT S.ID_STATUS, S.NAME_STATUS
            FROM T_RETURN_STATUS S
                WHERE ID_STATUS IN ( SELECT NEW_STATUS FROM T_STATUS_CHANGE WHERE OLD_STATUS = V_ID_STATUS )
                    ORDER BY 1,2; 
                      
    RETURN F;
    
END;