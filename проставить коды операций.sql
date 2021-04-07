-- проставить коды операций в выписках БЗН с неуказанным федеральным кодом операции
--23 04 2019
--25 06 2019
/*select * from hospital.cancer_sum_surgery_treat x

where
 x.id in
*/
declare
 n number default 1;
begin
  dbms_output.put_line('Проставляем в канцер-выписках коды операций по справочнику соответствия ЭМК и госпитального регистра, '||to_char(sysdate,'dd.mm.yyyy'));  
  for curs in
(
with dd as (select to_date('26.12.2019','dd.mm.yyyy') dtf, to_date('25.12.2020','dd.mm.yyyy') dtt from dual)
select
 cas.id ИД_выписки, 
 crd.id ИД_документа,
 csst.id ИД_хир,
 stat.parep.GetFIOClient(cl.id) Пациент,
 to_char(cl.birthday,'dd.mm.yyyy') Дата_рождения,
 trunc(hc.receive_date) Поступил,
 trunc(hc.outtake_date) Выписан,
 stat.parep.GetShortDepname(stat.parep.GetOuttakeDepID(hc.id)) Отделение,
 stat.parep.GetShortFIOWorker(p.worker_id) Врач,
 stat.parep.GetProjectMKBCode(1,p.id) Диагноз,
 st.code Код_ЭМК,
 st.name Хир_ЭМК,
 bi.id ИД_хир_фед,
 bi.code Код_фед,
 bi.name Хир_фед
from
 dd, table(stat.parep.GetListDep) dep, table(stat.parep.GetListBedDischargedPeriod(dd.dtf,dd.dtt,dep.id)) x, 
 hospital.client cl, hospital.project p, hospital.hospital_card hc
 join hospital.cancer_summary cas on cas.hospital_card_id=hc.id
 join hospital.cancer_register_document crd on crd.id=cas.document_id
 join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
 join hospital.surgery s on s.id=csst.surgery_id
 join hospital.service_type st on st.id=s.service_type_id
 left join (select cb.service_type, sr.id, sr.code, sr.name
              from hospital.cancer_bind_reg_surgery cb, hospital.cancer_surgery_type sr 
             where sr.id=cb.surgery_type --and cb.service_type=s.service_type_id
                   and not exists(select 1 from hospital.cancer_bind_reg_surgery cb1 where cb1.service_type=cb.service_type and cb.surgery_type is not null and cb1.id>cb.id) 
           ) bi on bi.service_type=st.id
 
where 
 hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id 
 --только отправленые в госпитальный
 and exists (select 1 from hospital.cancer_document_operation cdo where cdo.document_id=crd.id and cdo.operation='SendToHospitalRegister')
 --только без кода хир операции
 and csst.surgery_type_id is null and csst.surgery_id is not null
) loop
         dbms_output.put_line(to_char(n,'00')||' '||curs.пациент||' '||curs.дата_рождения||' '||curs.диагноз||' csst.id='||to_char(curs.ИД_хир)||' '||curs.Код_ЭМК||' '||curs.Хир_ЭМК||' = '||to_char(curs.ИД_хир_фед)||' '||curs.Код_фед||' '||curs.Хир_фед);
         update hospital.cancer_sum_surgery_treat u set u.surgery_type_id=curs.ИД_хир_фед where u.id=curs.ИД_хир;
  n:=n+1;
end loop; 
end;
