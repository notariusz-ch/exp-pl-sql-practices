--------------------------------------------------------------------------------------------------
-- Repository tables
create sequence feed_seq
/
create table t_map
(map_id number primary key,
 name_tx varchar2(256),
 view_tx varchar2(256),
 sequence_tx varchar2(256)
 )
 /
 create table t_row
 (
 row_id number primary key,
 map_id number references t_map(map_id),
 displayname_tx varchar2(30)
 )
 /
 create index row_map_idx on t_row(map_id)
 /
 
 create table t_column
 (column_id number primary key,
  row_id number references t_row(row_id),
  name_tx varchar2(30),
  viewcol_tx varchar2(30),
  mandatory_yn varchar2(1)
  )
 /
 create index column_row_idx on t_column(row_id)
 / 

-- customer table and view (with the format conversion)
 create table t_reserve
 (reserve_id number primary key,
  reservation_id number,
  restaurant_tx varchar2(256),
  guests_nr number,
  date_dt date
  )
 /
 create or replace view RESERVE
 as
 select reserve_id,reservation_id,restaurant_tx, guests_nr, to_char(date_dt,'YYYYMMDD') date_dt
 from t_RESERVE
 /
 create or replace trigger reserve_II
 instead of insert on RESERVE
 begin
  insert into T_RESERVE (reserve_id, reservation_id, restaurant_tx, guests_nr, date_dt)
  values (:new.reserve_id, :new.reservation_id, :new.restaurant_tx, :new.guests_nr, to_date(:new.date_dt,'YYYYMMDD'));
 end;
 / 

-- Feed table
 create table t_incoming
 (id number primary key,
  map_id number references t_map(map_id),
  upload_dt date,
  data_cl CLOB
  )
/
 create index incoming_map_idx on t_incoming(map_id)
 / 

--------------------------------------------------------------------------------------------------
-- Repository data
 insert into t_map values (1,'Reservation log','RESERVE','FEED_SEQ'); 
 insert into t_row values (10,1,'DataMain');
 insert into t_column values (100,10,'Restaurant','Restaurant_TX','Y');
 insert into t_column values (105,10,'ID','Reservation_ID','Y');
 insert into t_column values (110,10,'Guests','Guests_NR','N');
 insert into t_column values (115,10,'Scheduled','Date_DT','N');
 
 insert into t_row values (20,1,'DateChange');
 insert into t_column values (205,20,'ID','Reservation_ID','Y');
 insert into t_column values (215,20,'Correction','Date_DT','Y');

---------------------------------------------------------------------------------------------------
-- main package
CREATE OR REPLACE 
PACKAGE feed_pkg
  IS
    -- Supporting types
    type string is record (text varchar2(32000));

    type StringList is table of string
    index by binary_integer;

    ---------------------------------------------------------
    -- Main procedure
    procedure p_process (in_id number);
END;
/

