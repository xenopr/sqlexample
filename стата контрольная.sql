--стата контрольная
--протасов 06 07 2018
--215 секунд в 060718 за эти 19 периодов, 8 секунд на период
--30 07 2018 новый сервер и функцию колво поступивших ускорил
--23 секунды

--31 07 2018
--01 08 2018

--17 12 2018 новый ДС
--27 12 2018  2018 по 25.12 считать
--27 12 2018  2019 год с 26 по 25 считаем
--17 01 2019 пенсионеры неверно считались
--01 11 2019 getlistdep

with dd as (select pe.s, pe.o, pe.n, dep.nd, dep.id, add_months(to_date('26.'||pe.mf||'.'||yy.y,'dd.mm.yyyy'),-1) dtf, to_date('25.'||pe.mt||'.'||yy.y,'dd.mm.yyyy') dtt from
              --(select 2019 y from dual) yy,
              (select :YY y from dual) yy,
              (select dayhospital nd, id from table(stat.parep.GetListDep(:ds))) dep,
/*              (select 'Круглосуточный' nd, d.id from hospital.department d where d.id in (138,142,143,97,145,146,77,139,140,122)  and :DS<>0
               union all
               select 'Дневной' nd, 141 from dual where :DS<>1
               union all
               select 'Дневной' nd, 334 from dual where :DS<>1
              ) dep,*/
              (select 10 s, 1 o, 'январь' n, 1 mf, 1 mt from dual
               union all
               select 10 s, 2 o, 'февраль' n, 2 mf, 2 mt from dual
               union all
               select 10 s, 3 o, 'март' n, 3 mf, 3 mt from dual
               union all
               select 12 s, 4 o, '1й квартал' n, 1 mf, 3 mt from dual
               union all
               select 10 s, 5 o, 'апрель' n, 4 mf, 4 mt from dual
               union all
               select 10 s, 6 o, 'май' n, 5 mf, 5 mt from dual
               union all
               select 10 s, 7 o, 'июнь' n, 6 mf, 6 mt from dual
               union all
               select 12 s, 8 o, '2й квартал' n, 4 mf, 6 mt from dual
               union all
               select 14 s, 9 o, '1е полугодие' n, 1 mf, 6 mt from dual
               union all
               select 10 s, 10 o, 'июль' n, 7 mf, 7 mt from dual
               union all
               select 10 s, 11 o, 'август' n, 8 mf, 8 mt from dual
               union all
               select 10 s, 12 o, 'сентябрь' n, 9 mf, 9 mt from dual
               union all
               select 12 s, 13 o, '3й квартал' n, 7 mf, 9 mt from dual
               union all
               select 10 s, 14 o, 'октябрь' n, 10 mf, 10 mt from dual
               union all
               select 10 s, 15 o, 'ноябрь' n, 11 mf, 11 mt from dual
               union all
               select 10 s, 16 o, 'декабрь' n, 12 mf, 12 mt from dual
               union all
               select 12 s, 17 o, '4й квартал' n, 10 mf, 12 mt from dual
               union all
               select 14 s, 18 o, '2е полугодие' n, 7 mf, 12 mt from dual
               union all
               select 15 s, 19 o, 'год' n, 1 mf, 12 mt from dual
              ) pe
           )

select
 dd.s,
 dd.o,
 dd.n,
 dd.nd,
 cntrec.cnt Поступило,
 cntrec.cnt14 Поступило_возрастомдо14лет,
 cntrec.cnt18 Поступило_возрастомдо18лет,
 cntrec.cntold Поступило_нетрудоспособных,
 cntrec.cntvillage Поступило_сельских,
 cntrec.cnttyumen Поступило_тюменских,
 cntout.cnt Выписано,
 cntout.cntnotdead Выписано_без_умерших,
 cntout.cntdead Выписано_умерших,
 cntout.cntdead18 Выписано_умершихдо18лет,
 cntout.cnt14 Выписано_возрастомдо14лет,
 cntout.cnt18 Выписано_возрастомдо18лет,
 cntout.cntold Выписано_нетрудоспособных,
 cntout.cntvillage Выписано_сельских,
 cntout.cnttyumen Выписано_тюменских,
 cntout.cntdisZNO Выписано_с_ЗНО,
 cntout.cntdisDNO Выписано_с_ДНО,
 cntout.cntdisNNO Выписано_неопухолевых,
 cntout.sumbeddays Койкодней_у_выписанных,
 cntsurg.cnt Оперированных,
 cntsurg.cnt18 Оперированных_до18,
 cntsurg.cntdead Оперированных_умерло,
 cntsurg.cnt18dead Оперированных_умерлодо18,
 round(cntsurg.avgbedday,2) Среднийкойкодень_до_операции,
 cntsurg.sumcomplic Оперированных_с_осложнениями
