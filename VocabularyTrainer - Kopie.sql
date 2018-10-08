----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ DROP TABLES ---------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE T_VOCABULARY_IN_STATISTIC;
DROP TABLE T_TRANSLATION;
DROP TABLE T_VOCABULARY;
DROP TABLE T_UNIT;
DROP TABLE T_STATISTIC;
DROP TABLE T_USERS;
DROP TABLE T_LANGUAGES;
DROP VIEW V_ALL_VOCABULARY_ENTRIES;
DROP VIEW V_VOCABULARY_TO_LEARN;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ CREATE TABLES -------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE T_UNIT(
ID NUMBER GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
NAME VARCHAR(16) NOT NULL,
CONSTRAINT UNIT_PK PRIMARY KEY(ID)
);

CREATE TABLE T_LANGUAGES(
ID NUMBER GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
NAME VARCHAR(5) NOT NULL,
CONSTRAINT LANGUAGES_PK PRIMARY KEY(ID)
);

CREATE TABLE T_VOCABULARY(
ID NUMBER GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
VOCABULARY VARCHAR2(40) NOT NULL,
CATEGORY NUMBER NOT NULL,
COUNTER NUMBER NOT NULL,
TIMESTAMP_LAST_PRACTICE TIMESTAMP,
UNIT_ID NUMBER NOT NULL,
LANGUAGES_ID NUMBER NOT NULL,
CONSTRAINT VOCABULARY_PK PRIMARY KEY(ID),
CONSTRAINT UNIT_FK FOREIGN KEY(UNIT_ID) REFERENCES T_UNIT(ID),
CONSTRAINT LANGUAGES_VOC_FK FOREIGN KEY(LANGUAGES_ID) REFERENCES T_LANGUAGES(ID)
);

CREATE TABLE T_USERS(
ID NUMBER GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
EMAIL VARCHAR2(40) NOT NULL,
FIRSTNAME VARCHAR(16) NOT NULL,
LASTNAME VARCHAR(16) NOT NULL,
CONSTRAINT USERS_PK PRIMARY KEY(ID)
);

CREATE TABLE T_STATISTIC(
ID NUMBER GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
TIMESTAMP_GERNERATED TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP,
TIMESTAMP_PRACTICE_DONE TIMESTAMP(6),
USERS_ID NUMBER NOT NULL,
CONSTRAINT STATISTIC_PK PRIMARY KEY(ID),
CONSTRAINT USERS_FK FOREIGN KEY(USERS_ID) REFERENCES T_USERS(ID)
);

CREATE TABLE T_VOCABULARY_IN_STATISTIC(
ID NUMBER GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
CORRECT NUMBER,
STATISTIC_ID NUMBER NOT NULL,
VOCABULARY_ID NUMBER NOT NULL,
CONSTRAINT VOCABULARY_IN_STATISTIC_PK PRIMARY KEY(VOCABULARY_ID, STATISTIC_ID), 
CONSTRAINT STATISTIC_VOC_FK FOREIGN KEY(STATISTIC_ID) REFERENCES T_STATISTIC (ID),
CONSTRAINT VOCABULARY_STAT_FK FOREIGN KEY (VOCABULARY_ID) REFERENCES T_VOCABULARY(ID)
);

