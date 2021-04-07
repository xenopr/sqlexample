--анализ выполнения и сдачи амбулаторных услуг
--по амбулаторным случаям
--для Чижов, Рябых
--03 11 2020
--05 11 2020
--только услуги выполненные в период с 21.12.2019 по 20.09.2020
--только с видом оплаты выполнения ОМС
--только кодами вида медвмешательства соответсвующим определенным кодам КСГ
--06 11 2020 связь между услугой и поданой услугой в тфомс по коду услуги и по дате выполнения
--09 11 2020 номера по порядку оконными функциями, установка связи между услугой и подачей услуги в тфомс по номеру по порядку, так как нет однозначной связи по s.id
--10 11 2020
--11 11 2020 есть случаи не только типа 2 - амбулаторны
--13 01 2020 поанализить ковиды, Чижов, Рябых. сдано меньше чем наделано
--18 01 2020 инфа всяка дополнительная, анализ 19965 ОМСных

with dd as (select to_date('20.12.2019','dd.mm.yyyy') dtf, to_date('20.12.2020','dd.mm.yyyy') dtt from dual),
     u as  (select '40111' c from dual union all
            select '40110' from dual union all
            select '40113' from dual union all
            select '40115' from dual union all
            select '40114' from dual 
           )
                     
select
        x."№ пп пациента",
        x."ИД пациента",
        x."Пациент",
        x."Дата рождения",
        x."№ пп случая",
        x."ИД случая",
        x."Вид_случая",
        x."Случай с",
        x."Случай по",
        x."№ пп услуги в случае",
--        x.w,
        x."Направившая организация",
        x."Услуга",
        x."ИД услуги",
        x."Код ЭМК",
        x."Код ВМЕ",  
        x."Код КСГ расчетный",
        x."Назначена", 
        x."Кем назначена",
        x."Выполнена",
        x."Кем",
        x."Отделение врача",
        ree.p "Найдено в периодах",
        ree.typ "Найдено в счетах типа",
        ree.shs "Найдено в счетах",
        ree.ksg "Найдено с ксг",
        ree.kol "Найдено услуг",
        ree.sumu "Сумма по найденым",
        ree.txtu "Найдено услуг подробно",
        rea.txt "Всё по случаю в ТФОМС",      --для контроля  Всё, что принято в ТФОМС по ИД случая
        rea.sums "Всего получено по случаю"   --для контроля        
--        (case when "№ пп услуги в случае"=1 or rea.txt is null then rea.txt else '--//--' end) "Всё по случаю в ТФОМС",      --для контроля
--        (case when "№ пп услуги в случае"=1 then rea.sums else null end) "Всего получено по случаю"   --для контроля
from
   (
      select
        dense_rank() over (order by stat.parep.GetFIOClient(cl.id),stat.parep.GetBirthDayClient(cl.id),cl.id) "№ пп пациента",
        cl.id "ИД пациента",
        stat.parep.GetFIOClient(cl.id) "Пациент",
        stat.parep.GetBirthDayClient(cl.id) "Дата рождения",
        dense_rank() over (order by stat.parep.GetFIOClient(cl.id),stat.parep.GetBirthDayClient(cl.id),cl.id, p.id) "№ пп случая",
        p.id "ИД случая",
        pt.name "Вид_случая",
        trunc(p.start_date) "Случай с",
        trunc(p.end_date) "Случай по",
        row_number() over (partition by p.id order by ro.operation_date, st.code2, s.id) "№ пп услуги в случае",
        row_number() over (partition by p.id, trunc(ro.operation_date), st.code2 order by ro.operation_date) w,  --окно поиска
        s.id "ИД услуги",
        o.name "Направившая организация",
        st.name "Услуга",
        st.code "Код ЭМК",
        st.code2 "Код ВМЕ",  
        (select u.code_usl from REGISTRY_OMS.T003_V001 u where u.vid_vme=st.code2) "Код КСГ расчетный",
        stat.parep.GetServiceAppointDate(s.id) "Назначена",
        stat.parep.GetShortFIOWorker(stat.parep.GetServiceAppointWorker(s.id)) "Кем назначена",
        ro.operation_date "Выполнена",
        stat.parep.GetShortFIOWorker(w.id) "Кем",
        w.tfoms_code "Код врача",
        stat.parep.GetDepname(stat.parep.GetWorkerDepID(w.id)) "Отделение врача"
      from
        dd,hospital.service_operation ro
        join hospital.service s on s.id=ro.service_id
        join hospital.service_type st on st.id=s.service_type_id
        join hospital.project p on p.id=s.project_id
        join hospital.client cl on cl.id=p.client_id
        left join hospital.worker w on w.id=ro.worker_id
        left join hospital.project_type pt on pt.id=p.project_type_id
        left join hospital.direction dir on dir.id=s.direction_id
        left join hospital.organisation o on o.id=dir.organisation_id
      where
        trunc(ro.operation_date) between dd.dtf and dd.dtt
        and ro.operation_type_id=4  -- смотрим только события выполнения
        and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=10 and so1.id>ro.id) --нет отмены выполнения
        and not exists (select 1 from hospital.service_operation so2 where so2.service_id=ro.service_id and so2.operation_type_id=4 and so2.id>ro.id)  --только последнее событие выполнения смотрим
        and exists (select pt.short_name t
                      from hospital.service_operation so
                           join hospital.client_certificate cc on cc.id=so.client_certificate_id
                           join hospital.client_certificate_type cct on cct.id=cc.certificate_type_id
                           join hospital.pay_type pt on pt.id=cct.pay_type_id
                     where so.operation_type_id=2 and so.service_id=s.id and pt.id=801)  --только оплаченые по ОМС