---------------------------------------------------------------------------------------------------
-- main package
CREATE OR REPLACE 
PACKAGE BODY feed_pkg
IS
    -- split CLOB into chunks
    FUNCTION f_splitStringCL_tt(in_clob_cl clob, in_delim varchar2,in_limitRows_NR number default 15000)
    return StringList
    is
        myStringList StringList;
        v_clobLength_nr binary_integer;

        v_buffer_tx varchar2(32767);
        v_readLength_nr binary_integer:=32000-length(in_delim);

        -- global pointers
        v_line_nr      number:=0;
        v_CLOBreadPointer_nr  integer:=1;

        -- For each loop
        v_localCounter_nr number:=0;

        v_startLine_nr number;
        v_endLine_nr   number:=1;

        v_localEndRead_nr number;
    begin
        v_clobLength_nr := dbms_lob.getlength(in_clob_cl);

        if v_clobLength_nr > 0
        then
            <<Main>>
            for i in 1..ceil(v_clobLength_nr/v_readLength_nr)
            loop
                dbms_lob.read(in_clob_cl,v_readLength_nr,v_CLOBreadPointer_nr,v_buffer_tx);

                -- special case - single chunk or the last piece
                if i = ceil(v_clobLength_nr/v_readLength_nr)
                then
                    if instr(v_buffer_tx,in_delim,-1)!=length(v_buffer_tx)-length(in_delim)+1
                    then
                        v_buffer_tx:=v_buffer_tx||in_delim; -- add terminal delimeter
                    end if;
                end if;

                v_localEndRead_nr:=instr(v_buffer_tx,in_delim,-1)+length(in_delim);
                v_CLOBreadPointer_nr:=v_CLOBreadPointer_nr+v_localEndRead_nr;

                -- next start would be the last escape char
                v_buffer_tx:=in_delim||v_buffer_tx;

                v_localCounter_nr:=0;
                v_endLine_nr:=1;

                loop
                    v_line_nr:=v_line_nr+1;

                    if v_line_nr > in_limitRows_NR
                    then
                        exit Main;
                    end if;

                    v_localCounter_nr:=v_localCounter_nr+1;

                    v_startLine_nr:=v_endLine_nr;
                    v_endLine_nr:=instr(v_buffer_tx,in_delim,1,v_localCounter_nr+1);


                    myStringList(v_line_nr).text :=
                                                ltrim(rtrim(trim(
                                                substr(v_buffer_tx,v_startLine_nr,v_endLine_nr - v_startLine_nr)
                                                                ),in_delim),in_delim);
                    exit when v_endLine_nr=v_localEndRead_nr;
                end loop;
            end loop;
        end if;

        return  myStringList;
    end;

    -- split varchar2 into chunks
    function f_splitStringTx_tt(in_string_tx varchar2, in_delim varchar2,in_elements_nr number default 0)
    return StringList
    is
        myString string;
        myStringList StringList;

        v_temp_tx varchar2(32000);
        v_delim varchar2(1) := ' ';
        v_position_nr number := 0;

        v_defaultEnclosed_cd varchar2(5) := '"';

        v_line_nr binary_integer := 1;
        v_BufferPosition_nr binary_integer :=1;
        v_bufferChars_nr binary_integer;
        v_LineLength_nr binary_integer;
    begin
        if trim(replace(in_string_tx,in_delim,'')) is not null
          then
            --Break file into lines
            v_temp_tx := in_string_tx || in_delim;  --Append the delimiter to the end so a blank last column is still registered
            v_LineLength_nr := length(v_temp_tx);

            loop
                if in_elements_nr > 0 then
                    if (v_line_nr > in_elements_nr)  then
                        exit;
                    end if;
                elsif v_BufferPosition_nr >  v_LineLength_nr then
                    exit;
                end if;

                --getting the number of chars we need, based on standard or quotes enclosed
                if substr(v_temp_tx,v_BufferPosition_nr,length(v_defaultEnclosed_cd)) = v_defaultEnclosed_cd then
                    v_bufferChars_nr := instr(v_temp_tx,v_defaultEnclosed_cd,v_BufferPosition_nr,2)-v_BufferPosition_nr+length(v_defaultEnclosed_cd);
                else
                    if v_BufferPosition_nr >= v_LineLength_nr then
                        v_bufferChars_nr := 0;
                    else
                        if instr(v_temp_tx,in_delim,v_BufferPosition_nr,1) > 0 then
                            v_bufferChars_nr := instr(v_temp_tx,in_delim,v_BufferPosition_nr,1)-v_BufferPosition_nr;
                        else
                            v_bufferChars_nr := (v_LineLength_nr+length(in_delim))-v_BufferPosition_nr;
                        end if;
                    end if;
                end if;

                if v_bufferChars_nr = 0 then
                    if v_line_nr = in_elements_nr then
                        myStringList(v_line_nr).text := substr(v_temp_tx,v_BufferPosition_nr);
                    else
                        myStringList(v_line_nr).text := '';
                    end if;
                else
                    myString.text := substr(v_temp_tx,v_BufferPosition_nr,v_bufferChars_nr);
                    myStringList(v_line_nr) := myString;
                end if;
                 myStringList(v_line_nr).text := ltrim(rtrim(rtrim(myStringList(v_line_nr).text,in_delim),v_defaultEnclosed_cd),v_defaultEnclosed_cd);

                 v_line_nr := v_line_nr +1;
                 v_BufferPosition_nr := v_BufferPosition_nr + v_bufferChars_nr+length(in_delim);

            end loop;
        end if;
      return  myStringList;
    end;

    -- main procedure
    -- functionality is somewhat limited by enough to illustrate the case
    procedure p_process(in_id number)
    is
        v_main_cl CLOB;
        v_map_id  number;

        TYPE integer_tt IS TABLE OF integer index by binary_integer;
        v_cur_tt integer_tt;

        type number_tt is table of number index by binary_integer;
        v_groupRow_tt number_tt;

        type name_tt is table of varchar2(256) index by varchar2(256);
        v_columnRow_tt name_tt;

        v_row_tt StringList;
        v_data_tt StringList;
        v_header_tt StringList;

        v_map_rec t_map%rowtype;

        -- local vars
        cursor c_cols (cin_row_id number)
        is
        select name_tx, viewcol_tx, mandatory_yn
        from t_column
        where row_id = cin_row_id;

        type column_tt is table of c_cols%rowtype index by binary_integer;
        v_col_tt column_tt;
    begin
        -- retrive CLOB and type
        select data_cl, map_id
        into v_main_cl, v_map_id
        from t_incoming
        where id = in_id;

        -- retrive repository info
        select *
        into v_map_rec
        from t_map
        where map_id = v_map_id;

        select row_id
        bulk collect into v_groupRow_tt
        from t_row
        where map_id = v_map_id;

        -- Split feed into rows/columns
        v_row_tt:=f_splitStringCl_tt(v_main_cl,chr(10),64000);
        if v_row_tt.count!=0
        then
            -- get header
            v_header_tt:=f_splitStringTx_tt(v_row_tt(1).text,',',0);

            -- build inserts
            FOR r IN v_groupRow_tt.first..v_groupRow_tt.last LOOP
                declare
                    v_sql_tx varchar2(32767);
                    v_col_tx varchar2(32767):=v_map_rec.view_tx||'_id';
                    v_val_tx varchar2(32767):=v_map_rec.sequence_tx||'.nextval';
                begin
                   v_cur_tt(r):=dbms_sql.open_cursor;
                   FOR c IN c_cols(v_groupRow_tt(r)) LOOP
                       FOR i IN v_header_tt.first..v_header_tt.last LOOP
                           IF v_header_tt(i).text=c.name_tx THEN
                               -- cache information for future usage
                               v_col_tt(i):=c;
                               v_columnRow_tt(r||'|'||c.name_tx):=v_col_tt(i).viewcol_tx;
                               -- define bind variables
                               v_col_tx:=v_col_tx||','||v_col_tt(i).viewcol_tx;
                               v_val_tx:=v_val_tx||',:'||v_col_tt(i).viewcol_tx;
                           END IF;
                       END LOOP;
                   END LOOP;
                   -- parse prepared statement
                   v_sql_tx:='INSERT INTO '||v_map_rec.view_tx||'('||v_col_tx||') VALUES('||v_val_tx||')';
                   dbms_sql.parse(v_cur_tt(r),v_sql_tx,dbms_sql.native);
                end;
            END LOOP;

            -- process inserts
            FOR i IN 2..v_row_tt.count LOOP -- first row is a header
                -- split string
                begin
                    savepoint BeforeGroup;
                    v_data_tt:=f_splitStringTx_tt(v_row_tt(i).text,',',0);
                    FOR r IN v_groupRow_tt.first..v_groupRow_tt.last LOOP
                        declare
                            v_nr number;
                            v_skip_yn varchar2(1):='N';
                        begin
                            FOR c IN v_col_tt.first..v_col_tt.last LOOP
                                IF v_columnRow_tt.exists(r||'|'||v_col_tt(c).name_tx) then
                                    -- just an extra twist - if all mandatory columns are not filled - skip the row
                                    if v_col_tt(c).mandatory_yn = 'Y' and v_data_tt(c).text is null then
                                        v_skip_yn:='Y';
                                    else
                                        dbms_sql.bind_variable(v_cur_tt(r),':'||v_col_tt(c).viewcol_tx, v_data_tt(c).text);
                                    end if;
                                END IF;
                            END LOOP;

                            if  v_skip_yn = 'N' then
                                v_nr:=dbms_sql.execute(v_cur_tt(r));
                            end if;
                        end;
                     END LOOP;
                exception
                    when others then
                        rollback to SavePoint BeforeGroup;
                        dbms_output.put_line('Row:'||i||' failed with the error '||sqlerrm);
                end;
            END LOOP;
        end if;

        -- close all cursors
        if v_cur_tt.count!=0
        then
            for r in v_cur_tt.first..v_cur_tt.last
            loop
                if dbms_sql.is_open(v_cur_tt(r)) then
                    dbms_sql.close_cursor(v_cur_tt(r));
                end if;
            end loop;
        end if;

    exception
        when others  then
            -- close all cursors
            if v_cur_tt.count!=0
            then
                for r in v_cur_tt.first..v_cur_tt.last
                loop
                    if dbms_sql.is_open(v_cur_tt(r)) then
                        dbms_sql.close_cursor(v_cur_tt(r));
                    end if;
                end loop;
            end if;

            raise;
    end;
END;
/
