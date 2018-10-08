CREATE OR REPLACE PROCEDURE CATEGORY(P_CATEGORY IN NUMBER) AUTHID CURRENT_USER
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
        V_MESSAGE := GETTER.GET_RESSOURCE(1) || V_FIRSTNAME || ',' || CRLF ||
        GETTER.GET_RESSOURCE(2)|| CRLF ||
        GETTER.GET_RESSOURCE(3) || CRLF || CRLF ||
        'BEGIN' || CRLF;
            FOR J IN (SELECT DISTINCT VOC_ID AS V_VOCABULARY_ID FROM V_ALL_VOCABULARY_ENTRIES WHERE CATEGORY = P_CATEGORY AND USER_ID = I.V_USER_ID)
            LOOP
            V_MESSAGE := V_MESSAGE || '/*' || GETTER.GET_VOCABULARY_BY_ID(J.V_VOCABULARY_ID) || ': ' || '*/' || 'ANSWER_VOC(' || J.V_VOCABULARY_ID || ', ' || '''''' || ', ' || I.V_USER_ID || ');' || CRLF;
            END LOOP;
            INSERTS.CREATE_NEW_STATISTIC(P_CATEGORY, ' ', I.V_USER_ID);
        V_MESSAGE := V_MESSAGE || 'END;';
        SEND_MAIL(V_RECIPIENT, V_MESSAGE);
        END LOOP;
    END;
/
