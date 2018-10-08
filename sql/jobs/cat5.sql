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
