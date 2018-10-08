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