CREATE TABLE T_TRANSLATION(
ID NUMBER GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
TRANSLATION VARCHAR2(40) NOT NULL,
VOCABULARY VARCHAR2(40) NOT NULL,
VOCABULARY_ID NUMBER NOT NULL,
LANGUAGES_ID NUMBER NOT NULL,
CONSTRAINT TRANSLATION_PK PRIMARY KEY(ID),
CONSTRAINT VOCABULARY_FK FOREIGN KEY(VOCABULARY_ID) REFERENCES T_VOCABULARY(ID),
CONSTRAINT LANGUAGES_FK FOREIGN KEY(LANGUAGES_ID) REFERENCES T_LANGUAGES(ID)
);

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ CREATE VIEW ---------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE VIEW V_ALL_VOCABULARY_ENTRIES AS
SELECT U.ID AS UNIT_ID, U.NAME AS UNIT_NAME, V.ID AS VOC_ID, V.VOCABULARY, V.LANGUAGES_ID AS VOC_LANG_ID, VL.NAME AS VOC_LANG, T.ID AS TRA_ID, T.TRANSLATION, T.LANGUAGES_ID AS TRA_LANG_ID, LL.NAME AS TRA_LANG, V.CATEGORY AS CATEGORY
FROM T_VOCABULARY V
INNER JOIN T_TRANSLATION T ON V.ID = T.VOCABULARY_ID 
INNER JOIN T_UNIT U ON V.UNIT_ID = U.ID
INNER JOIN T_LANGUAGES VL ON VL.ID = V.LANGUAGES_ID 
INNER JOIN T_LANGUAGES LL ON LL.ID = T.LANGUAGES_ID;

CREATE VIEW V_VOCABULARY_TO_LEARN AS
SELECT VOCABULARY_ID FROM T_VOCABULARY_IN_STATISTIC WHERE CORRECT IS NULL;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ PROCEDURES ----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE INSERT_NEW_LANGUAGE (P_LANGUAGE IN VARCHAR)
	IS
    BEGIN
		IF NOT LANGUAGE_EXISTS_IN_TABLE(P_LANGUAGE) THEN
			INSERT INTO T_LANGUAGES(NAME) VALUES(P_LANGUAGE);
			COMMIT;
		END IF;
	END; 
/

CREATE OR REPLACE PROCEDURE INSERT_NEW_UNIT (P_UNIT IN VARCHAR2)
    IS
	BEGIN
		IF NOT UNIT_EXISTS_IN_TABLE(P_UNIT) THEN
			INSERT INTO T_UNIT(NAME) VALUES(P_UNIT);
			COMMIT;
		END IF;
	END;
/

CREATE OR REPLACE PROCEDURE INSERT_NEW_USERS (P_USERS_FIRSTNAME IN VARCHAR2, P_USERS_LASTNAME IN VARCHAR2, P_USERS_EMAIL IN VARCHAR2)
    IS
	BEGIN
		IF NOT EMAIL_EXISTS_IN_TABLE(P_USERS_EMAIL) THEN
			INSERT INTO T_USERS(FIRSTNAME, LASTNAME, EMAIL) VALUES(P_USERS_FIRSTNAME, P_USERS_LASTNAME, P_USERS_EMAIL);
			COMMIT;
		END IF;
	END;
/

CREATE OR REPLACE PROCEDURE INSERT_NEW_TRANSLATION (P_TRANSLATION IN VARCHAR2, P_VOCABULARY IN VARCHAR2, P_UNIT IN VARCHAR2, P_LANGUAGE IN VARCHAR)
    IS 
    V_LANGUAGE_ID NUMBER;
    V_VOCABULARY_ID NUMBER;
    BEGIN
        IF NOT TRANSLATION_EXISTS_IN_TABLE(P_TRANSLATION, P_VOCABULARY) THEN
            V_LANGUAGE_ID := GET_LANGUAGES_ID(P_LANGUAGE);
            V_VOCABULARY_ID := GET_VOCABULARY_ID(P_VOCABULARY);
            INSERT INTO T_TRANSLATION(TRANSLATION, LANGUAGES_ID, VOCABULARY_ID, VOCABULARY) VALUES(P_TRANSLATION, V_LANGUAGE_ID, V_VOCABULARY_ID, P_VOCABULARY);
            COMMIT;
        END IF;
    END;
/

CREATE OR REPLACE PROCEDURE INSERT_NEW_VOCABULARY (P_VOCABULARY IN VARCHAR2, P_UNIT IN VARCHAR2, P_LANGUAGE IN VARCHAR)
    IS
    BEGIN 
        IF NOT VOCABULARY_EXISTS_IN_TABLE(P_VOCABULARY) THEN
            INSERT INTO T_VOCABULARY(VOCABULARY, CATEGORY, COUNTER, UNIT_ID, LANGUAGES_ID) VALUES(P_VOCABULARY, 0, 0, GET_UNIT_ID(P_UNIT), GET_LANGUAGES_ID(P_LANGUAGE));
            COMMIT;
        END IF;
    END;
