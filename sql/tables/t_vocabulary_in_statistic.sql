CREATE TABLE T_VOCABULARY_IN_STATISTIC(
ID NUMBER GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
CORRECT NUMBER,
STATISTIC_ID NUMBER NOT NULL,
VOCABULARY_ID NUMBER NOT NULL,
CONSTRAINT VOCABULARY_IN_STATISTIC_PK PRIMARY KEY(VOCABULARY_ID, STATISTIC_ID),
CONSTRAINT STATISTIC_VOC_FK FOREIGN KEY(STATISTIC_ID) REFERENCES T_STATISTIC (ID),
CONSTRAINT VOCABULARY_STAT_FK FOREIGN KEY (VOCABULARY_ID) REFERENCES T_VOCABULARY(ID)
);