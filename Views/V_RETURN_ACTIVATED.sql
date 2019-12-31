CREATE OR REPLACE VIEW V_RETURN_ACTIVATED AS
/* Сравним количество карт в Заявке и количество активированных карт */
SELECT A.*, B.C_TOTAL FROM
    (
    SELECT 
    ID_RETURN, 
    SUM( COUNT_ACTIVATED ) as C_ACTIVATED
    FROM
    V_ACTIVATION
    GROUP BY ID_RETURN
    ) A
INNER JOIN
    (
    SELECT ID_RETURN, SUM(1+RANGE_MAX - RANGE_MIN) as C_TOTAL
    FROM T_RETURN_RANGE
    GROUP BY ID_RETURN
    ) B
ON A.ID_RETURN=B.ID_RETURN
ORDER BY A.ID_RETURN