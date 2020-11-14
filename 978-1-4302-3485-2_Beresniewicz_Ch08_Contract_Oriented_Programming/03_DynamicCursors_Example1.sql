set serveroutput on
set echo on

CREATE or replace FUNCTION f_getRefCursor_ref 
        (i_type_tx VARCHAR2:='EMP',
        i_param_xml XMLTYPE:= XMLTYPE( 
                '<param col1_tx="DEPTNO" value1_tx="20" col2_tx="ENAME" value2_tx="KING"/>')
        )
RETURN SYS_REFCURSOR
IS
    v_out_ref SYS_REFCURSOR;
    v_sql_tx VARCHAR2(32767);
BEGIN
    IF i_type_tx = 'EMP' THEN
        SELECT              
            'WITH param AS  ('||
            '    SELECT   TO_NUMBER(EXTRACTVALUE (in_xml, ''/param/@value1_tx'')) value1, '||
            '                     EXTRACTVALUE (in_xml, ''/param/@value2_tx'') value2 '||
            '    FROM (SELECT :1 in_xml FROM DUAL) '||
            '                             ) '||
            ' SELECT count(*)'||
            ' FROM scott.emp, '||
            '             param '||
            ' WHERE emp.'|| dbms_assert.simple_sql_name(
                                        EXTRACTVALUE (i_param_xml, '/param/@col1_tx')
                                                    )||'=param.value1 '||
            'OR emp.'|| dbms_assert.simple_sql_name(
                                       EXTRACTVALUE (i_param_xml, '/param/@col2_tx')
                                        )||'=param.value2' 
        INTO v_sql_tx  FROM DUAL;

    ELSIF i_type_tx = 'B' THEN
        v_sql_tx:='<queryB>';   
    END IF;
    OPEN v_out_ref FOR v_sql_tx USING i_param_xml;
    RETURN v_out_ref;
END;
/
 declare
    v_ref SYS_REFCURSOR;
    
    v_out_nr number;
 begin
    v_ref:=f_getRefCursor_ref('EMP');
    
    fetch v_ref into v_out_nr;
    dbms_output.put_line('Count:'||v_out_nr);
    close v_ref;
 end;
/