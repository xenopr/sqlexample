--лист движения больных за период по всем стационарам
--для сверки форм 007 и 016
--цифры точно те, что в качественных показателях, иных отчетов
--В HospitalReport
--53 сек на квартал
--протасов 10 08 2018
--14 08 2018 nvl для excel
--15 08 2018 Контролька
--28 12 2018 еще поля, ДС радио
--18 01 2019  нетрудоспособные неверно считались
--15 02 2019 поле - из занятых на утро находятся в реанимации
--в FReport
--05 11 2019 getlistdep
--13 12 2019 множественность осложнений

--with dd as (select trunc(:DTF) dtf, trunc(:DTT) dtt from dual),
with dd as (select to_date('26.11.2019','dd.mm.yyyy') dtf, to_date('30.11.2019','dd.mm.yyyy') dtt from dual),
     Dep as (select * from table(stat.parep.GetListDep) )

select
 dd.dtf Период_С,
 dd.dtt Период_по,
-- Dep.id ИД_отделения,
 decode(dep.dayhospital,'Дневной стационар',1,0) ДС,
 decode(dep.dayhospital,'Круглосуточный стационар',1,0) КР,
 stat.parep.GetDepOrder(dep.id) Порядок,
 stat.parep.GetDepname(Dep.id) Отделение,
 stat.parep.GetShortDepname(Dep.id) Отделение_кратко,
 round(stat.parep.GetPlanBeds(Dep.id,dd.dtf,dd.dtt)) Коек_по_приказу,
 round(stat.parep.GetPlanBedDays(Dep.id,dd.dtf,dd.dtt)) План_койкодней,
 nvl(cntbusy.cnt,0) Занято_на_утро,   --в качественных показателях для Дневного стационара прибавляем количество выписанных
 (nvl(cntbusy.cnt,0)-nvl(cntbusy95.cnt,0)) Занято_в_реанимации,
 nvl(cntbusy.cnt14,0) Занято_возрастомдо14лет,
 nvl(cntbusy.cnt18,0) Занято_возрастомдо18лет,
 nvl(cntbusy.cntold,0) Занято_нетрудоспособными,
 nvl(cntrec.cnt,0) Поступило,
 nvl(cntrec.cnt14,0) Поступило_возрастомдо14лет,
 nvl(cntrec.cnt18,0) Поступило_возрастомдо18лет,
 nvl(cntrec.cntold,0) Поступило_нетрудоспособных,
 nvl(cntrec.cntvillage,0) Поступило_сельских,
 nvl(cntrec.cnttyumen,0) Поступило_тюменских,
-- (select count(hospital_card_id) cnt from table(stat.parep.GetListBedInPeriod(dd.dtf,dd.dtt,Dep.ID)) ) Переведено_в_,    --переведено из других отделений
-- (select count(hospital_card_id) cnt from table(stat.parep.GetListBedOutPeriod(dd.dtf,dd.dtt,Dep.ID)) ) Переведено_из_,  --переведено в другие отделения
 nvl(cntin.cnt,0) Переведено_в,    --переведено из других отделений
 nvl(cntou.cnt,0) Переведено_из,  --переведено в другие отделения
 nvl(cntout.cnt,0) Выписано,
 nvl(cntout.cntnotdead,0) Выписано_без_умерших,
 nvl(cntout.cntdead,0) Выписано_умерших,
 nvl(cntout.cntdeadold,0) Выписано_умерших_нетрудо,
 nvl(cntout.cntdead18,0) Выписано_умерших_до18,
 nvl(cntout.cnt14,0) Выписано_возрастомдо14лет,
 nvl(cntout.cnt18,0) Выписано_возрастомдо18лет,
 nvl(cntout.cntold,0) Выписано_нетрудоспособных,
 nvl(cntout.cntvillage,0) Выписано_сельских,
 nvl(cntout.cnttyumen,0) Выписано_тюменских,
 nvl(cntout.cntdisZNO,0) Выписано_с_ЗНО,
 nvl(cntout.cntdisDNO,0) Выписано_с_ДНО,
 nvl(cntout.cntdisNNO,0) Выписано_неопухолевых,
 nvl(cntout.sumbeddays,0) Койкодней_у_выписанных,
 nvl(cntout.sumbeddaysold,0) Койкодней_у_выписанных_нетрудо,
 nvl(cntout.sumbeddays18,0) Койкодней_у_выписанных_до18,
 nvl(cntbusy1.cnt,0) Занято_на_вечер,
 nvl(cntsurg.cnt,0) Оперированных_из_выписанных,
 nvl(cntsurg.cnt18,0) Оперированных_до18лет,
 nvl(cntsurg.cntold,0) Оперированных_нетрудо,
 nvl(cntsurg.cntdead,0) Оперированных_умерло,
 nvl(cntsurg.cnt18dead,0) Оперированных_умерло_до18лет,
 nvl(cntsurg.cntolddead,0) Оперированных_умерло_нетрудо,
 nvl(round(cntsurg.avgbedday,1),0) Среднийкойкодень_до_операции,
 nvl(cntsurg.cntoutdep,0) Оперированных_др_отделений,
 nvl(cntsurg.sumcomplic,0) Оперированных_с_осложнениями,
 nvl(cntbusy.cnt,0)+nvl(cntrec.cnt,0)+ nvl(cntin.cnt,0)- nvl(cntou.cnt,0)-nvl(cntout.cnt,0)-nvl(cntbusy1.cnt,0) Контролька
