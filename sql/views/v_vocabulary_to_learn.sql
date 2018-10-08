CREATE VIEW V_VOCABULARY_TO_LEARN AS
SELECT VOCABULARY_ID, S.USER_ID AS USER_ID, U.EMAIL AS EMAIL
FROM T_VOCABULARY_IN_STATISTIC VS
INNER JOIN T_STATISTIC S ON VS.STATISTIC_ID = S.ID
INNER JOIN T_USER U ON U.ID = S.USER_ID
WHERE CORRECT IS NULL; 
