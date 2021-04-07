--повторные приёмы
--для Рябых, Наумов
--07 12 2020
--список 1х приёмов в амбулаторных случаях имеющих более одного выполненного приёма одним и тем же врачом, т.е. случаи с повторными приёмами
--признак наличие назначения на приём к себе же этим же врачом в момент выполнения первого приёма и выполнен, т.е. был повторный приём
--08 12 2020 определение первого приема в случае по дате выполнения, учет наличия приёмов одновременных

--05 02 2021 тоже самое, за 2020 год. было с 0109 по 3011 - 5603 10 декабря, сейчас 6484

with dd as (select to_date('01.01.2020','dd.mm.yyyy') dtf, to_date('31.12.2020','dd.mm.yyyy') dtt from dual)
    
select
     p.id ИД_случая,
     p.start_date Случай_начат,
     p.end_date Случай_кончен,
     stat.parep.GetShortFIOWorker(p.worker_id) Врач_случая,
--     w.id ИД_врача,
     stat.parep.GetShortFIOWorker(w.id) Врач_приёма,
     stat.parep.GetServiceExecDate(s.id) Выполнил_приём,
--     st.name Услуга,
     stat.parep.GetFIOClient(cl.id) Пациент,
     stat.parep.GetBirthDayClient(cl.id) Дата_рождения,
     (case when exists (
        select 1  --в момент выполнения первого приёма врач назначил приём к самому себе и выполнил его
          from  hospital.service s1
                join hospital.service_type st1 on st1.id=s1.service_type_id and substr(st1.code,1,3)='110'
         where s1.project_id=p.id and s1.id<>s.id
               and stat.parep.GetServiceAppointDate(s1.id)=stat.parep.GetServiceExecDate(s.id)
               and stat.parep.GetServiceExecWorker(s1.id)=w.id
                        ) 
      then 'да' else 'нет' end) Назначил_повторный_приём
    
      ,s.id,
      (select min(stat.parep.GetServiceExecDate(s1.id))   --в случае есть выполненный другим врачом приём раньше
                  from hospital.service s1
                       join hospital.service_type st1 on st1.id=s1.service_type_id and substr(st1.code,1,3)='110'
                 where s1.project_id=p.id and s1.id<>s.id 
                       and stat.parep.GetServiceExecDate(s1.id)<stat.parep.GetServiceExecDate(s.id)
                       and stat.parep.GetServiceExecWorker(s1.id)<>w.id
       ) Приём_первее,
      (select min(stat.parep.GetServiceExecDate(s1.id))   --в случае есть выполненные этим же врачом приём раньше
                  from hospital.service s1
                       join hospital.service_type st1 on st1.id=s1.service_type_id and substr(st1.code,1,3)='110'
                 where s1.project_id=p.id and s1.id<>s.id 
                       and stat.parep.GetServiceExecDate(s1.id)<stat.parep.GetServiceExecDate(s.id)
                       and stat.parep.GetServiceExecWorker(s1.id)=w.id
       ) Приём_ранее,
      (select min(stat.parep.GetServiceExecDate(s1.id))   --выполненный этим же врачом приём после
                  from hospital.service s1
                       join hospital.service_type st1 on st1.id=s1.service_type_id and substr(st1.code,1,3)='110'
                 where s1.project_id=p.id and s1.id<>s.id 
                       and stat.parep.GetServiceExecDate(s1.id)>=stat.parep.GetServiceExecDate(s.id)
                       and stat.parep.GetServiceExecWorker(s1.id)=w.id
       ) Приём_после,
      (select min(stat.parep.GetServiceExecDate(s1.id))   --более одного приёма в одно время одним и тем же врачом
                  from hospital.service s1
                       join hospital.service_type st1 on st1.id=s1.service_type_id and substr(st1.code,1,3)='110'
                 where s1.project_id=p.id and s1.id<>s.id 
                       and stat.parep.GetServiceExecDate(s1.id)=stat.parep.GetServiceExecDate(s.id)
                       and stat.parep.GetServiceExecWorker(s1.id)=w.id
       ) Приём_одновременный       
/*      (case when exists (  --не нужно, Рябых
        select 1  --есть внесение в расписание около даты выполнения этим же врачом к самому себе этого же пациента
          from hospital.event_operation eo
               join hospital.event ev on ev.id=eo.event_id
         where eo.operation_type_id in (4,5,6,8,9) and eo.worker_id=w.id and ev.client_id=cl.id and ev.worker_id=w.id and
               eo.operation_date between stat.parep.GetServiceExecDate(s.id)-1/24 and stat.parep.GetServiceExecDate(s.id)+1/24
                        )
      then 'да' else 'нет' end) Внёс_в_расписание_приём
*/        
 from 
    dd, hospital.project p
    join hospital.client cl on cl.id=p.client_id        
    join hospital.service s on s.project_id=p.id 
    join hospital.service_type st on st.id=s.service_type_id and substr(st.code,1,3)='110'  --только приёмы анализим
    join hospital.worker w on w.id=stat.parep.GetServiceExecWorker(s.id)
where   
    p.project_type_id<>2 and  --только амбулаторные
    trunc(p.start_date) between dd.dtf and dd.dtt  --начат в указаный период
    and not exists (select 1  --приём самый первый в случае по времени выполнения этим же врачом
                      from hospital.service s1
                           join hospital.service_type st1 on st1.id=s1.service_type_id and substr(st1.code,1,3)='110'
                     where s1.project_id=p.id and s1.id<>s.id 
                           and stat.parep.GetServiceExecDate(s1.id)<stat.parep.GetServiceExecDate(s.id)
                           and stat.parep.GetServiceExecWorker(s1.id)=w.id                   
    )
    and not exists (select 1  --для одинаковых по времени выбираем первый по id случая
                      from hospital.service s1
                           join hospital.service_type st1 on st1.id=s1.service_type_id and substr(st1.code,1,3)='110'
                     where s1.project_id=p.id and s1.id<s.id 
                           and stat.parep.GetServiceExecDate(s1.id)=stat.parep.GetServiceExecDate(s.id)
                           and stat.parep.GetServiceExecWorker(s1.id)=w.id                   
    )    
    and exists (select 1   --в случае есть выполненные этим же врачом другие приёмы
                  from hospital.service s1
                       join hospital.service_type st1 on st1.id=s1.service_type_id and substr(st1.code,1,3)='110'
                 where s1.project_id=p.id and s1.id<>s.id 
                       and stat.parep.GetServiceExecDate(s1.id) is not null 
                       and stat.parep.GetServiceExecWorker(s1.id)=w.id
                )       
    and w.sur_name<>'Тестовая'                
order by
   Случай_начат, s.id                       
 
