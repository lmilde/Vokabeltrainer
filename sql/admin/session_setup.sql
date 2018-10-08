-- change behavior of pl/sql compiler, optimization level, pl/scope and warnings
alter session set PLSQL_OPTIMIZE_LEVEL=3;

begin
  if (sys.dbms_db_version.version <= 11) or
     ((sys.dbms_db_version.version = 12) and (sys.dbms_db_version.release <= 1)) then
    -- until 12.1
    execute immediate 'alter session set PLSCOPE_SETTINGS=''IDENTIFIERS:ALL''';
  else 
    -- 12.2 and later
    execute immediate 'alter session set PLSCOPE_SETTINGS=''IDENTIFIERS:ALL, STATEMENTS:ALL''';
  end if;
end;
/

-- enable all warnings:
--
-- alter session set PLSQL_WARNINGS='ENABLE:ALL';
--
-- how to exclude warnings:
--
-- 05018: omitted optional AUTHID clause; default value DEFINER used
--   -> may not be relevant
-- 06005: inling of call of procedure '...' was done
--   -> due to PLSQL_OPTIMIZE_LEVEL=3, inlining.
-- 06006: uncalled procedure "..." is removed
--   -> due to inlining.
-- 06009: OTHERS handler does not end in RAISE or RAISE_APPLICATION_ERROR
--   -> false positives?
alter session set PLSQL_WARNINGS='ENABLE:ALL', 'DISABLE:(06005,06006)';

-- drop is drop
alter session set RECYCLEBIN=off;
