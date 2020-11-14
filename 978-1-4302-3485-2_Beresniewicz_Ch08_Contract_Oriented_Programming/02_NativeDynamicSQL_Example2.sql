-- Connect as SYS or any other administrative account
-- The following grant has to be done explicitly
grant alter session to SCOTT
/

-- Connect as SCOTT
CREATE PROCEDURE p_dropFBIndex (i_index_tx VARCHAR2) is
BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET EVENTS ''10624 trace name context forever, level 12''';
    EXECUTE IMMEDIATE 'drop index '||i_index_tx;
    EXECUTE IMMEDIATE 'ALTER SESSION SET EVENTS ''10624 trace name context off''';
END;
/
