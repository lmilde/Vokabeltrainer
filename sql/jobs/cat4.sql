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
