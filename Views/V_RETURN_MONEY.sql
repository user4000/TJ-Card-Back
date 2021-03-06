CREATE OR REPLACE VIEW CARD_BACK.V_RETURN_MONEY AS 
SELECT /* Сумма по каждому возврату. 1 строка = 1 возврат */
ID_RETURN, 
SUM ( F_CARD ) AS F_CARD_COUNT,
SUM ( F_CARD * F_BALANCE )  AS F_RETURN_MONEY 
FROM V_RETURN_NOMINAL
GROUP BY ID_RETURN
ORDER BY ID_RETURN