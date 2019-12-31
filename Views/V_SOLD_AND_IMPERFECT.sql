CREATE OR REPLACE VIEW CARD_BACK.V_SOLD_AND_IMPERFECT 
AS /* Дефектные КЭО бывшие до этого в статусе Продана */

SELECT A.XCRD_ID, A.ICC, A.NUM_HISTORY, B.START_DATE, B.END_DATE, A.USER_USER_ID as USER_ID
FROM XMASTER.XCARD A
        INNER JOIN XMASTER.XCARD_HISTORY B
        ON A.XCRD_ID=B.XCRD_XCRD_ID AND A.NUM_HISTORY=B.NUM_HISTORY
                INNER JOIN XMASTER.XCARD_HISTORY C
                ON A.XCRD_ID=C.XCRD_XCRD_ID AND A.NUM_HISTORY=C.NUM_HISTORY+1
                
WHERE 1=1

    AND A.XCST_XCST_ID = 10 /* Текущий статус = Дефектная */  
    AND B.XCST_XCST_ID = 10 /* В принципе это условие можно было и не писать, так как по идее автоматом тут должен быть тот же статус что и у A.XCST_XCST_ID */
    AND C.XCST_XCST_ID = 5  /* Предыдущий статус = Продана */
    
ORDER BY 1;
