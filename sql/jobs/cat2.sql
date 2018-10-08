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
