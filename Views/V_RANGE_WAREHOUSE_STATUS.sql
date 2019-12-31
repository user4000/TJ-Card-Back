CREATE OR REPLACE VIEW CARD_BACK.V_RANGE_WAREHOUSE_STATUS AS

select A.N_RANGE, A.ICC_START, A.ICC_END, A.N_COUNT, B.DEF as STATUS_NAME, A.XCST_ID as STATUS_ID 
from TD_RANGE_WAREHOUSE_STATUS A
LEFT JOIN XMASTER.XCARD_STATUS B
ON A.XCST_ID=B.XCST_ID
ORDER BY A.ICC_START, A.XCST_ID