from
 dd,
 dep
 left join (select depx.id, count(x.hospital_card_id) cnt
              from dd, dep depx, table(stat.parep.GetListBedInPeriod(dd.dtf,dd.dtt,depx.id)) x
          group by depx.id
           ) cntin on cntin.id=dep.id
 left join (select depx.id, count(x.hospital_card_id) cnt
              from dd, dep depx, table(stat.parep.GetListBedOutPeriod(dd.dtf,dd.dtt,depx.id)) x
          group by depx.id
           ) cntou on cntou.id=dep.id
 left join (select depx.id, count(x.hospital_card_id) cnt,
                            count(case when trunc(months_between(hc.receive_date,cl.birthday)/12)<14 then 1 else null end) cnt14,
                            count(case when trunc(months_between(hc.receive_date,cl.birthday)/12)<18 then 1 else null end) cnt18,
                            count(case when stat.parep.GetClientIsPensioner(cl.id,hc.receive_date)=1 then 1 else null end) cntold
              from dd, dep depx, table(stat.parep.GetListBedBusyPeriod(dd.dtf,dd.dtt,depx.id)) x, hospital.hospital_card hc, hospital.project p, hospital.client cl
             where hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id
             group by depx.id
           )  cntbusy on cntbusy.id=dep.id    --сумма количества стационарных карт пациентов находящихся в отделении на утро каждого дня указанного периода
 left join (select depx.id, count(x.hospital_card_id) cnt
              from dd, dep depx, table(stat.parep.GetListBedBusyPeriod95(dd.dtf,dd.dtt,depx.id)) x, hospital.hospital_card hc, hospital.project p, hospital.client cl
             where hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id
             group by depx.id
           )  cntbusy95 on cntbusy95.id=dep.id    --сумма количества стационарных карт пациентов из отделения с учётом реанимации на утро каждого дня указанного периода
 left join (select depx.id, count(x.hospital_card_id) cnt,
                            count(case when trunc(months_between(hc.receive_date,cl.birthday)/12)<14 then 1 else null end) cnt14,
                            count(case when trunc(months_between(hc.receive_date,cl.birthday)/12)<18 then 1 else null end) cnt18,
                            count(case when stat.parep.GetClientIsPensioner(cl.id,hc.receive_date)=1 then 1 else null end) cntold,
                            count(case when stat.parep.GetClientIsCity(cl.id)='Village' then 1 else null end) cntvillage,
                            count(case when stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)) in ('   Тюмень','  Юг Тюменской области') then 1 else null end) cnttyumen
              from dd, dep depx, table(stat.parep.GetListBedRecievedPeriod(dd.dtf,dd.dtt,depx.id)) x, hospital.hospital_card hc, hospital.project p, hospital.client cl
             where hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id
             group by depx.id
           )  cntrec on cntrec.id=dep.id      --сумма количества стационарных карт пациентов поступивших в отделение в каждый день указанного периода
 left join (select depx.id, count(x.hospital_card_id) cnt,
                            count(case when p.project_result_type2_id not in (-34,-25) then 1 else null end) cntnotdead,
                            count(case when p.project_result_type2_id in (-34,-25) then 1 else null end) cntdead,
                            count(case when (stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1)
                                             and p.project_result_type2_id in (-34,-25) then 1 else null end) cntdeadold,
                            count(case when trunc(months_between(hc.outtake_date,cl.birthday)/12)<18
                                             and p.project_result_type2_id in (-34,-25) then 1 else null end) cntdead18,
                            count(case when trunc(months_between(hc.outtake_date,cl.birthday)/12)<14 then 1 else null end) cnt14,
                            count(case when trunc(months_between(hc.outtake_date,cl.birthday)/12)<18 then 1 else null end) cnt18,
                            count(case when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 1 else null end) cntold,
                            count(case when stat.parep.GetClientIsCity(cl.id)='Village' then 1 else null end) cntvillage,
                            count(case when stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)) in ('   Тюмень','  Юг Тюменской области') then 1 else null end) cnttyumen,
                            count(case when (substr(mkbfi.code,1,1)='C' or substr(mkbfi.code,1,2)='D0') then 1 else null end ) cntdisZNO,
                            count(case when (substr(mkbfi.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkbfi.code,1,3)<>'D86') then 1 else null end ) cntdisDNO,
                            count(case when not(substr(mkbfi.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkbfi.code,1,3)<>'D86')and not(substr(mkbfi.code,1,1)='C' or substr(mkbfi.code,1,2)='D0') then 1 else null end ) cntdisNNO,
                            sum(stat.parep.GetBedDays(hc.id)) sumbeddays,
                            sum(case when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then stat.parep.GetBedDays(hc.id) else 0 end) sumbeddaysold,
                            sum(case when trunc(months_between(hc.outtake_date,cl.birthday)/12)<18 then stat.parep.GetBedDays(hc.id) else 0 end) sumbeddays18
              from dd, dep depx, table(stat.parep.GetListBedDischargedPeriod(dd.dtf,dd.dtt,depx.id)) x, hospital.hospital_card hc,
                   hospital.project p, hospital.client cl, hospital.diagnosis di, hospital.mkb mkbfi
             where hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id and di.id=p.main_diagnosis_id and mkbfi.id=di.mkb10_id
             group by depx.id
           )  cntout on cntout.id=dep.id      --сумма количества стационарных карт пациентов выписанных из отделения в каждый день указанного периода
 left join (select depx.id, count(x.hospital_card_id) cnt,
                            count(case when stat.parep.GetClientIsCity(cl.id)='Village' then 1 else null end) cntvillage
              from dd, dep depx, table(stat.parep.GetListBedBusyPeriod(dd.dtf+1,dd.dtt+1,depx.id)) x, hospital.hospital_card hc, hospital.project p, hospital.client cl
             where hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id
             group by depx.id
           )  cntbusy1 on cntbusy1.id=dep.id  --сумма количества стационарных карт пациентов находящихся в отделении на вечер каждого дня указанного периода что равно количеству на утро следующего дня
 left join (select depx.id, count(x.surgery_id) cnt,
                            count(case when p.project_result_type2_id in (-34,-25) then 1 else null end) cntdead,
                            count(case when trunc(months_between(hc.outtake_date,cl.birthday)/12)<18 then 1 else null end) cnt18,
                            count(case when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 1 else null end) cntold,
                            count(case when p.project_result_type2_id in (-34,-25) and trunc(months_between(hc.outtake_date,cl.birthday)/12)<18 then 1 else null end) cnt18dead,
                            count(case when p.project_result_type2_id in (-34,-25) and stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 1 else null end) cntolddead,
                            avg(trunc(s.start_date)-trunc(hc.receive_date)) avgbedday,
                            count(case when stat.parep.GetOuttakeDepID(x.hospital_card_id)<>depx.ID then 1 else null end) cntoutdep,
                            sum((select count(csc.complication_id)   --число осложнений, как и в качественных, множественность осложнений
                                   from hospital.cancer_summary cas, hospital.cancer_sum_surgery_treat csst, hospital.cancer_sum_surgery_compl csc
                                  where cas.hospital_card_id=x.hospital_card_id and csst.cancer_summary_id=cas.id and csc.cancer_summary_surgery_id=csst.id and csc.type='Postoperative')
                                ) sumcomplic                            
/*                            sum((select count(surcop1.id)
                                  from hospital.cancer_summary cas
                                       join hospital.cancer_sum_surgery_treat csst1 on csst1.cancer_summary_id=cas.id               --из канцер-выписки все осложнения по всем операциям
                                       join hospital.surgery_complication surcop1 on surcop1.id=csst1.postoperative_complication_id --постоперац осложн
                                 where cas.hospital_card_id=x.hospital_card_id)
                                ) sumcomplic*/
              from dd, dep depx, table(stat.parep.GetListSurgeryPeriod(dd.dtf,dd.dtt,depx.ID)) x,
                   hospital.project p, hospital.hospital_card hc, hospital.client cl, hospital.surgery s
             where p.id=x.project_id and hc.id=x.hospital_card_id and s.id=x.surgery_id and cl.id=p.client_id
             group by depx.id
            ) cntsurg on cntsurg.id=dep.id    --количество оперированных из выписанных в указанном периоде, отнесенных к указанному отделению по правилам МКМЦ

order by
 Порядок