--        and p.project_type_id<>2 --только амбулаторные случай
        and st.code in (select u.c from u)  --только эти услуги интересуют
--        and (p.id between 1136375 and 1136385 or p.id in (1194847,1144750,1268867,1203405,1188322,1262443) )  --тестирование (4 одинаковых услуги выполнены в один день и одна услуга подана 3 раза в разных счетах)
        
  ) x
outer apply (
          select
--             listagg('№'||to_char(n)||' '||t, chr(13)) WITHIN GROUP(order by r.date_z_2, r.vid_vme) txtu,   
             listagg(t, chr(13)) WITHIN GROUP(order by r.date_z_2, r.vid_vme) txtu,   
             listagg(p, chr(13)) WITHIN GROUP(order by r.date_z_2, r.vid_vme) p, 
             listagg(typ, chr(13)) WITHIN GROUP(order by r.date_z_2, r.vid_vme) typ, 
             listagg(shs, chr(13)) WITHIN GROUP(order by r.date_z_2, r.vid_vme) shs, 
             listagg(code_usl, chr(13)) WITHIN GROUP(order by r.date_z_2, r.vid_vme) ksg, 
             sum(r.s) sumu,
             sum(r.kol) kol                                                    
            from
             (select
                 row_number() over (partition by sh.id order by zsl.date_z_2, sl.vid_vme) n,  
                 to_char(zsl.date_z_2,'dd.mm.yy')||' '||sl.code_usl||' '||sl.vid_vme||' '||t3.name||' на '||trim(to_char(zsl.sumv,'999999999990D00'))||' руб '||to_char(u.kol_usl)||'шт счет '||sh.nschet||' от '||to_char(sh.dschet,'dd.mm.yy') t,
                 to_char(sh.year,'9999')||to_char(sh.month,'900') p,
                 (case when sh.type in ('01','14') then 'База'
                       when sh.type in ('02','15') then 'Сверхбаза'
                       when sh.type in ('10','22') then 'Межтер'
                       when sh.type in ('03','23') then 'Высокотех'
                  else sh.type end) typ,
                 nvl(u.kol_usl,1) kol,
                 sh.nschet||' от '||to_char(sh.dschet,'dd.mm.yy') shs,
                 sl.code_usl,
                 sl.sum_m s,
                 zsl.id,
                 sl.vid_vme,
                 zsl.date_z_2
                from
                 dd,registry_oms.z_sl zsl
                 join registry_oms.schet sh on zsl.schet_id=sh.id 
                 join registry_oms.sl sl on sl.z_sl_id=zsl.id
                 join registry_oms.head h on h.id=sl.head_id
                 left join registry_oms.t003 t3 on sl.code_usl = t3.code and t3.year=sh.year
                 outer apply
                       (select sum(u.kol_usl) as kol_usl
                          from registry_oms.usl u 
                         where u.sl_id = sl.id and u.is_main = 1
                       ) u                  
                where
                 sh.type<>'00' and sl.accepted_tfoms=1   
                 and zsl.project_id="ИД случая" 
                 and sl.vid_vme="Код ВМЕ"
                 and zsl.date_z_2=trunc("Выполнена")    --по услуге подано в тфомс, связь по коду тфомс+дата   
              ) r
            where
              r.n=x.w   --связь также по порядковому номеру если в один день несколько одинаковых услуг
   ) ree --что подано в тфомс по данной услуге
outer apply (select 
                 count(zsl.id) cnt,
                 sum(u.kol_usl) cntu,
                 sum(sl.sum_m) sums,
                 listagg(to_char(zsl.date_z_2,'dd.mm.yy')||' '||sl.code_usl||' '||sl.vid_vme||' '||t3.name||' на '||trim(to_char(zsl.sumv,'999999999990D00'))||' руб '||to_char(u.kol_usl)||'шт счет '||sh.nschet||' от '||to_char(sh.dschet,'dd.mm.yy')
                         , chr(13)) WITHIN GROUP(order by zsl.date_z_2, sl.vid_vme) txt                                                                     
                from
                 dd,registry_oms.z_sl zsl
                 join registry_oms.schet sh on zsl.schet_id=sh.id 
                 join registry_oms.sl sl on sl.z_sl_id=zsl.id
                 join registry_oms.head h on h.id=sl.head_id
                 left join registry_oms.t003 t3 on sl.code_usl = t3.code and t3.year=sh.year
                 outer apply
                       (select sum(u.kol_usl) as kol_usl
                          from registry_oms.usl u 
                         where u.sl_id = sl.id and u.is_main = 1
                       ) u   
                where
                 sh.type<>'00' and sl.accepted_tfoms=1   
                 and zsl.project_id="ИД случая"
               ) rea  --всё что когда либо подано по случаю в тфомс   
order by 
  "Пациент", "Дата рождения", "ИД пациента", "ИД случая", "Выполнена", "Код ВМЕ", "ИД услуги"       
 
