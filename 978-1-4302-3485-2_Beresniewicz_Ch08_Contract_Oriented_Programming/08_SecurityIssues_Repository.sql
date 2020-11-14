-- Create repository
CREATE TABLE t_extra_ui 
(id_nr                  NUMBER PRIMARY KEY,
 displayName_tx VARCHAR2(256),
 function_tx         VARCHAR2(50),
 v1_label_tx        VARCHAR2(100),
 v1_type_tx         VARCHAR2(50),
 v1_required_yn  VARCHAR2(1),
 v1_lov_tx           VARCHAR2(50), 
 v1_convert_tx    VARCHAR2(50),

 v2_label_tx        VARCHAR2(100),
 v2_type_tx         VARCHAR2(50),
 v2_required_yn  VARCHAR2(1),
 v2_lov_tx           VARCHAR2(50), 
 v2_convert_tx    VARCHAR2(50),

 v3_label_tx        VARCHAR2(100),
 v3_type_tx         VARCHAR2(50),
 v3_required_yn  VARCHAR2(1),
 v3_lov_tx           VARCHAR2(50), 
 v3_convert_tx    VARCHAR2(50),

 v4_label_tx        VARCHAR2(100),
 v4_type_tx         VARCHAR2(50),
 v4_required_yn  VARCHAR2(1),
 v4_lov_tx           VARCHAR2(50), 
 v4_convert_tx    VARCHAR2(50),

 v5_label_tx        VARCHAR2(100),
 v5_type_tx         VARCHAR2(50),
 v5_required_yn  VARCHAR2(1),
 v5_lov_tx           VARCHAR2(50), 
 v5_convert_tx    VARCHAR2(50)
)
/
-- Create a logical wrapper
CREATE OR REPLACE FUNCTION f_umbrella_cl (i_id_nr NUMBER, 
                               v1_tx VARCHAR2:=null,
                               v2_tx VARCHAR2:=null,
                               v3_tx VARCHAR2:=null,
                               v4_tx VARCHAR2:=null,                                                              
                               v5_tx VARCHAR2:=null)
RETURN CLOB
IS
    v_out_cl CLOB;
    v_sql_tx VARCHAR2(32767);
    v_rec t_extra_ui%ROWTYPE;
BEGIN
    SELECT * INTO v_rec FROM t_extra_ui WHERE id_nr=i_id_nr;

    IF v_rec.v1_label_tx IS NOT NULL THEN
        v_sql_tx:=nvl(v_rec.v1_convert_tx,':1');
    END IF;

    IF v_rec.v2_label_tx IS NOT NULL THEN
        v_sql_tx:=v_sql_tx||','||nvl(v_rec.v2_convert_tx,':2');
    END IF;

    IF v_rec.v3_label_tx IS NOT NULL THEN
        v_sql_tx:=v_sql_tx||','||nvl(v_rec.v3_convert_tx,':3');
    END IF;

    IF v_rec.v4_label_tx IS NOT NULL THEN
        v_sql_tx:=v_sql_tx||','||nvl(v_rec.v4_convert_tx,':4');
    END IF;
    
    IF v_rec.v5_label_tx IS NOT NULL THEN
        v_sql_tx:=v_sql_tx||','||nvl(v_rec.v5_convert_tx,':5');
    END IF;

    v_sql_tx:='BEGIN :out:='||v_rec.function_tx||'('||v_sql_tx||'); END;'; 

    IF v5_tx IS NOT NULL THEN
        EXECUTE IMMEDIATE v_sql_tx USING OUT v_out_cl, v1_tx,v2_tx,v3_tx,v4_tx,v5_tx;
    ELSIF v4_tx IS NOT NULL THEN
        EXECUTE IMMEDIATE v_sql_tx USING OUT v_out_cl, v1_tx,v2_tx,v3_tx,v4_tx;
    ELSIF v3_tx IS NOT NULL THEN
        EXECUTE IMMEDIATE v_sql_tx USING OUT v_out_cl, v1_tx,v2_tx,v3_tx;
    ELSIF v2_tx IS NOT NULL THEN
        EXECUTE IMMEDIATE v_sql_tx USING OUT v_out_cl, v1_tx,v2_tx;
    ELSIF v1_tx IS NOT NULL THEN
        EXECUTE IMMEDIATE v_sql_tx USING OUT v_out_cl, v1_tx;
    ELSE
        EXECUTE IMMEDIATE v_sql_tx USING OUT v_out_cl;
    END IF; 

    RETURN v_out_cl;
END;
/

---------------------------------------------------------------------------------------------------
-- Create a sample function
CREATE FUNCTION f_getEmp_CL (i_job_tx VARCHAR2, i_hiredate_dt DATE) 
RETURN CLOB 
IS
    v_out_cl CLOB;
    PROCEDURE p_add(pi_tx VARCHAR2) IS
    BEGIN
        dbms_lob.writeappend(v_out_cl,length(pi_tx),pi_tx);
    END;
BEGIN
    dbms_lob.createtemporary(v_out_cl,true,dbms_lob.call);
    p_add('<html><table>');    
    FOR c IN (SELECT '<tr>'||'<td>'||empno||'</td>'||'<td>'||ename||'</td>'||'</tr>' row_tx
                     FROM emp 
                     WHERE job = i_job_tx
                     AND hiredate >= NVL(i_hiredate_dt,add_months(sysdate,-36))
		)
    LOOP 
        p_add(c.row_tx);
    END LOOP;
    p_add('</table></html>');
    RETURN v_out_cl;
END;
/
---------------------------------------------------------------------------------------------------
-- Register the function
INSERT INTO t_extra_ui ( id_nr,displayName_tx,function_tx,
                      v1_label_tx, v1_type_tx, v1_required_yn, v1_lov_tx, v1_convert_tx,
                      v2_label_tx, v2_type_tx, v2_required_yn, v2_lov_tx, v2_convert_tx )
VALUES (100, 'Filter Employees', 'f_getEmp_cl',
        'Job','TEXT','Y',null,null,
        'Hire Date','DATE','N',null,'TO_DATE(:2,''YYYYMMDD''')
/

