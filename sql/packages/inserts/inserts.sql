PROCEDURE INSERT_NEW_LANGUAGE (P_LANGUAGE IN VARCHAR);
PROCEDURE INSERT_NEW_UNIT (P_UNIT IN VARCHAR2);
PROCEDURE INSERT_NEW_USER (P_FIRSTNAME IN VARCHAR2, P_LASTNAME IN VARCHAR2, P_EMAIL IN VARCHAR2);
PROCEDURE INSERT_NEW_TRANSLATION (P_TRANSLATION IN VARCHAR2, P_VOCABULARY IN VARCHAR2, P_UNIT IN VARCHAR2, P_LANGUAGE IN VARCHAR);
PROCEDURE INSERT_NEW_VOCABULARY (P_VOCABULARY IN VARCHAR2, P_UNIT IN VARCHAR2, P_LANGUAGE IN VARCHAR2);
PROCEDURE CREATE_NEW_STATISTIC (P_CATEGORY IN NUMBER, P_UNIT IN VARCHAR2, P_USER_ID IN NUMBER);