/

CREATE OR REPLACE PROCEDURE CREATE_NEW_STATISTIC (P_CATEGORY IN NUMBER, P_UNIT IN VARCHAR2, P_USER_ID IN NUMBER)
    IS V_STATISTIC_ID NUMBER;
    BEGIN	
--create the statistic itself
        INSERT INTO T_STATISTIC (USERS_ID) VALUES (P_USER_ID);
        COMMIT;

--load variables
        SELECT ID INTO V_STATISTIC_ID FROM T_STATISTIC WHERE ROWID=(SELECT MAX(ROWID) FROM T_STATISTIC);


        FOR	I IN (SELECT DISTINCT MIN(VOC_ID) AS ID FROM V_ALL_VOCABULARY_ENTRIES WHERE (CATEGORY = P_CATEGORY OR P_CATEGORY = -1) AND (UNIT_NAME = P_UNIT OR P_UNIT = ' ') GROUP BY TRANSLATION)
        LOOP
            INSERT INTO T_VOCABULARY_IN_STATISTIC (STATISTIC_ID, VOCABULARY_ID) VALUES (V_STATISTIC_ID, I.ID);	
            COMMIT;
        END LOOP;

    END; 
/

CREATE OR REPLACE PROCEDURE ANSWER (P_VOCABULARY_IN_STATISTIC_ID IN NUMBER, P_ANSWER IN VARCHAR2)
    IS
    V_CORRECT NUMBER;
    V_VOCABULARY_ID NUMBER;
    BEGIN
        SELECT VOCABULARY_ID INTO V_VOCABULARY_ID FROM T_VOCABULARY_IN_STATISTIC WHERE ID = P_VOCABULARY_IN_STATISTIC_ID;
            IF CHECK_ANSWER(V_VOCABULARY_ID, P_ANSWER) THEN
            V_CORRECT := -1; 
            ELSE 
            V_CORRECT := 0;
            END IF;
        UPDATE T_VOCABULARY_IN_STATISTIC SET CORRECT = V_CORRECT WHERE ID = P_VOCABULARY_IN_STATISTIC_ID;
        commit;
    END;
/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ FUNCTIONS -----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------- CHECK IF EXISTS ------------------------------------------------------------------------------------------------------------
  CREATE OR REPLACE FUNCTION LANGUAGE_EXISTS_IN_TABLE (P_LANGUAGE IN VARCHAR)
      RETURN BOOLEAN
      IS V_NUMBER_OF_ROWS_WITH_LANGUAGE NUMBER;
      BEGIN
          SELECT COUNT(*) INTO V_NUMBER_OF_ROWS_WITH_LANGUAGE FROM T_LANGUAGES WHERE NAME = P_LANGUAGE;
          RETURN V_NUMBER_OF_ROWS_WITH_LANGUAGE > 0;
      END;
/

CREATE OR REPLACE FUNCTION UNIT_EXISTS_IN_TABLE (P_UNIT IN VARCHAR2)
    RETURN BOOLEAN
    IS V_NUMBER_OF_ROWS_WITH_UNIT NUMBER;
    BEGIN
        SELECT COUNT(*) INTO V_NUMBER_OF_ROWS_WITH_UNIT FROM T_UNIT WHERE NAME = P_UNIT;
        RETURN V_NUMBER_OF_ROWS_WITH_UNIT > 0;
    END;
/

CREATE OR REPLACE FUNCTION EMAIL_EXISTS_IN_TABLE (P_USERS_EMAIL IN VARCHAR2)
    RETURN BOOLEAN
    IS V_NUMBER_OF_ROWS_WITH_EMAIL NUMBER;
    BEGIN
        SELECT COUNT(*) INTO V_NUMBER_OF_ROWS_WITH_EMAIL FROM T_USERS WHERE EMAIL = P_USERS_EMAIL;
        RETURN V_NUMBER_OF_ROWS_WITH_EMAIL > 0;
    END;
