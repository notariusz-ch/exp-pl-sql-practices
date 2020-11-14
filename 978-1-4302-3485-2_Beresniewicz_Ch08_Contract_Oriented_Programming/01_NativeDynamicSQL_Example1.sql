set echo on
-- Make you output look pretty in SQL*Plus 
column ID_NR format 99999
column DISPLAY_TX format A15

-- Create object type
-- It should look exactly like the result you need
CREATE TYPE lov_t IS OBJECT (id_nr NUMBER, display_tx VARCHAR2(256))
/

-- Create a collection
CREATE TYPE lov_tt AS TABLE OF lov_t
/

-- Create a function that returns a collection
--
CREATE or replace FUNCTION f_getlov_tt  (
         i_table_tx    VARCHAR2,
         i_id_tx         VARCHAR2,  
         i_display_tx VARCHAR2, 
         i_order_nr   VARCHAR2,
         i_limit_nr   NUMBER:=100)
RETURN lov_tt 
IS
    v_out_tt lov_tt := lov_tt();
    v_sql_tx VARCHAR2(32767);
BEGIN
    v_sql_tx:='SELECT lov_item_t '||
                    'FROM (SELECT lov_t(' ||
                                   dbms_assert.simple_sql_name(i_id_tx)||', '||
                      dbms_assert.simple_sql_name(i_display_tx)||') lov_item_t '||
                    ' FROM '||dbms_assert.simple_sql_name(i_table_tx)||
                       ' order by '||dbms_assert.simple_sql_name(i_order_nr)||
                ')' ||
             ' WHERE ROWNUM <= :limit';

    EXECUTE IMMEDIATE v_sql_tx 
    BULK COLLECT INTO v_out_tt 
    USING i_limit_nr;

    RETURN v_out_tt;
END;
/

-- 
SELECT * 
FROM TABLE(
	   CAST
               (
               f_getlov_tt('EMP',   -- table
                           'EMPNO', -- ID column
                           'ENAME', -- Display column
                           'ENAME', -- Order column
                           5)       -- number of returned records 
               AS lov_tt
               )
          );