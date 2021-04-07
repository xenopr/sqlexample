--для проверки форма14
--протасов
--количества операций по группам в форме14 (раздел 4000) (из канцер-выписок)
--10 09 2018
--11 09 2018
--14 09 2018  признак - первая операция
--11 01 2019
--09 12 2019 готовим к отчету за 2019 год, осложнения из множественности, количество операций с осложнениями, не количество осложнений

--30 12 2019 
--28 12 2020 за 2020
--12 01 2020 в годовой, загружа ок, по поводу ЗНО ГР27 для аппендоэктопий 0 надо

--with dd as (select :DTF dtf, :DTT dtt from dual),
with dd as (select to_date('26.12.2019','dd.mm.yyyy') dtf, to_date('25.12.2020','dd.mm.yyyy') dtt from dual),
     Dep as (select id from table(stat.parep.GetListDep(0)))

select
 lpad('                        ',length(stat.parep.GetFormGroupOrder(sg.grcode)),' ')||ltrim(sg.grname) Группа_имя_к1,
 sg.grcode Группа_к2,
 --форма 14 раздел 4000 часть 1
 count(oper.csst_id) Всего_к3,
 count(oper.age14) До14лет_к4,
 count(oper.age1) До1года_к5,
 count(oper.age15_17) От15до17лет_к6,
 count(oper.vmt) ВМТ_к7,
 count(case when oper.vmt=1 and oper.age14=1    then 1 end) ВМТ_до14лет_к8,
 count(case when oper.vmt=1 and oper.age1=1     then 1 end) ВМТ_до1года_к9,
 count(case when oper.vmt=1 and oper.age15_17=1 then 1 end) ВМТ_от15до17лет_к10,
 count(oper.compl) Осложн_к11,
 count(case when oper.compl=1 and oper.age14=1    then 1 end) Осложн_до14лет_к12,
 count(case when oper.compl=1 and oper.age1=1     then 1 end) Осложн_до1года_к13,
 count(case when oper.compl=1 and oper.age15_17=1 then 1 end) Осложн_от15до17лет_к14,
 --форма 14 раздел 4000 часть 2
 count(case when oper.compl=1 and oper.vmt=1    then 1 end) ОсложнВМТ_к15,
 count(case when oper.compl=1 and oper.vmt=1 and oper.age14=1    then 1 end) ОсложнВМТ_до14лет_к16,
 count(case when oper.compl=1 and oper.vmt=1 and oper.age1=1     then 1 end) ОсложнВМТ_до1года_к17,
 count(case when oper.compl=1 and oper.vmt=1 and oper.age15_17=1 then 1 end) ОсложнВМТ_от15до17лет_к18,
 count(case when oper.dead=1 and oper.isfirst=1 then 1 end)                     Умерло_к19,
 count(case when oper.dead=1 and oper.age14=1 and oper.isfirst=1    then 1 end) Умерло_до14лет_к20,
 count(case when oper.dead=1 and oper.age1=1 and oper.isfirst=1     then 1 end) Умерло_до1года_к21,
 count(case when oper.dead=1 and oper.age15_17=1 and oper.isfirst=1 then 1 end) Умерло_от15до17лет_к22,
 count(case when oper.dead=1 and oper.vmt=1 and oper.isfirst=1                     then 1 end) УмерлоВМТ_к23,
 count(case when oper.dead=1 and oper.vmt=1 and oper.age14=1 and oper.isfirst=1    then 1 end) УмерлоВМТ_до14лет_к24,
 count(case when oper.dead=1 and oper.vmt=1 and oper.age1=1 and oper.isfirst=1     then 1 end) УмерлоВМТ_до1года_к25,
 count(case when oper.dead=1 and oper.vmt=1 and oper.age15_17=1 and oper.isfirst=1 then 1 end) УмерлоВМТ_от15до17лет_к26,
 count(case when sg.grcode not in ('9.1','9.2','9.4') and oper.zno=1 and oper.isfirst=1 then 1 end) ЗНО_к27,
 count(case when sg.grcode not in ('9.1','9.2','9.4') and oper.zno=1 and oper.isfirst=1 then 1 end) На_Морфо_к28,
 --форма 14 раздел 4001
 count(oper.pensioner) Старые_к3,
 count(case when oper.pensioner=1 and oper.vmt=1 then 1 end) СтарыеВМТ_к4,
 count(case when oper.pensioner=1 and oper.compl=1 then 1 end) СтарыеОсложн_к5,
 count(case when oper.pensioner=1 and oper.compl=1 and oper.vmt=1 then 1 end) СтарыеОсложнВМТ_к6,
 count(case when oper.pensioner=1 and oper.dead=1 and oper.isfirst=1 then 1 end) СтарыеУмерло_к7,
 count(case when oper.pensioner=1 and oper.dead=1 and oper.vmt=1 and oper.isfirst=1 then 1 end) СтарыеУмерлоВМТ_к8
