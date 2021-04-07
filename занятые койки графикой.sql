--занятые койки графикой
--21 01 2021

with dd as (select dtf+level-1 d from (select to_date('26.12.2019','dd.mm.yyyy') dtf, to_date('25.01.2020','dd.mm.yyyy') dtt from dual) connect by dtf+level-1<=dtt),
     dep as (select * from table(stat.parep.GetListDep(1)))
     
--with dd as (select dtf+level-1 d from (select :DTF dtf, :DTT dtt from dual) connect by dtf+level-1<=dtt),
--     dep as (select * from table(stat.parep.GetListDep(:DS)))     

select
  stat.parep.GetDepname(dep.id) Отделение,
  dd.d Дата,
/*
  (select count(*) cnt from table(stat.parep.GetListBedBusy(dd.d,dep.id)))+
   (case when dep.dayhospital='Дневной стационар' then 
     (select count(*) from table(stat.parep.GetListBedDischarged(dd.d,dep.id)))
    else 0 end) Колво,
*/      
  (select count(*) cnt from table(stat.parep.GetListBedBusy(dd.d,dep.id))) Колво,
  (select count(*) from table(stat.parep.GetListBedDischarged(dd.d,dep.id))) Выбыло,
  (select sum(stat.parep.GetBedDays(z.hospital_card_id)) from table(stat.parep.GetListBedDischarged(dd.d,dep.id)) z) Койкодней
from
  dep, dd
order by
  stat.parep.GetDepOrder(dep.id), dd.d
    
