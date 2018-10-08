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
