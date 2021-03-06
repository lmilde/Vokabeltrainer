CREATE TABLE T_VOCABULARY(
ID NUMBER GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
VOCABULARY VARCHAR2(256) NOT NULL,
UNIT_ID NUMBER NOT NULL,
LANGUAGE_ID NUMBER NOT NULL,
CONSTRAINT VOCABULARY_PK PRIMARY KEY(ID),
CONSTRAINT UNIT_FK FOREIGN KEY(UNIT_ID) REFERENCES T_UNIT(ID),
CONSTRAINT LANGUAGE_VOC_FK FOREIGN KEY(LANGUAGE_ID) REFERENCES T_LANGUAGE(ID)
);
