--Данные по паллиативной помощи
--в FReport, для заполнения ежеквартального отчета в МИАЦ
--ТЗ от Подгальняя
--считаем пациентов из госпитализаций в указанный период
--только с IV клинической группой в выписках
--02 10 2019 Гайсин - считаем госпитализации, не пациентов,  считаем из ДС как амбулаторные и из круглосуточного отдельно
--03 10 2019 бага - первичный пациент, правильно - первичная госпитализация

--with dd as (select to_date('26.12.2018','dd.mm.yyyy') dtf, to_date('25.09.2019','dd.mm.yyyy') dtt from dual),
with dd as (select :DTF dtf, :DTT dtt from dual),
     colu as (select 'Всего'          gru, 'всего'   nam, 1 nu, 2 stacionar, 0 age  from dual
              union all
              select 'Всего'          gru, 'нетруд' nam, 2 nu, 2 stacionar, 1 age  from dual
              union all
              select 'Всего'          gru, 'детей'   nam, 3 nu, 2 stacionar, 2 age  from dual
              union all
              select 'из них в амбулаторных условиях' gru, 'всего'   nam, 4 nu, 1 stacionar, 0 age  from dual
              union all
              select 'из них в амбулаторных условиях' gru, 'нетруд' nam, 5 nu, 1 stacionar, 1 age  from dual
              union all
              select 'из них в амбулаторных условиях' gru, 'детей'   nam, 6 nu, 1 stacionar, 2 age  from dual
                            union all
              select 'из них в условиях круглосуточного стационара' gru, 'всего'   nam, 10 nu, 0 stacionar, 0 age  from dual
              union all
              select 'из них в условиях круглосуточного стационара' gru, 'нетруд' nam, 11 nu, 0 stacionar, 1 age  from dual
              union all
              select 'из них в условиях круглосуточного стационара' gru, 'детей'   nam, 12 nu, 0 stacionar, 2 age  from dual
             )

select
 gru Имя_группа,
 nam Имя_колонки,
 nu Номер_колонки,
 count(ИД_стацкарты) Всего_госпитализаций,
 count(case when Первичный=1 then ИД_стацкарты end) Первичных,
 count(case when Умер=1 then ИД_стацкарты end) Умерших,
 count(case when instr(Сильнодействующие,'Tramadolum')>0 then ИД_стацкарты end) Трамадол,
 count(case when Наркотические is not null then ИД_стацкарты end) Наркотик
from
colu
outer apply (
select
 dd.dtf С,
 dd.dtt По,
 cl.id ИД_пациента,
 hc.id ИД_стацкарты,
 stat.parep.GetFIOClient(cl.id) Пациент,
 cl.birthday Дата_рождения,
 cl.sex Пол,
 stat.parep.GetClientAge(cl.id,hc.outtake_date) Возраст,
 (case when stat.parep.GetClientAge(cl.id,hc.outtake_date)<18 then 1 else 0 end) Ребенок,
 stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date) Нетрудоспособный,
-- stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id)) Проживает,
 (case when p.project_result_type2_id in (-34,-25) then 1 else 0 end) Умер,
 (case when exists(select 1 from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state in ('Closed') and hc1.outtake_date<hc.outtake_date) then 0 else 1 end) Первичный,
-- (case when cl.id = (LAG(cl.id,1) over (order by stat.parep.GetFIOClient(cl.id),cl.birthday,hc.outtake_date)) then 'Нет' else 'Да' end)  Первая_в_периоде,
 hc.num Стацкарта,
 trunc(hc.receive_date) Поступил,
 trunc(hc.outtake_date) Выписан,
 stat.parep.GetShortDepname(stat.parep.GetOuttakeDepID(hc.id)) Отделение,
 stat.parep.GetShortFIOWorker(p.worker_id) Врач,
 cas.id ИД_выписки,
 stat.parep.GetCancerHospitalizationResult(cas.hospitalization_resid_result) Результат_госпитализации,
 stat.parep.GetCancerTreatmentResult(cas.hosp_treat_result) Результат_лечения,
 stat.parep.GetCancerStage(cas.cancer_stage) Стадия,
 stat.parep.GetDrugsParus(hc.id,'НАРКОТИКИ') Наркотические,
 stat.parep.GetDrugsParus(hc.id,'СИЛЬНОДЕЙСТВУЮЩИЕ') Сильнодействующие
from
 dd, table(stat.parep.GetListDep(colu.stacionar)) dep, table(stat.parep.GetListBedDischargedPeriod(dd.dtf,dd.dtt,dep.id)) x,
 hospital.client cl, hospital.project p, hospital.hospital_card hc
 left join hospital.cancer_summary cas on cas.hospital_card_id=hc.id
 left join hospital.cancer_clinic_group cg on cg.id=cas.cancer_clinic_group_id
where
 hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id
 and cg.id=6  --только IV клиническая группа
 and (case when colu.age=0 then 1
           when colu.age=1 and stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 1
           when colu.age=2 and stat.parep.GetClientAge(cl.id,hc.outtake_date)<18 then 1
           else 0 end)=1
)
group by
 gru,
 nam,
 nu

order by
 nu

