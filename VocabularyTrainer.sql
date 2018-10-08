
CREATE OR REPLACE FUNCTION CORRECT_IS_NULL
    RETURN BOOLEAN
    IS V_NUMBER_OF_ROWS_WITH_CORRECT NUMBER;
    BEGIN
        SELECT COUNT(*) INTO V_NUMBER_OF_ROWS_WITH_CORRECT FROM T_VOCABULARY_IN_STATISTIC WHERE CORRECT IS NULL;
        RETURN V_NUMBER_OF_ROWS_WITH_CORRECT > 0; 
    END;
/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ ANSWER --------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CHECK_ANSWER(P_VOCABULARY_ID IN NUMBER, P_ANSWER IN VARCHAR2)
    RETURN BOOLEAN
    IS V_NUMBER_OF_ROWS_WITH_ANSWER NUMBER;
    BEGIN
        SELECT COUNT(*) INTO V_NUMBER_OF_ROWS_WITH_ANSWER FROM T_TRANSLATION WHERE TRANSLATION = P_ANSWER AND VOCABULARY_ID = P_VOCABULARY_ID;
        RETURN V_NUMBER_OF_ROWS_WITH_ANSWER > 0;
END;
/

CREATE OR REPLACE PROCEDURE ANSWER (P_VOCABULARY_ID IN NUMBER, P_ANSWER IN VARCHAR2, P_USER_ID IN NUMBER)
    IS
    V_CORRECT NUMBER;
    V_VOCABULARY_ID NUMBER;
    V_MESSAGE VARCHAR2(256);
    CRLF        VARCHAR2(2)  := CHR(13)||CHR(10);
    BEGIN
            IF CHECK_ANSWER(P_VOCABULARY_ID, P_ANSWER) THEN
            V_CORRECT := -1;
            V_MESSAGE := GET_RESSOURCE(4) || '''' || GET_VOCABULARY_BY_ID(P_VOCABULARY_ID) || '''' || GET_RESSOURCE(5) || CRLF ||
                         GET_RESSOURCE(7) || P_ANSWER || CRLF;
            DBMS_OUTPUT.PUT_LINE(V_MESSAGE);

            ELSE 
            V_CORRECT := 0;
            V_MESSAGE := GET_RESSOURCE(4) || '''' || GET_VOCABULARY_BY_ID(P_VOCABULARY_ID) || '''' ||GET_RESSOURCE(6) || '''' || GET_TRANSLATION_BY_VOCABULARY_ID(P_VOCABULARY_ID) || '''' || CRLF ||
                         GET_RESSOURCE(7) || P_ANSWER || CRLF;
            DBMS_OUTPUT.PUT_LINE(V_MESSAGE);
            END IF;
        UPDATE T_VOCABULARY_IN_STATISTIC SET CORRECT = V_CORRECT WHERE VOCABULARY_ID = P_VOCABULARY_ID;
        INSERT_COUNTER_AND_CATEGORY(P_USER_ID, P_VOCABULARY_ID, V_CORRECT);
    COMMIT;
    SET_TIMESTAMP_DONE();
    END;
/

CREATE OR REPLACE PROCEDURE INSERT_COUNTER_AND_CATEGORY(P_USER_ID IN NUMBER, P_VOCABULARY_ID IN NUMBER, P_CORRECT IN NUMBER)
    IS
    BEGIN
        MERGE INTO T_VOCABULARY_IN_USER DEST USING (SELECT P_USER_ID AS USER_ID, P_VOCABULARY_ID AS VOCABULARY_ID FROM DUAL) SRC ON (SRC.USER_ID=DEST.USER_ID AND SRC.VOCABULARY_ID=DEST.VOCABULARY_ID)
        WHEN MATCHED THEN
            UPDATE SET 
            TIMESTAMP_LAST_PRACTICE = CURRENT_TIMESTAMP,
            CATEGORY = CASE 
                        WHEN(P_CORRECT=-1 AND CATEGORY < 5 AND COUNTER = 5)
                        THEN (CATEGORY + 1)
                        ELSE CATEGORY
                        END,
            COUNTER = CASE
                        WHEN ((P_CORRECT = 0 AND COUNTER = 0 ) OR (P_CORRECT = -1 AND COUNTER = 5))
                        THEN 0
                        ELSE(COUNTER+1)
                        END
            WHERE USER_ID = P_USER_ID AND VOCABULARY_ID = P_VOCABULARY_ID
        WHEN NOT MATCHED THEN
        INSERT (USER_ID, VOCABULARY_ID, CATEGORY, COUNTER)
        VALUES (P_USER_ID, P_VOCABULARY_ID, 0, CASE
                                                WHEN (P_CORRECT = -1) THEN 1
                                                ELSE 0
                                                END);
        COMMIT;
    END;
