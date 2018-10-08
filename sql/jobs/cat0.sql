BEGIN
DBMS_SCHEDULER.CREATE_JOB (
    job_name        =>  'CAT0',
    job_type        =>  'PLSQL_BLOCK',
    job_action      =>  'CATEGORY(0);',
    start_date      =>  SYSTIMESTAMP,
    enabled         =>  TRUE,
    repeat_interval =>  'FREQ=DAILY; BYHOUR=8;',
    auto_drop       =>  TRUE,
    comments        =>  '');
END;
/
