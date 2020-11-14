-- Required object type
CREATE TYPE id_tt IS TABLE OF NUMBER
/
-- Global sequence counter
CREATE SEQUENCE Object_SEQ
/

CREATE OR REPLACE PACKAGE clone_pkg
IS
    -- Parent/child pair storage
    TYPE pair_tt IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    v_Pair_t pair_tt;

    -- OrgTree hierarchy lookup
    TYPE list_rec IS RECORD
        (table_tx VARCHAR2(50), fk_tx VARCHAR2(50), pk_tx VARCHAR2(50));
    TYPE list_rec_tt IS TABLE OF list_rec;

    -- supporting modules
    FUNCTION f_getChildrenRec (in_tablename_tx VARCHAR2) RETURN list_rec_tt;
    PROCEDURE p_process (in_list_rec clone_pkg.list_rec, in_parent_list id_tt);

    -- main procedure
    PROCEDURE p_clone (in_table_tx VARCHAR2, in_pk_tx VARCHAR2, in_id NUMBER);
END;
/
CREATE OR REPLACE PACKAGE BODY clone_pkg
IS
    FUNCTION f_getChildrenRec (in_tablename_tx VARCHAR2)
    RETURN list_rec_tt
    IS
        v_out_tt list_rec_tt;
    BEGIN
        SELECT fk_tab.table_name, fk_tab.column_name fk_tx, pk_tab.column_name pk_tx
        BULK COLLECT INTO v_Out_tt
        FROM
            (SELECT ucc.column_name, uc.table_name
             FROM user_cons_columns ucc,
                  user_constraints uc
             WHERE ucc.constraint_name = uc.constraint_name
             AND   constraint_type = 'P') pk_tab,
             (SELECT ucc.column_name, uc.table_name
              FROM   user_cons_columns ucc,
                    (SELECT constraint_name, table_name
                    FROM user_constraints
                    WHERE r_constraint_name = (SELECT constraint_name
                                               FROM user_constraints
                                               WHERE table_name = in_tablename_tx
                                               AND constraint_type = 'P'
                                               )
                       ) uc
             WHERE ucc.constraint_name = uc.constraint_name ) fk_tab
        WHERE pk_tab.table_name = fk_tab.table_name;
        RETURN v_out_tt;
    END;

    PROCEDURE p_process (in_list_rec clone_pkg.list_rec, in_parent_list id_tt)
    IS
        v_execute_tx VARCHAR2(32767);
    BEGIN
        v_execute_tx:=
            'DECLARE '||
            '    TYPE rows_tt IS TABLE OF '||in_list_rec.table_tx||'%rowtype;'||
            '    v_rows_tt rows_tt;'||
            '    v_new_id number;'||
            '    v_list clone_pkg.list_rec_tt;'||
            '    v_parent_list id_tt:=id_tt();'||
            'BEGIN '||
            '    SELECT * BULK COLLECT INTO v_rows_tt '||
            '    FROM '||in_list_rec.table_tx||' t WHERE '||in_list_rec.fk_tx||
            '       IN  (SELECT column_value FROM TABLE (CAST (:1 as id_tt)));'||
            '    IF v_rows_tt.count()=0 THEN RETURN; END IF;'||
            '    FOR i IN v_rows_tt.first..v_rows_tt.last LOOP '||
            '       SELECT object_Seq.nextval INTO v_new_id FROM DUAL;'||
            '       v_parent_list.extend;'||
            '       v_parent_list(v_parent_list.last):=v_rows_tt(i).'||in_list_rec.pk_tx||';'||
            '       clone_pkg.v_Pair_t(v_rows_tt(i).'||in_list_rec.pk_tx||'):=v_new_id;'||
            '       v_rows_tt(i).'||in_list_rec.pk_tx||':=v_new_id;'||
            '       v_rows_tt(i).'||in_list_rec.fk_tx||':=clone_pkg.v_Pair_t(v_rows_tt(i).'||in_list_rec.fk_tx||');'||
            '    END LOOP;'||
            '    FORALL i IN v_rows_tt.first..v_rows_tt.last '||
            '    INSERT INTO '||in_list_rec.table_tx||' VALUES v_rows_tt(i);'||
            '    v_list:=clone_pkg.f_getchildrenRec('''||in_list_rec.table_tx||''');'||
            '    IF v_list.count()=0 THEN RETURN; END IF;'||
            '    FOR l IN v_list.first..v_list.last LOOP '||
            '        clone_pkg.p_process(v_list(l),v_parent_list);'||
            '    END LOOP;'||
            'END;';
        EXECUTE IMMEDIATE v_execute_tx USING in_parent_list;
    END;

    PROCEDURE p_clone (in_table_tx VARCHAR2, in_pk_tx VARCHAR2, in_id NUMBER)
    IS
        v_new_id NUMBER;
        PROCEDURE p_processRoot is
            v_sql_tx VARCHAR2(32767);
        BEGIN
          v_sql_tx:=
          'DECLARE '||
          '   v_row '||in_table_tx||'%ROWTYPE; '||
          '   v_listDirectChildren_t clone_pkg.list_rec_tt; '||
          '   v_parent_list id_tt:=id_tt(); '||
          '   v_old_id NUMBER:=:1; '||
          '   v_new_id NUMBER:=:2; '||
          'BEGIN '||
          '  SELECT * INTO v_row FROM '||in_table_tx||
          '    WHERE '||in_pk_tx||'=v_old_id;'||
          '    v_row.'||in_pk_tx||':=v_new_id;'||
          '    clone_pkg.v_Pair_t(v_old_id):=v_new_id;'||
          '    v_parent_list.extend;'||
          '    v_parent_list(v_parent_list.last):=v_old_id;'||
          '    INSERT INTO '||in_table_tx||' VALUES v_row;'||
          '    v_listDirectChildren_t:=clone_pkg.f_getChildrenRec(:3);'||
          '    FOR i IN v_listDirectChildren_t.first..v_listDirectChildren_t.last'||
          '    LOOP'||
          '        clone_pkg.p_process(v_listDirectChildren_t(i),v_parent_list); '||
          '     END LOOP;'||
          'END; ';
          EXECUTE IMMEDIATE v_sql_tx USING in_id,v_new_id,UPPER(in_table_tx);
        END;
    BEGIN
        clone_pkg.v_Pair_t.delete;
        SELECT object_seq.nextval INTO v_new_id FROM DUAL;
        p_processRoot;
    END;
END;
/