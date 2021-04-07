--препараты (Гайсина)
--отобразить список пациентов у которых есть назначения препарата по части названия
--по дате назначения в указанный период, хоть раз выполненные
--либо по дате выбытия в указанный период
--в HospitalReport если не задаем дату - дата будет на сейчас вместе с временем
--отображение как в Журнал ВК №4
--05 03 2021 протасов аа
--на будущее, когда понадобится - включить

with dd as (select TO_DATE('04.03.2021', 'dd.mm.yyyy') dtf,   TO_DATE('05.03.2021', 'dd.mm.yyyy')+0.1 dtt,    
                   TO_DATE('01.02.2021', 'dd.mm.yyyy')+0.1 dtfp,   TO_DATE('01.02.2021', 'dd.mm.yyyy')+0.1 dttp from dual), 
     dr as (select '' drug from dual)
     
--with dd as (select :dtf dtf, :dtt dtt,                          
--                   :dtfp dtfp, :dttp dttp from dual), 
--     dr as (select :drug drug from dual)     

select
  (select '"'||drug||'" '||
          (case when dtf<>dtt or trunc(dtf)=dtf then 'назначен с '||to_char(dtf,'dd.mm.yy')||' по '||to_char(dtt,'dd.mm.yy') end)||
          (case when dtfp<>dttp or trunc(dtfp)=dtfp then 'выполнен и пациент выписан с '||to_char(dtfp,'dd.mm.yy')||' по '||to_char(dttp,'dd.mm.yy') end)||
          ' на '||to_char(sysdate,'dd.mm.yyyy hh24:mi:ss')
   from dd,dr) Ищем,
  stat.parep.GetFIOClient(cl.id) Пациент,
  stat.parep.GetBirthDayClient(cl.id) Дата_рождения,
  cl.sex Пол,
  stat.parep.GetClientAge(cl.id,nvl(hc.outtake_date,sysdate)) Возраст,
  trunc(stat.parep.GetReceiveDate(hc.id)) Поступил,
  to_char(stat.parep.GetOuttakeDate(hc.id),'dd.mm.yyyy') Выбыл,
  stat.parep.GetDepname(nvl(stat.parep.GetOuttakeDepID(hc.id),stat.parep.GetBusyDepID(hc.id))) Отделение,
  stat.parep.GetShortFIOWorker(p.worker_id) Лечащий_врач,
  stat.parep.GetProjectPayType(p.id) Вид_оплаты,
  hc.num Стацкарта,
  stat.parep.GetProjectMKBCode(1,p.id) Диагноз_основной,
  stat.parep.GetProjectMKBCode(2,p.id) Диагнозы_сопутсвующие,
  stat.parep.GetShortFIOWorker(x.worker_id) Назначил_препарат,
  x.prescribe_date Дата_назначения,
  stat.parep.GetCancerDrugTreatType(x.drug_treatment_type) Тип_назначения,
  x.name Найдено_название_ЭМК,
  x.parusmnn Найдено_название_МНН,
 (select 
         'по '||to_char(pd1.one_time_dose)||' '||pd1.one_time_dose_measurement_unit||', '||dum.name||
         ' '||to_char(pd1.repeatedly_by_day)||' раз в день '||to_char(pd1.duration_in_days)||' дней'
    from hospital.prescribed_drug pd1
         left join hospital.drug_use_form duf on duf.id=pd1.drug_use_form_id
         left join hospital.drug_use_method dum on dum.id=pd1.drug_use_method_id
   where pd1.id=x.id
  ) Назначение,                           --дозировка, доза на приём, способ введения, кратность приёма, длительность приёма
  decode(x.is_patient_drug,0,'Нет','Да') Препарат_пациента,
--  x.id,
  x.first_date Первое_выполнение,
  x.last_date Последнее_выполнение,
  x.cnt Выполнений,
  x.sum_dose Суммарная_доза,
  x.one_time_dose_measurement_unit Единица,
  x.aname Название_назначения,
  x.anote Комментарий_врача,
  x.astate Статус_назначения
