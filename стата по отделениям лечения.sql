--справка количество распределение по территориям и видам лечения
--инфа из канцер-выписок и стацкарт
--по выписанным (освободившим койки) в указанный период
--протасов 15 02 2018

--распределение выписанных больных по территориям
-- 16 02 2018
--25 12 2018 ДС радио
--01 03 2019 параметр - что считать
--sh=0 госпитализации, sh=1 койкодни, sh=2 среднее койкодней
--25 03 2019 фильтр только ЗНО
--16 05 2019 фильтр только ОМС под Услова
--31 10 2019 GetListDep

with dd as (select to_date('26.12.2018','dd.mm.yyyy')  dtf,   to_date('25.09.2019','dd.mm.yyyy')  dtt, 0 ds, 0 sh, 0 zno, 1 oms FROM   dual)
--with dd as (select :DTF  dtf,   :DTT  dtt , :DS ds , :SH sh, :ZNO zno, :OMS oms FROM   dual)

select
 ИД_отделения,
 Отделение_кратко,
 decode(dd.sh,0,Лекарственная,1,ЛекарственнаяК,2,round(ЛекарственнаяК/Лекарственная,1)) Лекарственная,
 decode(dd.sh,0,Только_лекарственная,1,Только_лекарственнаяК,2,round(Только_лекарственнаяК/Только_лекарственная,1)) Только_лекарственная,
 decode(dd.sh,0,В_лекарствн_химио,1,В_лекарствн_химиоК,2,round(В_лекарствн_химиоК/В_лекарствн_химио,1)) В_лекарствн_химио,
 decode(dd.sh,0,В_лекарствн_гормоно,1,В_лекарствн_гормоноК,2,round(В_лекарствн_гормоноК/В_лекарствн_гормоно,1)) В_лекарствн_гормоно,
 decode(dd.sh,0,В_лекарствн_таргет,1,В_лекарствн_таргетК,2,round(В_лекарствн_таргетК/В_лекарствн_таргет,1)) В_лекарствн_таргет,
 decode(dd.sh,0,Сочетанное,1,СочетанноеК,2,round(СочетанноеК/Сочетанное,1)) Сочетанное,
 decode(dd.sh,0,Лучевое,1,ЛучевоеК,2,round(ЛучевоеК/Лучевое,1)) Лучевое,
 decode(dd.sh,0,Операция,1,ОперацияК,2,round(ОперацияК/Операция,1)) Операция,
 decode(dd.sh,0,Операция_и_Лучевое,1,Операция_и_ЛучевоеК,2,round(Операция_и_ЛучевоеК/Операция_и_Лучевое,1)) Операция_и_Лучевое,
 decode(dd.sh,0,Операция_и_Лекарственная,1,Операция_и_ЛекарствК,2,round(Операция_и_ЛекарствК/Операция_и_Лекарственная,1)) Операция_и_Лекарственная,
 decode(dd.sh,0,Лекарственная_и_Лучевое,1,Лекарственная_и_ЛучевоеК,2,round(Лекарственная_и_ЛучевоеК/Лекарственная_и_Лучевое,1)) Лекарственная_и_Лучевое,
 decode(dd.sh,0,Операция_Лекарственная_Лучевое,1,Операция_Лекарств_ЛучК,2,round(Операция_Лекарств_ЛучК/Операция_Лекарственная_Лучевое,1)) Операция_Лекарственная_Лучевое,
 decode(dd.sh,0,Комплексное,1,КомплексноеК,2,round(КомплексноеК/Комплексное,1)) Комплексное,
 decode(dd.sh,0,Без_спец_лечения,1,Без_спец_леченияК,2,round(Без_спец_леченияК/Без_спец_лечения,1)) Без_спец_лечения,
 Всего,
 Койко_дней