/

CREATE OR REPLACE FUNCTION TRANSLATION_EXISTS_IN_TABLE (P_TRANSLATION IN VARCHAR2, P_VOCABULARY IN VARCHAR2)
    RETURN BOOLEAN
    IS V_NUMBER_OF_ROWS_WITH_TRANSLATION NUMBER;
    BEGIN
        SELECT COUNT(*) INTO V_NUMBER_OF_ROWS_WITH_TRANSLATION FROM T_TRANSLATION WHERE TRANSLATION = P_TRANSLATION;
        RETURN V_NUMBER_OF_ROWS_WITH_TRANSLATION > 0;
    END;
/

CREATE OR REPLACE FUNCTION VOCABULARY_EXISTS_IN_TABLE (P_VOCABULARY IN VARCHAR2)
    RETURN BOOLEAN
    IS V_NUMBER_OF_ROWS_WITH_VOCABULARY NUMBER;
    BEGIN
        SELECT COUNT(*) INTO V_NUMBER_OF_ROWS_WITH_VOCABULARY FROM T_VOCABULARY WHERE VOCABULARY = P_VOCABULARY;
        RETURN V_NUMBER_OF_ROWS_WITH_VOCABULARY > 0;
    END;
/


CREATE OR REPLACE FUNCTION CHECK_ANSWER(P_VOCABULARY_ID IN NUMBER, P_ANSWER IN VARCHAR2)
    RETURN BOOLEAN
    IS V_NUMBER_OF_ROWS_WITH_ANSWER NUMBER;
    BEGIN
        SELECT COUNT(*) INTO V_NUMBER_OF_ROWS_WITH_ANSWER FROM T_TRANSLATION WHERE TRANSLATION = P_ANSWER AND VOCABULARY_ID = P_VOCABULARY_ID;
        RETURN V_NUMBER_OF_ROWS_WITH_ANSWER > 0;
END;
/

----------------------------------------------------------------------------------- GET IDS ------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GET_LANGUAGES_ID (P_LANGUAGE IN VARCHAR)
    RETURN NUMBER
    IS V_LANGUAGE_ID NUMBER;
    BEGIN
        SELECT ID INTO V_LANGUAGE_ID FROM T_LANGUAGES WHERE NAME = P_LANGUAGE;
        RETURN V_LANGUAGE_ID;
    END;
/

CREATE OR REPLACE FUNCTION GET_UNIT_ID (P_UNIT IN VARCHAR2)
    RETURN NUMBER
    IS V_UNIT_ID NUMBER;
    BEGIN
        SELECT ID INTO V_UNIT_ID FROM T_UNIT WHERE NAME = P_UNIT;
        RETURN V_UNIT_ID;
    END;
/

CREATE OR REPLACE FUNCTION GET_VOCABULARY_ID (P_VOCABULARY IN VARCHAR2)
    RETURN NUMBER
    IS V_VOCABULARY_ID NUMBER;
    BEGIN
        SELECT ID INTO V_VOCABULARY_ID FROM T_VOCABULARY WHERE VOCABULARY = P_VOCABULARY;
        RETURN V_VOCABULARY_ID;
    END;
/

----------------------------------------------------------------------------------- GET USER INFORMATION ------------------------------------------------------------------------------------------------------

-- CREATE OR REPLACE FUNCTION GET_USER_EMAIL(P_FIRSTNAME IN VARCHAR2, P_LASTNAME IN VARCHAR2)
--     RETURN VARCHAR2
--     IS
--     V_USER_EMAIL VARCHAR2(40);
--     BEGIN
--         SELECT EMAIL INTO V_USER_EMAIL FROM T_USERS WHERE FIRSTNAME = P_FIRSTNAME AND LASTNAME = P_LASTNAME;
--         RETURN V_USER_EMAIL;
--     END;
-- /


