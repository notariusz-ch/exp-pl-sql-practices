set echo on
set pagesize 100
set line 80
-- Make you output look pretty in SQL*Plus 
column ID_NR format 99999
column DISPLAY_TX format A15

-- Required object types are the same as in 01_NativeDynamicSQL_Example1.sql
-- Create a function that returns a collection
CREATE or REPLACE FUNCTION f_getlov_tt  (
        i_table_tx    VARCHAR2,
        i_id_tx         VARCHAR2, 
        i_display_tx VARCHAR2, 
        i_order_nr   VARCHAR2,
        i_limit_nr     NUMBER:=50)
RETURN lov_tt 
IS
    v_out1_tt lov_tt := lov_tt();
    v_out2_tt lov_tt := lov_tt();
    v_sql_tx VARCHAR2(32767);
    v_cur SYS_REFCURSOR;
BEGIN
    v_sql_tx:='SELECT lov_t(' ||
                               dbms_assert.simple_sql_name(i_id_tx)||','||
                  dbms_assert.simple_sql_name(i_display_tx)||')'||
      ' FROM '||dbms_assert.simple_sql_name(i_table_tx)||
      ' ORDER BY '||dbms_assert.simple_sql_name(i_order_nr);

    OPEN v_cur FOR v_sql_tx;
    FETCH v_cur BULK COLLECT INTO v_out1_tt LIMIT i_limit_nr;
    IF v_out1_tt.count=i_limit_nr AND UPPER(v_out1_tt(i_limit_nr).display_tx)>'N' then
           FETCH v_cur BULK COLLECT INTO v_out2_tt;
           SELECT v_out1_tt MULTISET UNION v_out2_tt INTO v_out1_tt FROM DUAL;
    END IF;
    CLOSE v_cur;
     
    RETURN v_out1_tt;
END;
/
-- Run the query with limit=11 (to illustrate the business case)
-- since 11th name (SCOTT) is above the middle of the alfabet
-- which means we should continue untill the end
SELECT * 
FROM TABLE(
	   CAST
               (
               f_getlov_tt('EMP',   -- table
                           'EMPNO', -- ID column
                           'ENAME', -- Display column
                           'ENAME', -- Order column
                           11)       -- number of returned records 
               AS lov_tt
               )
          );