/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ SEND EMAIL ----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE SEND_MAIL (P_RECIPIENT IN VARCHAR2, P_MESSAGE IN VARCHAR2)
    IS 
    V_FROM      VARCHAR2(80) := 'trainer.vocabeln@lernedies.com';
    V_RECIPIENT VARCHAR2(80) := P_RECIPIENT;
    V_SUBJECT   VARCHAR2(80) := 'Vokabeln lernen';
    V_MAIL_HOST VARCHAR2(30) := 'mail.triology.de';
    V_MAIL_CONN UTL_SMTP.CONNECTION;

    CRLF        VARCHAR2(2)  := CHR(13)||CHR(10);
    BEGIN
        V_MAIL_CONN := UTL_SMTP.OPEN_CONNECTION(V_MAIL_HOST, 25);
        UTL_SMTP.HELO(V_MAIL_CONN, V_MAIL_HOST);
        UTL_SMTP.MAIL(V_MAIL_CONN, V_FROM);
        UTL_SMTP.RCPT(V_MAIL_CONN, V_RECIPIENT);
        UTL_SMTP.DATA(V_MAIL_CONN,
        'Date: '   || TO_CHAR(sysdate, 'Dy, DD Mon YYYY hh24:mi:ss') || CRLF ||
        'From: '   || V_FROM || CRLF ||
        'Subject: '|| V_SUBJECT || CRLF ||
        'To: '     || V_RECIPIENT || CRLF ||
        CRLF ||
        P_MESSAGE
        );
        utl_smtp.QUIT(V_MAIL_CONN);
        EXCEPTION
        WHEN UTL_SMTP.TRANSIENT_ERROR OR UTL_SMTP.PERMANENT_ERROR then
        RAISE_APPLICATION_ERROR(-20000, 'Unable to send mail', TRUE);
    END;
/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ CATEGORIES ----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


CREATE OR REPLACE PROCEDURE CATEGORY(P_CATEGORY IN NUMBER) 
    IS
    V_MESSAGE VARCHAR2(8192) := ' ';
    CRLF        VARCHAR2(2)  := CHR(13)||CHR(10);
    V_USER_ID NUMBER;
    V_FIRSTNAME VARCHAR2(16);
    V_RECIPIENT VARCHAR2(256);
    BEGIN
    FOR I IN (SELECT DISTINCT USER_ID AS V_USER_ID FROM V_ALL_VOCABULARY_ENTRIES)
    LOOP
    SELECT FIRSTNAME INTO V_FIRSTNAME FROM T_USER WHERE ID = I.V_USER_ID;
    SELECT EMAIL INTO V_RECIPIENT FROM T_USER WHERE ID = I.V_USER_ID;
        V_MESSAGE := GET_RESSOURCE(1) || V_FIRSTNAME || ',' || CRLF ||
        GET_RESSOURCE(2)|| CRLF ||
        GET_RESSOURCE(3) || CRLF || CRLF ||
        'BEGIN' || CRLF;
            FOR J IN (SELECT DISTINCT VOC_ID AS V_VOCABULARY_ID FROM V_ALL_VOCABULARY_ENTRIES WHERE CATEGORY = P_CATEGORY AND USER_ID = I.V_USER_ID)
            LOOP
            V_MESSAGE := V_MESSAGE || '/*' || GET_VOCABULARY_BY_ID(J.V_VOCABULARY_ID) || ': ' || '*/' || 'ANSWER(' || J.V_VOCABULARY_ID || ', ' || '''''' || ', ' || I.V_USER_ID || ');' || CRLF;
            END LOOP;
            CREATE_NEW_STATISTIC(P_CATEGORY, ' ', I.V_USER_ID);
        V_MESSAGE := V_MESSAGE || 'END;';
        SEND_MAIL(V_RECIPIENT, V_MESSAGE);
        END LOOP;
    END;