----------------------------------------------------------------------------------- UNSOLVED VOCABULARY --------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION UNSOLVED_VOCABULARY(P_VOCABULARY_IN_STATISTIC_ID IN NUMBER)
    RETURN BOOLEAN
    IS V_NUMBER_OF_ROWS_WITH_ANSWER NUMBER;
    BEGIN
        SELECT COUNT(*) INTO V_NUMBER_OF_ROWS_WITH_ANSWER FROM T_VOCABULARY_IN_STATISTIC WHERE CORRECT IS NULL AND ID = P_VOCABULARY_IN_STATISTIC_ID;
        RETURN V_NUMBER_OF_ROWS_WITH_ANSWER > 0;
    END;
/

CREATE OR REPLACE FUNCTION GET_VOCABULARY_BY_ID(P_VOCABULARY_ID IN NUMBER)
    RETURN VARCHAR2
    IS V_VOCABULARY VARCHAR2(256);
    BEGIN
        SELECT VOCABULARY INTO V_VOCABULARY FROM T_VOCABULARY WHERE ID = P_VOCABULARY_ID;
        RETURN V_VOCABULARY;
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
        'Hallo!'|| CRLF ||	-- Message body
        'Du hast schon lange keine Vokabeln mehr gelernt. Deshalb solltest du das jetzt unbedingt tun.'|| CRLF ||
        'Unten siehst Du die Vokabeln, die Du lernen solltest. :)'|| CRLF ||
        P_MESSAGE
        );
        utl_smtp.QUIT(V_MAIL_CONN);
        EXCEPTION
        WHEN UTL_SMTP.TRANSIENT_ERROR OR UTL_SMTP.PERMANENT_ERROR then
        RAISE_APPLICATION_ERROR(-20000, 'Unable to send mail', TRUE);
    END;
/

