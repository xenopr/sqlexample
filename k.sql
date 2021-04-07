SET ECHO OFF
SET FEEDBACK OFF
SET NEWP NONE
SET PAGESIZE 1000
SET LINESIZE 1000

connect stat/*@m2tood01

SET HEADING OFF
prompt Content-Type: text/html; charset=windows-1251
prompt
prompt <HTML><HEAD><meta http-equiv="Content-Type" content="text/html; charset=windows-1251">
prompt <TITLE>На койках сейчас</TITLE>
prompt </HEAD><BODY>
select '<H2 align="center">На койках сейчас, '||to_char(sysdate,'dd.mm.yyyy hh24:mi')||'</H2>' from dual;
prompt <TABLE cellspacing="1">
prompt <col width="10%">
prompt <col width="10%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">
prompt <col width="4%">

--койки
--протасов 17 06 2020
with k as(select prp.patient_room_id, prp.bed_number,
                 count(hc.id) cnt,
                 listagg(stat.parep.GetShortFIOClient(hc.client_id)||' '||to_char(stat.parep.GetBirthDayClient(hc.client_id),'yyyy')||
                         ' с '||to_char(prp.appointment_date,'dd.mm.yy hh24:mi'),', ') 
                 within group(order by prp.id) pa
           from hospital.patient_room_patient prp
                join hospital.hospital_card hc on hc.id=prp.hospital_card_id
          where prp.appointment_date<sysdate
                and stat.parep.GetBusyDepID(hc.id) is not null
                and not exists(select 1 from hospital.patient_room_patient prp1 
                                where prp1.hospital_card_id=prp.hospital_card_id and prp1.appointment_date<sysdate and prp1.id>prp.id)
          group by
                prp.patient_room_id,    
                prp.bed_number                                
          )                 
select
  '<tr>' Н,
  (case when Отделение||' '<>(LAG(Отделение,1) over (order by ordernum,pr_name))||' ' then '<td rowspan="3" valign="top">'||Отделение||'</td>' 
        when Отделение||' '<>(LAG(Отделение,2) over (order by ordernum,pr_name))||' ' then '' 
        when Отделение||' '<>(LAG(Отделение,3) over (order by ordernum,pr_name))||' ' then ''
        else '<td></td>' end) Отделение,
  '<td>'||substr(Палата,1,25)||'</td>' Палата,
  (case when Коек<1 then '<td bgcolor="white"'
        when Койка1 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка1||'"> </td>' Койка1,
  (case when Коек<2 then '<td bgcolor="white"'
        when Койка2 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка2||'"> </td>' Койка2,
  (case when Коек<3 then '<td bgcolor="white"'
        when Койка3 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка3||'"> </td>' Койка3,
  (case when Коек<4 then '<td bgcolor="white"'
        when Койка4 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка4||'"> </td>' Койка4,
  (case when Коек<5 then '<td bgcolor="white"'
        when Койка5 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка5||'"> </td>' Койка5,
  (case when Коек<6 then '<td bgcolor="white"'
        when Койка6 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка6||'"> </td>' Койка6,
  (case when Коек<7 then '<td bgcolor="white"'
        when Койка7 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка7||'"> </td>' Койка7,
  (case when Коек<8 then '<td bgcolor="white"'
        when Койка8 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка8||'"> </td>' Койка8,
  (case when Коек<9 then '<td bgcolor="white"'
        when Койка9 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка9||'"> </td>' Койка9,
  (case when Коек<10 then '<td bgcolor="white"'
        when Койка10 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка10||'"> </td>' Койка10,
  (case when Коек<11 then '<td bgcolor="white"'
        when Койка11 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка11||'"> </td>' Койка11,
  (case when Коек<12 then '<td bgcolor="white"'
        when Койка12 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка12||'"> </td>' Койка12,
  (case when Коек<13 then '<td bgcolor="white"'
        when Койка13 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка13||'"> </td>' Койка13,
  (case when Коек<14 then '<td bgcolor="white"'
        when Койка14 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка14||'"> </td>' Койка14,
  (case when Коек<15 then '<td bgcolor="white"'
        when Койка15 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка15||'"> </td>' Койка15,
  (case when Коек<16 then '<td bgcolor="white"'
        when Койка16 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка16||'"> </td>' Койка16,
  (case when Коек<17 then '<td bgcolor="white"'
        when Койка17 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка17||'"> </td>' Койка17,
  (case when Коек<18 then '<td bgcolor="white"'
        when Койка18 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка18||'"> </td>' Койка18,
  (case when Коек<19 then '<td bgcolor="white"'
        when Койка19 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка19||'"> </td>' Койка19,
  (case when Коек<20 then '<td bgcolor="white"'
        when Койка20 is null then '<td bgcolor="grey"' else '<td bgcolor="blue"' end)||' title="'||Койка20||'"> </td>' Койка20,
  '</tr>' К        
from
(                       
select
  dep.ordernum, pr.name pr_name,
  d.name Отделение,
  pr.name Палата,
  pr.beds_count Коек,
  (select max(t.bed_number) from HOSPITAL.PATIENT_ROOM_PATIENT t where t.patient_room_id=pr.id) Коек_,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=1) Койка1,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=2) Койка2,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=3) Койка3,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=4) Койка4,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=5) Койка5,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=6) Койка6,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=7) Койка7,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=8) Койка8,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=9) Койка9,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=10) Койка10,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=11) Койка11,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=12) Койка12,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=13) Койка13,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=14) Койка14,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=15) Койка15,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=16) Койка16,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=17) Койка17,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=18) Койка18,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=19) Койка19,
  (select pa from k where k.patient_room_id=pr.id and k.bed_number=20) Койка20
from 
  (select id,name,ordernum from table(stat.parep.GetListDep(0)) union all select d95.id, d95.name, 30 from hospital.department d95 where d95.id=95) dep
  join hospital.department d on d.id=dep.id
  join hospital.patient_room pr on pr.department_id=d.id
) x 
order by
  ordernum, pr_name;

prompt </TABLE>

select '<H6 align="right">сформировано '||to_char(sysdate,'dd.mm.yyyy hh24:mi')||'</H6>' from dual;

prompt </BODY></HTML>

exit