from
 (select distinct dd.s, dd.o, dd.n, dd.nd from dd) dd
 left join (select dd.o, dd.nd, count(x.hospital_card_id) cnt,
                            count(case when trunc(months_between(hc.receive_date,cl.birthday)/12)<14 then 1 else null end) cnt14,
                            count(case when trunc(months_between(hc.receive_date,cl.birthday)/12)<18 then 1 else null end) cnt18,
                            count(case when stat.parep.GetClientIsPensioner(cl.id,receive_date)=1 then 1 else null end) cntold,
                            count(case when stat.parep.GetClientIsCity(cl.id)='Village' then 1 else null end) cntvillage,
                            count(case when stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)) in ('   Тюмень','  Юг Тюменской области') then 1 else null end) cnttyumen
              from dd, table(stat.parep.GetListBedRecievedPeriod(dd.dtf,dd.dtt,dd.id)) x, hospital.hospital_card hc, hospital.project p, hospital.client cl
             where hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id
             group by dd.o, dd.nd
           )  cntrec on cntrec.nd=dd.nd and cntrec.o=dd.o      --сумма количества стационарных карт пациентов поступивших в отделение в каждый день указанного периода
 left join (select dd.o, dd.nd, count(x.hospital_card_id) cnt,
                            count(case when p.project_result_type2_id not in (-34,-25) then 1 else null end) cntnotdead,
                            count(case when p.project_result_type2_id in (-34,-25) then 1 else null end) cntdead,
                            count(case when p.project_result_type2_id in (-34,-25) and
                                            trunc(months_between(hc.outtake_date,cl.birthday)/12)<18 then 1 else null end) cntdead18,
                            count(case when trunc(months_between(hc.outtake_date,cl.birthday)/12)<14 then 1 else null end) cnt14,
                            count(case when trunc(months_between(hc.outtake_date,cl.birthday)/12)<18 then 1 else null end) cnt18,
                            count(case when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 1 else null end) cntold,
                            count(case when stat.parep.GetClientIsCity(cl.id)='Village' then 1 else null end) cntvillage,
                            count(case when stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)) in ('   Тюмень','  Юг Тюменской области') then 1 else null end) cnttyumen,
                            count(case when (substr(mkbfi.code,1,1)='C' or substr(mkbfi.code,1,2)='D0') then 1 else null end ) cntdisZNO,
                            count(case when (substr(mkbfi.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkbfi.code,1,3)<>'D86') then 1 else null end ) cntdisDNO,
                            count(case when not(substr(mkbfi.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkbfi.code,1,3)<>'D86')and not(substr(mkbfi.code,1,1)='C' or substr(mkbfi.code,1,2)='D0') then 1 else null end ) cntdisNNO,
                            sum(stat.parep.GetBedDays(hc.id)) sumbeddays
              from dd, table(stat.parep.GetListBedDischargedPeriod(dd.dtf,dd.dtt,dd.id)) x, hospital.hospital_card hc,
                   hospital.project p, hospital.client cl, hospital.diagnosis di, hospital.mkb mkbfi
             where hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id and di.id=p.main_diagnosis_id and mkbfi.id=di.mkb10_id
             group by dd.o, dd.nd
           )  cntout on cntout.o=dd.o and cntout.nd=dd.nd      --сумма количества стационарных карт пациентов выписанных из отделения в каждый день указанного периода
 left join (select dd.o, dd.nd, count(x.surgery_id) cnt,
                            count(case when p.project_result_type2_id in (-34,-25) then 1 else null end) cntdead,
                            count(case when trunc(months_between(hc.outtake_date,cl.birthday)/12)<18 then 1 else null end) cnt18,
                            count(case when p.project_result_type2_id in (-34,-25) and trunc(months_between(hc.outtake_date,cl.birthday)/12)<18 then 1 else null end) cnt18dead,
                            avg(trunc(s.start_date)-trunc(hc.receive_date)) avgbedday,
                            sum((select count(surcop1.id)
                                  from hospital.cancer_summary cas
                                       join hospital.cancer_sum_surgery_treat csst1 on csst1.cancer_summary_id=cas.id               --из канцер-выписки все осложнения по всем операциям
                                       join hospital.surgery_complication surcop1 on surcop1.id=csst1.postoperative_complication_id --постоперац осложн
                                 where cas.hospital_card_id=x.hospital_card_id)
                                ) sumcomplic
              from dd, table(stat.parep.GetListSurgeryPeriod(dd.dtf,dd.dtt,dd.id)) x,
                   hospital.project p, hospital.hospital_card hc, hospital.client cl, hospital.surgery s
             where p.id=x.project_id and hc.id=x.hospital_card_id and s.id=x.surgery_id and cl.id=p.client_id
             group by dd.o, dd.nd
            ) cntsurg on cntsurg.o=dd.o and cntsurg.nd=dd.nd    --количество оперированных из выписанных в указанном периоде, отнесенных к указанному отделению по правилам МКМЦ

order by
 dd.o, dd.nd desc