/

CREATE OR REPLACE PROCEDURE SET_TIMESTAMP_DONE
    IS
    BEGIN
        FOR I IN (SELECT ID AS V_STATISTIC_ID FROM T_STATISTIC)
        LOOP
   		UPDATE T_STATISTIC SET TIMESTAMP_PRACTICE_DONE = CURRENT_TIMESTAMP WHERE ID = I.V_STATISTIC_ID 
           AND NOT EXISTS (SELECT COUNT(*) FROM T_VOCABULARY_IN_STATISTIC WHERE STATISTIC_ID = I.V_STATISTIC_ID GROUP BY CORRECT HAVING CORRECT IS NULL);
        COMMIT;
        END LOOP;
    END;
/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ JOBS ----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

BEGIN
    DBMS_SCHEDULER.DROP_JOB(job_name => 'CAT0');
    DBMS_SCHEDULER.DROP_JOB(job_name => 'CAT1');
    DBMS_SCHEDULER.DROP_JOB(job_name => 'CAT2');
    DBMS_SCHEDULER.DROP_JOB(job_name => 'CAT3');
    DBMS_SCHEDULER.DROP_JOB(job_name => 'CAT4');
    DBMS_SCHEDULER.DROP_JOB(job_name => 'CAT5');
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
    job_name        =>  'CAT0',
    job_type        =>  'PLSQL_BLOCK',
    job_action      =>  'CATEGORY(0);',
    start_date      =>  SYSTIMESTAMP,
    enabled         =>  TRUE,
    repeat_interval =>  'FREQ=DAILY; BYHOUR=8;',
    auto_drop       =>  TRUE,
    comments        =>  '');
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
    job_name        =>  'CAT1',
    job_type        =>  'PLSQL_BLOCK',
    job_action      =>  'CATEGORY(1);',
    start_date      =>  SYSTIMESTAMP,
    enabled         =>  TRUE,
    repeat_interval =>  'FREQ=DAILY; INTERVAL=2',
    auto_drop       =>  TRUE,
    comments        =>  '');
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
    job_name        =>  'CAT2',
    job_type        =>  'PLSQL_BLOCK',
    job_action      =>  'CATEGORY(2);',
    start_date      =>  SYSTIMESTAMP,
    enabled         =>  TRUE,
    repeat_interval =>  'FREQ=DAILY; INTERVAL=3;',
    auto_drop       =>  TRUE,
    comments        =>  '');
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
    job_name        =>  'CAT3',
    job_type        =>  'PLSQL_BLOCK',
    job_action      =>  'CATEGORY(3);',
    start_date      =>  SYSTIMESTAMP,
    enabled         =>  TRUE,
    repeat_interval =>  'FREQ=DAILY; INTERVAL=4;',
    auto_drop       =>  TRUE,
    comments        =>  '');
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
    job_name        =>  'CAT4',
    job_type        =>  'PLSQL_BLOCK',
    job_action      =>  'CATEGORY(4);',
    start_date      =>  SYSTIMESTAMP,
    enabled         =>  TRUE,
    repeat_interval =>  'FREQ=DAILY; INTERVAL=5;',
    auto_drop       =>  TRUE,
    comments        =>  '');
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
    job_name        =>  'CAT5',
    job_type        =>  'PLSQL_BLOCK',
    job_action      =>  'CATEGORY(5);',
    start_date      =>  SYSTIMESTAMP,
    enabled         =>  TRUE,
    repeat_interval =>  'FREQ=DAILY; INTERVAL=6;',
    auto_drop       =>  TRUE,
    comments        =>  '');
END;
/