from
dd,(
select
 ИД_отделения,
 Отделение_кратко,
 sum(case when Лекарственная>0 then 1 end ) Лекарственная,   --не нужно показывать
 sum(case when Лечение='только лекарственная' then 1 end ) Только_лекарственная,

 sum(case when Лечение='только лекарственная' and nvl(Химио,0)>0 and nvl(Гормоно,0)=0 and nvl(Таргетное,0)=0 then 1 end ) В_лекарствн_химио,            --из только лекарственная
 sum(case when Лечение='только лекарственная' and nvl(Химио,0)=0 and nvl(Гормоно,0)>0 and nvl(Таргетное,0)=0 then 1 end ) В_лекарствн_гормоно,        --из только лекарственная
 sum(case when Лечение='только лекарственная' and nvl(Химио,0)=0 and nvl(Гормоно,0)=0 and nvl(Таргетное,0)>0 then 1 end ) В_лекарствн_таргет,       --из только лекарственная

 sum(case when Лечение='только лекарственная' and (nvl(sign(Химио),0)+nvl(sign(Гормоно),0)+nvl(sign(Таргетное),0) )>1 then 1 end ) Сочетанное,  --(больше одного вида только лекарственного лечения)
 sum(case when Лечение='только лучевое' then 1 end ) Лучевое,   --только
 sum(case when Лечение='только операция' then 1 end ) Операция, --только
 sum(case when Лечение='операция и лучевое' then 1 end ) Операция_и_Лучевое,   --оно же комбинированое лечение
 sum(case when Лечение='операция и лекарственная' then 1 end ) Операция_и_Лекарственная,
 sum(case when Лечение='лекарственная и лучевое' then 1 end ) Лекарственная_и_Лучевое,
 sum(case when Лечение='операция и лекарственная и лучевое' then 1 end ) Операция_Лекарственная_Лучевое,
 sum(case when Лечение='операция и лекарственная и лучевое' or Лечение='лекарственная и лучевое' or Лечение='операция и лекарственная' then 1 end ) Комплексное,
 sum(case when Лечение='без специального' then 1 end ) Без_спец_лечения,
 sum(1) Всего,

 sum(case when Лекарственная>0 then K end ) ЛекарственнаяК,   --не нужно показывать
 sum(case when Лечение='только лекарственная' then K end ) Только_лекарственнаяК,

 sum(case when Лечение='только лекарственная' and nvl(Химио,0)>0 and nvl(Гормоно,0)=0 and nvl(Таргетное,0)=0 then K end ) В_лекарствн_химиоК,            --из только лекарственная
 sum(case when Лечение='только лекарственная' and nvl(Химио,0)=0 and nvl(Гормоно,0)>0 and nvl(Таргетное,0)=0 then K end ) В_лекарствн_гормоноК,        --из только лекарственная
 sum(case when Лечение='только лекарственная' and nvl(Химио,0)=0 and nvl(Гормоно,0)=0 and nvl(Таргетное,0)>0 then K end ) В_лекарствн_таргетК,       --из только лекарственная

 sum(case when Лечение='только лекарственная' and (nvl(sign(Химио),0)+nvl(sign(Гормоно),0)+nvl(sign(Таргетное),0) )>1 then K end ) СочетанноеК,  --(больше одного вида только лекарственного лечения)
 sum(case when Лечение='только лучевое' then K end ) ЛучевоеК,   --только
 sum(case when Лечение='только операция' then K end ) ОперацияК, --только
 sum(case when Лечение='операция и лучевое' then K end ) Операция_и_ЛучевоеК,   --оно же комбинированое лечение
 sum(case when Лечение='операция и лекарственная' then K end ) Операция_и_ЛекарствК,
 sum(case when Лечение='лекарственная и лучевое' then K end ) Лекарственная_и_ЛучевоеК,
 sum(case when Лечение='операция и лекарственная и лучевое' then K end ) Операция_Лекарств_ЛучК,
 sum(case when Лечение='операция и лекарственная и лучевое' or Лечение='лекарственная и лучевое' or Лечение='операция и лекарственная' then K end ) КомплексноеК,
 sum(case when Лечение='без специального' then K end ) Без_спец_леченияК,
 sum(K) Койко_дней
from
(
select
 crd.id ИД_канцер_документа,
 crd.client_sur_name Фамилия,
 crd.client_first_name Имя,
 crd.client_patr_name Отчестово,
 crd.client_birthday Дата_рождения,
 crd.home_address Адрес,
 stat.parep.GetTerritory(crd.home_address) Территория,
 stat.parep.GetTerritoryRegion(crd.home_address) Территория_Регион,
 dout.name Отделение,
 dout.id ИД_отделения,
 stat.parep.GetShortDepName(dout.id) Отделение_кратко,
 hc.receive_date Поступил,
 hc.outtake_date Выписан,
 stat.parep.GetBedDays(hc.id) K,
-- trunc(hcmout.create_date)-trunc(hcmin.create_date)+decode(dout.id,141,1,0) Койко_дней,
-- trunc(hc.outtake_date)-trunc(hc.receive_date)+decode(dout.id,141,1,0) Койко_дней_стацкарта,
-- cas.hospital_receive_date Поступил_канцер,
-- cas.hospital_discharge_death_date Выписан_канцер,
-- trunc(cas.hospital_discharge_death_date)-trunc(cas.hospital_receive_date)+decode(dout.id,141,1,0) Койко_дней_канцер,
 cdrug.cnt Лекарственная,
 csurgery.cnt Операций,
 crad.cnt Лучевое,
 cchemo.cnt Химио,
 chormo.cnt Гормоно,
 ctarget.cnt Таргетное,
 (case
   when csurgery.cnt is null and crad.cnt is null and cdrug.cnt is not null then 'только лекарственная'
   when csurgery.cnt is not null and crad.cnt is null and cdrug.cnt is null then 'только операция'
   when csurgery.cnt is null and crad.cnt is not null and cdrug.cnt is null then 'только лучевое'
   when csurgery.cnt is not null and crad.cnt is null and cdrug.cnt is not null then 'операция и лекарственная'
   when csurgery.cnt is not null and crad.cnt is not null and cdrug.cnt is null then 'операция и лучевое'
   when csurgery.cnt is null and crad.cnt is not null and cdrug.cnt is not null then 'лекарственная и лучевое'
   when csurgery.cnt is not null and crad.cnt is not null and cdrug.cnt is not null then 'операция и лекарственная и лучевое'
   else 'без специального'
  end) Лечение

from
 dd,hospital.cancer_summary cas
 join hospital.cancer_register_document crd on crd.id=cas.document_id
 join hospital.hospital_card hc on hc.id=cas.hospital_card_id
 --отделение поступления из стацкарты
 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id, hcmr.execute_worker_id
            from hospital.hospital_card_movement hcmr
            where hcmr.state='InDepartment'  --получаем дату занятия койки
                  and not exists( select 1 from hospital.hospital_card_movement hcmx
                                  where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='InDepartment' and hcmx.id<hcmr.id )
           ) hcmin on hcmin.hospital_card_id=hc.id
 --отделение выписывающее из стацкарты
 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id, hcmr.execute_worker_id
            from hospital.hospital_card_movement hcmr
            where hcmr.state='Discharged'  --получаем дату последнего нахождения в момент выписки hc
                  and not exists( select 1 from hospital.hospital_card_movement hcmx
                                  where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='Discharged' and hcmx.id>hcmr.id )
           ) hcmout on hcmout.hospital_card_id=hc.id
 left join hospital.department dout on dout.id=hcmout.department_id
 --хирургическое лечение
 left join (select csst.cancer_summary_id cancer_summary_id, count(csst.id) cnt, count(csst.postoperative_complication_id) cnt_surgery_postcomp, count(csst.intraoperative_complication_id) cnt_surgery_intrcomp
            from hospital.cancer_sum_surgery_treat csst
            group by csst.cancer_summary_id
           ) csurgeryc on csurgeryc.cancer_summary_id=cas.id
 --хирургическое лечение из стацкарты
 left join (select s.project_id project_id, count(s.id) cnt
            from hospital.surgery s
            where s.execute_state='Done'
            group by s.project_id
           ) csurgery on csurgery.project_id=hc.project_id
 --лучевое лечение
 left join (select csrt.cancer_summary_id cancer_summary_id, count(csrt.id) cnt
            from hospital.cancer_sum_rad_treat_meth csrt
            group by csrt.cancer_summary_id
           ) crad on crad.cancer_summary_id=cas.id
 --химиолечение
 left join (select csdt.cancer_summary_id cancer_summary_id, count(csdt.id) cnt
            from hospital.cancer_sum_drug_treat csdt
            where csdt.drug_treatment_type='ChemoTherapeutic'
            group by csdt.cancer_summary_id
            ) cchemo on cchemo.cancer_summary_id=cas.id
 --гормонолечение
 left join (select csdt.cancer_summary_id cancer_summary_id, count(csdt.id) cnt
            from hospital.cancer_sum_drug_treat csdt
            where csdt.drug_treatment_type='HormoneImmuneTherapeutic'
            group by csdt.cancer_summary_id
            ) chormo on chormo.cancer_summary_id=cas.id
 --таргетное лечение
 left join (select csdt.cancer_summary_id cancer_summary_id, count(csdt.id) cnt
            from hospital.cancer_sum_drug_treat csdt
            where csdt.drug_treatment_type='Targeted'
            group by csdt.cancer_summary_id
            ) ctarget on ctarget.cancer_summary_id=cas.id
 --лекарственное лечение
 left join (select csdt.cancer_summary_id cancer_summary_id, count(csdt.id) cnt
            from hospital.cancer_sum_drug_treat csdt
            group by csdt.cancer_summary_id
            ) cdrug on cdrug.cancer_summary_id=cas.id

where
--по дате выписки в стацкарте
 trunc(hc.outtake_date) between dd.dtf and dd.dtt
--только нормальные выписывающие отделения
 and dout.id in (select id from dd,table(stat.parep.GetListDep(dd.ds)))
-- and ((dout.id in (138,142,143,97,139,140,122,145,146,77,95) and 1=dd.DS)or(dout.id in (141,334) and 0=dd.DS))
--фильтр, только ЗНО
 and (dd.zno=0 or substr(stat.parep.GetProjectMKBCode(1,hc.project_id),1,3) between 'C00' and 'C99'  or substr(stat.parep.GetProjectMKBCode(1,hc.project_id),1,3) between 'D00' and 'D09' )
--фильтр, случай ОМС
 and (dd.oms=0 or stat.parep.GetProjectPayType(hc.project_id)='ОМС')

) x
group by
 x.ИД_отделения, x.Отделение_кратко
) z
order by
 stat.parep.GetDepOrder(ИД_отделения)



