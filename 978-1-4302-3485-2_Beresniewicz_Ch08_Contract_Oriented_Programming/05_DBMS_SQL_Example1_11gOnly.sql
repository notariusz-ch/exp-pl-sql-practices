set echo on
set serveroutput on

CREATE or REPLACE PROCEDURE p_explainCursor (io_ref_cur IN OUT SYS_REFCURSOR)
IS
    v_cur      INTEGER := dbms_sql.open_cursor;
    v_cols_nr NUMBER := 0;
    v_cols_tt dbms_sql.desc_tab;
BEGIN
    v_cur:=dbms_sql.to_cursor_number(io_ref_cur);
    dbms_sql.describe_columns (v_cur, v_cols_nr, v_cols_tt);
    FOR i IN 1 .. v_cols_nr LOOP
        dbms_output.put_line(v_cols_tt (i).col_name);
    END LOOP;       
    io_ref_cur:=dbms_sql.to_refcursor(v_cur);
END;
/
DECLARE
    v_tx VARCHAR2(256):='SELECT * FROM dept';
    v_cur SYS_REFCURSOR;
BEGIN
    OPEN v_cur FOR v_tx;
    p_explainCursor(v_cur);
    CLOSE v_cur;
  END;
/