from
 stat.surgerygroup sg
 left join (select sgs1.scode, sgs1.grcode from stat.surgerygroups sgs1 where sgs1.grform='FORM14'
            union all
            select cst1.code, '1' from hospital.cancer_surgery_type cst1
           ) sgs on sgs.grcode=sg.grcode
 left join (
   select
     hc.id hc_id,
     csst.id csst_id,
     cst.code scode,
     mkbfi.code mkbcode,
     stat.parep.GetClientAge(cl.id,hc.outtake_date) age,
     (case when stat.parep.GetClientAge(cl.id,hc.outtake_date)<=14 then 1 else null end) age14,
     (case when stat.parep.GetClientAge(cl.id,hc.outtake_date)<1 then 1 else null end) age1,
     (case when stat.parep.GetClientAge(cl.id,hc.outtake_date) between 15 and 17 then 1 else null end) age15_17,
     (case when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 1 else null end) pensioner,
     (case when p.project_result_type2_id in (-34,-25) then 1 else null end) dead,
     (case when (substr(mkbfi.code,1,1)='C' or substr(mkbfi.code,1,2)='D0') then 1 else null end) zno,
     (case when exists(select 1 from stat.surgerygroups sgs1 where sgs1.grform='FORM14VMT' and sgs1.scode=cst.code) then 1 else null end) vmt,
     (case when surcop.cnt>0 then 1 end) compl,
     (case when exists(select 1 from hospital.cancer_sum_surgery_treat csst1 where csst1.cancer_summary_id=csst.cancer_summary_id and csst1.id>csst.id) then 0 else 1 end) isfirst
   from
     dd, dep, table(stat.parep.GetListBedDischargedPeriod(dd.dtf,dd.dtt,dep.id)) x, hospital.hospital_card hc,
     hospital.project p, hospital.client cl, hospital.diagnosis di, hospital.mkb mkbfi,
     hospital.cancer_register_document crd, hospital.cancer_summary cas
     --хирургическое лечение
     join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id = cas.id   --операции из канцервыписки
     left join hospital.cancer_surgery_type cst on cst.id=csst.surgery_type_id --название операции федеральное
     --осложнения послеоперационные
     left join (select csc.cancer_summary_surgery_id, count(sc.id) cnt
                  from hospital.cancer_sum_surgery_compl csc
                       join hospital.surgery_complication sc on sc.id=csc.complication_id
                 where csc.type='Postoperative'
                 group by csc.cancer_summary_surgery_id) surcop on surcop.cancer_summary_surgery_id=csst.id
   where
     hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id and di.id=p.main_diagnosis_id and mkbfi.id=di.mkb10_id
     and cas.hospital_card_id=hc.id and crd.id=cas.document_id
   ) oper on oper.scode=sgs.scode
    --decode(sg.grcode,'1','000',oper.scode)=decode(sg.grcode,'1','000',sgs.scode) --or sg.grcode='1'

where
 sg.grform='FORM14'
--  and length(sg.grcode)<3
group by
 sg.grcode, sg.grname

order by
  stat.parep.GetFormGroupOrder(sg.grcode)
