CREATE OR REPLACE VIEW V_RETURN_NOMINAL AS 
SELECT ID_RETURN, SUM(F_COUNT_OF_CARD) as F_CARD, F_BALANCE FROM
(
SELECT ID_RETURN, (1+RANGE_MAX-RANGE_MIN) as F_COUNT_OF_CARD, F_BALANCE FROM T_RETURN_RANGE
)
GROUP BY ID_RETURN, F_BALANCE
ORDER BY 1,3