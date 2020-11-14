---------------------------------------------------------------------------------------
--- Less efficient case
CREATE or REPLACE FUNCTION f_getSumSal_nr (i_empno_tx VARCHAR2)
RETURN NUMBER 
IS
    v_out_nr NUMBER:=0;
    v_sql_tx VARCHAR2(2000);
BEGIN
    IF i_empno_tx IS NOT NULL THEN
        v_sql_tx:='SELECT sum(sal) FROM emp WHERE empno IN ('||i_empno_tx||')';
        EXECUTE IMMEDIATE v_sql_tx INTO v_out_nr;
    END IF;
    RETURN v_out_nr;
END;
/

----------------------------------------------------------------------------------------
-- Result
declare
    v_list_tx varchar2(256):='7369,7499,7521';
    v_sum_nr number;
begin
    v_sum_nr:=f_getSumSal_nr(v_list_tx);
    dbms_output.put_line('Total:'||v_sum_nr);
end;
/


----------------------------------------------------------------------------------------
-- More efficient option
CREATE OR REPLACE TYPE id_tt IS TABLE OF NUMBER
/
CREATE OR REPLACE FUNCTION f_getSumSal_nr (i_tt id_tt)
RETURN NUMBER IS
    v_out_nr NUMBER:=0;
BEGIN
    IF i_tt IS NOT NULL AND i_tt.count>0 THEN
        SELECT sum(sal) INTO v_out_nr
        FROM emp
        WHERE empno IN (SELECT t.column_value FROM TABLE(CAST(i_tt as id_tt)) t);
    END IF;
    RETURN v_out_nr;
END;
/
----------------------------------------------------------------------------------------
-- Result is the same
declare
    v_list_tt id_tt:=id_tt(7369,7499,7521);
    v_sum_nr number;
begin
    v_sum_nr:=f_getSumSal_nr(v_list_tt);
    dbms_output.put_line('Total:'||v_sum_nr);
end;
/