from
  dd,
  (select 
     mr.project_id, 
     mr.worker_id,
     pd.prescribe_date,
     max(a.name) aname,
     max(a.note) anote,
     max(a.state) astate,
     ddd.name,
     ddd.parusmnn,
     min(atas.execute_date) first_date,
     max(atas.execute_date) last_date,
     count(atas.id) cnt,
     count(distinct atas.id) dcnt,
     count(a.id) acnt,
     sum(pd.one_time_dose) sum_dose,
     pd.is_patient_drug,
     pd.drug_treatment_type,
     pd.one_time_dose_measurement_unit,
     pd.id
    from
     dd,hospital.medical_record mr
     join hospital.appointment a on a.medical_record_id=mr.id 
     join hospital.drug_appointment da on da.appointment_id=a.id
     join hospital.prescribed_drug pd on pd.id=da.prescribed_drug_id
     join stat.mv_drug_description ddd on ddd.id=pd.drug_id
     join hospital.appointment_task atas on atas.appointment_id=a.id and atas.execute_worker_id is not null  --только с существующей задачей назначения (отображаемые в ЭМК) и только выполненные
    where
     exists(select 1 from dr 
             where dr.drug is null or upper(ddd.name) like upper('%'||dr.drug||'%') or upper(ddd.parusmnn) like upper('%'||dr.drug||'%'))  --ищем по вхождению названия в названии ЭМК либо в названии МНН
     and (trunc(pd.prescribe_date) between trunc(dd.dtf) and trunc(dd.dtt) or (dtf=dtt and trunc(dtf)<>dtf))   
    group by
     mr.project_id, mr.worker_id, pd.id, pd.prescribe_date, ddd.name, ddd.parusmnn, pd.is_patient_drug, pd.drug_treatment_type, pd.one_time_dose_measurement_unit
    
    union all
    
    select 
     a.project_id, 
     a.worker_id,
     ad.drugs_date,
     '' aname,
     '' anote,
     '' astate,
     ddd.name,
     ddd.parusmnn,
     min(ad.drugs_date) first_date,
     max(ad.drugs_date) last_date,
     count(ad.id) cnt,
     count(distinct ad.id) dcnt,
     count(a.id) acnt,
     sum(ad.dose) sum_dose,
     0 is_patient_drug,
     'Анестезия' drug_treatment_type,
     'мг ' one_time_dose_measurement_unit,
     null
    from
     dd, hospital.anesthesia a
     join hospital.anesthesia_drugs ad on ad.anesthesia_id=a.id
     join stat.mv_drug_description ddd on ddd.id=ad.drug_description_id
    where
     exists(select 1 from dr 
             where dr.drug is null or upper(ddd.name) like upper('%'||dr.drug||'%') or upper(ddd.parusmnn) like upper('%'||dr.drug||'%'))  --ищем по вхождению названия из списка в названии либо в МНН
     and (trunc(ad.drugs_date) between trunc(dd.dtf) and trunc(dd.dtt) or (dtf=dtt and trunc(dtf)<>dtf))
    group by
     a.project_id, a.worker_id, ad.id, ad.drugs_date, ddd.name, ddd.parusmnn
     
  ) x
  join hospital.project p on p.id=x.project_id
  join hospital.hospital_card hc on hc.project_id=p.id   
  join hospital.client cl on cl.id=p.client_id
where
  (trunc(hc.outtake_date) between trunc(dd.dtfp) and (dd.dttp) or (dtfp=dttp and trunc(dtfp)<>dtfp))
order by
  (case when dtf<>dtt or trunc(dtf)=dtf then x.prescribe_date else stat.parep.GetOuttakeDate(hc.id) end) desc, Пациент desc, Дата_рождения desc, x.id desc
