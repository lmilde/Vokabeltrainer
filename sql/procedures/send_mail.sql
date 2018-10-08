CREATE OR REPLACE PROCEDURE SEND_MAIL (P_RECIPIENT IN VARCHAR2, P_MESSAGE IN VARCHAR2) AUTHID CURRENT_USER
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