CREATE OR REPLACE PROCEDURE SEND_MAILS(P_RECIPIENT IN VARCHAR2)
    IS
    V_MESSAGE VARCHAR2(4096) := '';
    V_VOCABULARY_ID NUMBER;
    V_VOCABULARY_IN_STATISTIC_ID NUMBER;
    CRLF        VARCHAR2(2)  := CHR(13)||CHR(10);
    BEGIN
        V_MESSAGE := 'BEGIN' || CRLF;
        FOR I IN (SELECT VOCABULARY_ID AS ID FROM V_VOCABULARY_TO_LEARN)
        LOOP
             SELECT DISTINCT ID INTO V_VOCABULARY_IN_STATISTIC_ID FROM T_VOCABULARY_IN_STATISTIC WHERE VOCABULARY_ID = I.ID;
             V_MESSAGE := V_MESSAGE || '/*' || GET_VOCABULARY_BY_ID(I.ID) || ': ' || '*/' || 'ANSWER(' ||V_VOCABULARY_IN_STATISTIC_ID || ',' || '''' ||');' || CRLF;
        END LOOP;
        V_MESSAGE := V_MESSAGE || CRLF || 'END;';
        SEND_MAIL(P_RECIPIENT, V_MESSAGE);
    END;
/

CREATE OR REPLACE PROCEDURE SEND_MAIL_TO
    IS
    BEGIN
        SEND_MAILS('lisa.milde@triology.de');
    END;
/


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ JOB -----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

BEGIN
    DBMS_SCHEDULER.DROP_JOB(job_name => 'send_email');
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
    job_name        =>  'send_email',
    job_type        =>  'PLSQL_BLOCK',
    job_action      =>  'SEND_MAIL_TO;',
    start_date      =>  SYSTIMESTAMP,
    enabled         =>  TRUE,
    repeat_interval =>  'FREQ=DAILY; BYHOUR=8;',
    auto_drop       =>  TRUE,
    comments        =>  '');
END;
/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------ TESTS ---------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

BEGIN

INSERT_NEW_LANGUAGE('EN');
INSERT_NEW_LANGUAGE('DE');

INSERT_NEW_UNIT('LEKTION 1');
INSERT_NEW_UNIT('LEKTION 2');

INSERT_NEW_USERS('Lisa', 'Milde', 'lisa.milde@triology.de');

INSERT_NEW_VOCABULARY('to put', 'LEKTION 1', 'EN');
INSERT_NEW_VOCABULARY('to walk', 'LEKTION 1', 'EN');
INSERT_NEW_VOCABULARY('mother', 'LEKTION 1', 'EN');
INSERT_NEW_VOCABULARY('father', 'LEKTION 1', 'EN');
INSERT_NEW_VOCABULARY('pretty', 'LEKTION 1', 'EN');
INSERT_NEW_VOCABULARY('old', 'LEKTION 1', 'EN');
INSERT_NEW_VOCABULARY('to talk', 'LEKTION 1', 'EN');
INSERT_NEW_VOCABULARY('hour', 'LEKTION 1', 'EN');
INSERT_NEW_VOCABULARY('monday', 'LEKTION 1', 'EN');
INSERT_NEW_VOCABULARY('music', 'LEKTION 1', 'EN');

INSERT_NEW_VOCABULARY('setzen, stellen, legen', 'LEKTION 1', 'DE');
INSERT_NEW_VOCABULARY('gehen', 'LEKTION 1', 'DE');
INSERT_NEW_VOCABULARY('Mutter', 'LEKTION 1', 'DE');
INSERT_NEW_VOCABULARY('Vater', 'LEKTION 1', 'DE');
INSERT_NEW_VOCABULARY('huebsch', 'LEKTION 1', 'DE');
INSERT_NEW_VOCABULARY('alt', 'LEKTION 1', 'DE');
INSERT_NEW_VOCABULARY('sprechen', 'LEKTION 1', 'DE');
INSERT_NEW_VOCABULARY('Stunde', 'LEKTION 1', 'DE');
INSERT_NEW_VOCABULARY('Montag', 'LEKTION 1', 'DE');
INSERT_NEW_VOCABULARY('Musik', 'LEKTION 1', 'DE');

INSERT_NEW_TRANSLATION('setzen', 'to put', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('stellen', 'to put', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('legen', 'to put', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('gehen', 'to walk', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('Mutter', 'mother', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('Vater', 'father', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('huebsch', 'pretty', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('alt', 'old', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('sprechen', 'to talk', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('Stunde', 'hour', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('Montag', 'monday', 'LEKTION 1', 'DE');
INSERT_NEW_TRANSLATION('Musik', 'music', 'LEKTION 1', 'DE');

INSERT_NEW_TRANSLATION('to put', 'setzen, stellen, legen', 'LEKTION 1', 'EN');
INSERT_NEW_TRANSLATION('to walk', 'gehen', 'LEKTION 1', 'EN');
INSERT_NEW_TRANSLATION('mother', 'Mutter', 'LEKTION 1', 'EN');
INSERT_NEW_TRANSLATION('father', 'Vater', 'LEKTION 1', 'EN');
INSERT_NEW_TRANSLATION('pretty', 'huebsch', 'LEKTION 1', 'EN');
INSERT_NEW_TRANSLATION('old', 'alt', 'LEKTION 1', 'EN');
INSERT_NEW_TRANSLATION('to talk', 'sprechen', 'LEKTION 1', 'EN');
INSERT_NEW_TRANSLATION('hour', 'Stunde', 'LEKTION 1', 'EN');
INSERT_NEW_TRANSLATION('monday', 'Montag', 'LEKTION 1', 'EN');
INSERT_NEW_TRANSLATION('music', 'Musik', 'LEKTION 1', 'EN');

CREATE_NEW_STATISTIC('0', ' ', '1');

SEND_MAILS('lisa.milde@triology.de');

ANSWER('1', 'setzen');

INSERT_NEW_LANGUAGE('EN');

INSERT_NEW_UNIT('LEKTION 1');

INSERT_NEW_USERS('Lisa', 'Milde', 'lisa.milde@triology.de');

INSERT_NEW_VOCABULARY('to put', 'LEKTION 1', 'EN');

INSERT_NEW_TRANSLATION('stellen', 'to put', '1', 'DE');

END;
