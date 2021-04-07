--суммы для тфомс отображаемые в "Аналит: свод доходов и расходов по отделениям", "Аналит: Анализ реестров ОМС", "Подсистема реестры" 
--по годам и месяцам периодов сдачи
--протасов аа
--11 12 2019
--19 06 2020

--with y as (select :Y y from dual),
with y as (select 2018+level y from dual connect by level<=1),
     m as (select level as m from dual connect by level<=12)

select 
    y.y Год,
    m.m Месяц,
    --Аналит: свод доходов и расходов по отделениям
    a1.c1 Свод_доходов_колво,
    a1.s1 Свод_доходов_сумма,
    --Аналит: Анализ реестров ОМС
    a2.c2 Анализ_реестров_колво,
    a2.s2 Анализ_реестров_сумма,
    round(a2.s2-a1.s1) разность,
    --Подсистема реестры
    a3.c3 Подсистема_реестры_колво,
    a3.s3 Подсистема_реестры_сумма,
    a4.c4 Подсистема_реестры_колво2,
    a4.s4 Подсистема_реестры_сумма2,
    round(a2.s2-a4.s4) разность2
  from
    y,m
    outer apply (
      select count(*) c1, sum(rro.sumv) s1
        from hospital.refund_register_oms rro
       where rro.year=y and rro.month=m and rro.lostmoney=0
    ) a1
    outer apply (
      select sum(rao.service_count) c2, sum(rao.service_sum) s2
        from hospital.register_analysis_oms rao
             join hospital.register_analysis_oms_stage s on s.id=rao.stage_id
       where s.year=y and s.month=m and s.confirmed=1
    ) a2
    outer apply (
      select sum(nvl(u.kol_usl,1)) c3, sum(sl.sum_m) s3
        from registry_oms.sl sl
             join registry_oms.z_sl zsl on zsl.id = sl.z_sl_id
             join registry_oms.schet s on zsl.schet_id = s.id
             join registry_oms.head h on h.id=sl.head_id
             outer apply
               (select sum(u.kol_usl) as kol_usl from registry_oms.usl u 
                 where u.sl_id = sl.id and u.is_main = 1) u 
       where s.year=y and s.month=m and s.type<>'00' and sl.accepted_tfoms=1
    ) a3
    outer apply (
    select sum(nvl(u.kol_usl,1)) as c4, sum(sl.sum_m) as s4
      from registry_oms.sl sl
      join registry_oms.z_sl zsl on zsl.id = sl.z_sl_id
      join registry_oms.head h on zsl.head_id = h.id
        outer apply
         (select sum(u.kol_usl) as kol_usl from registry_oms.usl u 
         where u.sl_id = sl.id and u.is_main = 1) u 
      where extract(year from h.end_date) = y and extract(month from h.end_date) = m  and sl.accepted_tfoms = 1
    ) a4
order by
    y,m
