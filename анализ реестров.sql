--анализ реестров
--универсальный отчет
--18 11 2019 протасов аа
--21 11 2019
--25 11 2019  не сходятся цифры за старые периоды с аналитом... сходятся с ноября 2019
--19 05 2020
--25 06 2020 под FReport
--26 06 2020 вид реестра и помощи, совпадение с аналитом
--29 06 2020 периоды с по, вкл предъявленые

--01 09 2020 Первичный в периоде счета по алгоритму Аналит, пациентов по client_id, не id_pac
--06 11 2020 Отделение группа по аналит свод доходов, Отделение по аналиту испр.
--10 11 2020 Услуга периоде сдачи, Услуга подробно, Наличие медвмешательства, Перечень медвмешательств

/*
with dd as (select :Y1+2019 y1, :Y2+2019 y2, :M1+1 m1, :M2+1 m2, :Acce acce,
             :VGROUP1 Group1, :VGROUP2 Group2, :VGROUP3 Group3, :VGROUP4 Group4, :VGROUP5 Group5, :VGROUP6 Group6,
             :FL1 fl1, :FL2 fl2, :FL3 fl3, :FL4 fl4, :FL5 fl5, :FL6 fl6,
             :fn1 fn1, :fn2 fn2, :fn3 fn3, :fn4 fn4, :fn5 fn5, :fn6 fn6
            from dual)
*/
with dd as (
            select 2020 y1, 2020 y2, 1 m1, 9 m2, 0 acce,
             '' Group1, 'Счет вид реестра' Group2, 'Услуга код' Group3, 'Медвмешательство присутсвует в случае эмк' Group4, 'Услуга подробно' Group5, 'Перечень выполненых услуг в случае эмк' Group6,
             '*' fl1, 'База' fl2, '1.1.3.024' fl3, '*' fl4, '*' fl5, '*' fl6,
             0 fn1, 0 fn2, 0 fn3, 0 fn4, 0 fn5, 0 fn6
            from dual)
select 
 Группа1,
 Группа2,
 Группа3,
 Группа4,
 Группа5,
 Группа6,
 min(Период_с) Период_с,
 max(Период_по) Период_по,
 count(distinct nvl(to_char(client_id),id_pac)) Пациентов,
 count(distinct ZSL_ID) Случаев,
 sum(nvl(Услуг,1)) Услуг,
 nvl(Услуг_неполных,0) Услуг_неполных,
 sum(Койкодни) Койкодней,
 sum(Сумма) Сумма
/* 
 count(distinct case when Принят_ТФОМС=1 then id_pac end) Пациентов,
 count(distinct case when Принят_ТФОМС=1 then ZSL_ID end) Случаев,
 sum(case when Принят_ТФОМС=1 then Услуг end) Услуг,
 nvl(sum(case when Принят_ТФОМС=1 then Услуг_неполных end),0) Услуг_неполных,
 sum(case when Принят_ТФОМС=1 then Койкодни end) Койкодней,
 sum(case when Принят_ТФОМС=1 then Сумма end) Сумма,
-- count(distinct ZSL_ID) Предъявлено_Законченых_случаев,
 sum(Услуг) Предъявлено_Услуг_всего,
-- nvl(sum(Услуг_неполных),0) Предъявлено_Услуг_неполных,
 sum(Сумма) Предъявлено_Сумма
-- sum(Койкодни) Предъявлено_койкодней,
*/
from
dd,(
  select
    (case 
      when Group1='Период' then to_char(h.end_date,'mm')||' '||trim(to_char(h.end_date,'Month'))||' '||to_char(h.end_date,'yyyy')
      when Group1='Счет GUID' then lower(regexp_replace(regexp_replace(sh.head_id,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group1='Счет период' then to_char(sh.year,'0000')||' '||to_char(sh.month,'00')
      when Group1='Счет префикс файла' then (select t014.prefixfile from registry_oms.t014 t014 where t014.code=sh.type)
      when Group1='Счет наименование' then (select t014.name from registry_oms.t014 t014 where t014.code=sh.type) 
      when Group1='Счет номер' then 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00'))
      when Group1='Счет код типа' then sh.type
      when Group1='Счет вид реестра' then case when sh.type in ('01','14') then 'База'
                                               when sh.type in ('02','15') then 'Сверхбаза'
                                               when sh.type in ('10','22') then 'Межтер'
                                               when sh.type in ('03','23') then 'Высокотех'
                                               else sh.type end
      when Group1='Услуга вид помощи' then case when sl.code_usl in ('1.2.1.013','1.2.1.032') then 'Паллиативная помощь' 
                                                when zsl.usl_ok=1 then 'Стационарная помощь'
                                                when zsl.usl_ok=2 then 'Помощь в дневном стационаре'
                                                when zsl.usl_ok=3 then 'Амбулаторная помощь'
                                                else to_char(zsl.usl_ok) end
      when Group1='Услуга код' then sl.code_usl
      when Group1='Услуга наименование' then t3.name
      when Group1='Услуга код наименование' then sl.code_usl||' '||t3.name
      when Group1='ВМП вид' then sl.vid_hmp  
      when Group1='ВМП метод' then sl.metod_hmp
      when Group1='Перечень медвмешательств' then u.vid_vmes
      when Group1='Медвмешательство код' then sl.vid_vme
      when Group1='Медвмешательство код наименование' then  sl.vid_vme||' '||(select max(v001.caption) from registry_oms.v001 v001 where v001.code=sl.vid_vme)   
      when Group1='Лекарственная схема код' then sl.code_sh
      when Group1='Лекарственная схема код наименование' then sl.code_sh||' '||(select max(r.mnn_drugs) from hospital.register_drug_schema r where r.code=sl.code_sh and sl.date_2 between r.start_date and r.end_date)
      when Group1='Тариф' then to_char(sl.tarif,'999999999990D00')  
      when Group1='Пациент GUID' then lower(regexp_replace(regexp_replace(zsl.ID_PAC,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group1='Пациент' then zsl.fam||' '||zsl.im||' '||zsl.ot||' '||to_char(zsl.dr,'dd.mm.yyyy') 
      when Group1='Диагноз' then sl.ds1
      when Group1='Полис' then zsl.npolis
      when Group1='СМО' then zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group1='СМО тюменская' then (case when zsl.smo_ok='71000' then 'Тюменская' else 'Межтер' end)
      when Group1='Полис СМО' then zsl.npolis||' '||zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group1='Пациент эмк' then cl.sur_name||' '||cl.first_name||' '||cl.patr_name||' '||to_char(cl.birthday,'dd.mm.yyyy') 
      when Group1='Стацкарта эмк' then (select hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)||' '||stat.parep.GetShortDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group1='Случай эмк' then decode(p.project_type_id,2,'стац ','амб ')||to_char(p.id)||' с '||to_char(p.start_date,'dd.mm.yyyy')||' по '||to_char(p.end_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
      when Group1='Случай эмк тип' then decode(p.project_type_id,2,'стационарный','амбулаторный')
      when Group1='Лечащий врач эмк' then stat.parep.GetFIOWorker(p.worker_id) 
      when Group1='Диагноз эмк' then stat.parep.GetProjectMKBCode(1,p.id)
      when Group1='Отделение выбытия эмк' then (select to_char(stat.parep.GetDepOrder(stat.parep.GetOuttakeDepID(hc.id)),'00')||' '||stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group1='Тип стационара эмк' then decode((select substr(stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)),1,7) 
                                                      from hospital.hospital_card hc where hc.project_id=p.id),null,'Амбулаторный','Дневной','Дневной стационар','Круглосуточный стационар')
      when Group1='Гражданство эмк' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
      when Group1='Инвалидность эмк' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
      when Group1='Умер эмк' then decode(p.project_result_type2_id, -34, 'Мертв', -25, 'Мертв', 'Жив')
      when Group1='Территория проживания эмк' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
      when Group1='Регион проживания эмк' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
      when Group1='Куст проживания эмк' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
      when Group1='Проживает в Тюмени и юге области эмк' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
      when Group1='Пол' then decode(zsl.w,2,'Женщины',1,'Мужчины','Неопределен')
      when Group1='Возраст' then 'Возраст '||to_char(trunc(months_between(zsl.date_z_2,zsl.dr)/12),'00')
      when Group1='Трудоспособность' then (case when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<1 then 'Возраст до 1 года'
                                                when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<18 then 'Возраст до 18 лет'
                                                when (trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=55 and zsl.w=2)or(trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=60 and zsl.w=1)  then 'Старше трудоспособного возраста'
                                           else 'Трудоспособный' end)
      when Group1='Отделение по аналиту' then (select max(d.name) d_name   --в 10.2019 встречается дубль sl.sl_id
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id) 
      when Group1='Отделение группа по аналиту' then (select max(case when exists(select 1 from table(stat.parep.GetListDep(1)) t where t.id=d.id) then 'Дневной стационар'
                                                                      when exists(select 1 from table(stat.parep.GetListDep(0)) t where t.id=d.id) then 'Стационар'
                                                                 else 'АПП' end)
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id)                                                      
      when Group1='Принято' then (case when sl.accepted_tfoms=1 then 'Принят' else 'Не принят' end)
      when Group1='Первичный в случае' then (case when exists (select 1
                                         from HOSPITAL.Disease d2
                                              join HOSPITAL.ONCOLOGIC_DISEASE od2 on d2.ONCOLOGIC_DISEASE_ID = od2.ID
                                              join HOSPITAL.PROJECT p2 on d2.PROJECT_ID = p2.id
                                              join HOSPITAL.PROJECT_TYPE pt2 on p2.PROJECT_TYPE_ID = pt2.ID
                                              join HOSPITAL.DIAGNOSIS_TYPE dt2 on d2.DIAGNOSIS_TYPE_ID = dt2.ID
                                              join HOSPITAL.MKB m2 on d2.MKB_ID = m2.ID
                                        where  
                                              p2.id=p.id
                                              and (od2.SOURCE_CANCER_DATE is null)
                                              and pt2.CARE_TYPE_ID = 3
                                              and (od2.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                              and (dt2.Code in (2, 4, 7, 3))
                                              and not (exists (select d1.ID
                                                                 from HOSPITAL.Disease d1
                                                                      join HOSPITAL.PROJECT p1 on d1.PROJECT_ID = p1.ID
                                                                      join HOSPITAL.ONCOLOGIC_DISEASE od1 on d1.ONCOLOGIC_DISEASE_ID = od1.ID
                                                                      join HOSPITAL.DIAGNOSIS_TYPE dt1 on d1.DIAGNOSIS_TYPE_ID = dt1.ID
                                                                      join HOSPITAL.MKB m1 on d1.MKB_ID = m1.ID
                                                                where p1.CLIENT_ID = p2.CLIENT_ID
                                                                      and (od1.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                                                      and (dt1.Code in (2, 4, 7, 3))
                                                                      and d1.START_DATE < d2.START_DATE
                                                                      and substr(m1.code, 1, 3) = substr(m2.code, 1, 3)))                                              
                                    ) then 'Да' else 'Нет' end)   
      when Group1='Услуга в периоде сдачи' then (case when exists(
                                        select min(h.start_date) s,max(h.end_date) e 
                                          from registry_oms.schet sh join registry_oms.head h on h.id=sh.head_id
                                         where sh.year between y1 and y2 and sh.month between m1 and m2 and sh.type<>'00'
                                        having zsl.date_z_2 between min(h.start_date) and max(h.end_date)
                                    ) then 'Услуга в периоде сдачи' else 'Услуга вне периода сдачи'  end)        
      when Group1='Услуга подробно' then to_char(zsl.date_z_2,'dd.mm.yy')||' '||sl.code_usl||' '||sl.vid_vme||' '||t3.name||' на '||trim(to_char(zsl.sumv,'999999999990D00'))||' руб '||to_char(u.kol_usl)||'шт счет '||sh.nschet||' от '||to_char(sh.dschet,'dd.mm.yy') 
      when Group1='Медвмешательство присутсвует в случае эмк' then (case when exists(
                                        select 1
                                          from hospital.service_operation ro
                                               join hospital.service s on s.id=ro.service_id
                                               join hospital.service_type st on st.id=s.service_type_id
                                         where s.project_id=p.id and trunc(ro.operation_date)=zsl.date_z_2 and st.code2=sl.vid_vme 
                                               and ro.operation_type_id=4
                                               and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=10 and so1.id>ro.id)
                                               and exists (select pt.short_name t
                                                             from hospital.service_operation so
                                                                  join hospital.client_certificate cc on cc.id=so.client_certificate_id
                                                                  join hospital.client_certificate_type cct on cct.id=cc.certificate_type_id
                                                                  join hospital.pay_type pt on pt.id=cct.pay_type_id
                                                            where so.operation_type_id=2 and so.service_id=s.id and pt.id=801)
                                    ) then 'Есть' else 'Нет' end)   
      when Group1='Перечень выполненых услуг в случае эмк' then (
                     select listagg(c, '') WITHIN GROUP(order by d)
                       from (select stat.parep.GetServiceExecDate(s.id) d,
                                    case when trunc(stat.parep.GetServiceExecDate(s.id))=zsl.date_z_2 and st.code2=sl.vid_vme then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||'* '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<10 then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||' '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<13 then '.' end c
                               from hospital.service s left join hospital.service_type st on st.id=s.service_type_id
                              where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null and stat.parep.GetServicePayType(s.id)='ОМС'))                                   
     end) Группа1,
     (case 
      when Group2='Период' then to_char(h.end_date,'mm')||' '||trim(to_char(h.end_date,'Month'))||' '||to_char(h.end_date,'yyyy')
      when Group2='Счет GUID' then lower(regexp_replace(regexp_replace(sh.head_id,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group2='Счет период' then to_char(sh.year,'0000')||' '||to_char(sh.month,'00')
      when Group2='Счет префикс файла' then (select t014.prefixfile from registry_oms.t014 t014 where t014.code=sh.type)
      when Group2='Счет наименование' then (select t014.name from registry_oms.t014 t014 where t014.code=sh.type) 
      when Group2='Счет номер' then 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00'))
      when Group2='Счет код типа' then sh.type
      when Group2='Счет вид реестра' then case when sh.type in ('01','14') then 'База'
                                               when sh.type in ('02','15') then 'Сверхбаза'
                                               when sh.type in ('10','22') then 'Межтер'
                                               when sh.type in ('03','23') then 'Высокотех'
                                               else sh.type end
      when Group2='Услуга вид помощи' then case when sl.code_usl in ('1.2.1.013','1.2.1.032') then 'Паллиативная помощь' 
                                                when zsl.usl_ok=1 then 'Стационарная помощь'
                                                when zsl.usl_ok=2 then 'Помощь в дневном стационаре'
                                                when zsl.usl_ok=3 then 'Амбулаторная помощь'
                                                else to_char(zsl.usl_ok) end       
      when Group2='Услуга код' then sl.code_usl
      when Group2='Услуга наименование' then t3.name
      when Group2='Услуга код наименование' then sl.code_usl||' '||t3.name
      when Group2='ВМП вид' then sl.vid_hmp  
      when Group2='ВМП метод' then sl.metod_hmp
      when Group2='Перечень медвмешательств' then u.vid_vmes
      when Group2='Медвмешательство код' then sl.vid_vme
      when Group2='Медвмешательство код наименование' then  sl.vid_vme||' '||(select max(v001.caption) from registry_oms.v001 v001 where v001.code=sl.vid_vme)   
      when Group2='Лекарственная схема код' then sl.code_sh
      when Group2='Лекарственная схема код наименование' then sl.code_sh||' '||(select max(r.mnn_drugs) from hospital.register_drug_schema r where r.code=sl.code_sh and sl.date_2 between r.start_date and r.end_date)
      when Group2='Тариф' then to_char(sl.tarif,'999999999990D00')  
      when Group2='Пациент GUID' then lower(regexp_replace(regexp_replace(zsl.ID_PAC,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group2='Пациент' then zsl.fam||' '||zsl.im||' '||zsl.ot||' '||to_char(zsl.dr,'dd.mm.yyyy') 
      when Group2='Диагноз' then sl.ds1
      when Group2='Полис' then zsl.npolis
      when Group2='СМО' then zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group2='СМО тюменская' then (case when zsl.smo_ok='71000' then 'Тюменская' else 'Межтер' end)         
      when Group2='Полис СМО' then zsl.npolis||' '||zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam       
      when Group2='Пациент эмк' then cl.sur_name||' '||cl.first_name||' '||cl.patr_name||' '||to_char(cl.birthday,'dd.mm.yyyy') 
      when Group2='Стацкарта эмк' then (select hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)||' '||stat.parep.GetShortDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group2='Случай эмк' then decode(p.project_type_id,2,'стац ','амб ')||to_char(p.id)||' с '||to_char(p.start_date,'dd.mm.yyyy')||' по '||to_char(p.end_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
      when Group2='Случай эмк тип' then decode(p.project_type_id,2,'стационарный','амбулаторный')
      when Group2='Лечащий врач эмк' then stat.parep.GetFIOWorker(p.worker_id) 
      when Group2='Диагноз эмк' then stat.parep.GetProjectMKBCode(1,p.id)
      when Group2='Отделение выбытия эмк' then (select to_char(stat.parep.GetDepOrder(stat.parep.GetOuttakeDepID(hc.id)),'00')||' '||stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group2='Тип стационара эмк' then decode((select substr(stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)),1,7) 
                                                      from hospital.hospital_card hc where hc.project_id=p.id),null,'Амбулаторный','Дневной','Дневной стационар','Круглосуточный стационар')
      when Group2='Гражданство эмк' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
      when Group2='Инвалидность эмк' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
      when Group2='Умер эмк' then decode(p.project_result_type2_id, -34, 'Мертв', -25, 'Мертв', 'Жив')
      when Group2='Территория проживания эмк' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
      when Group2='Регион проживания эмк' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
      when Group2='Куст проживания эмк' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
      when Group2='Проживает в Тюмени и юге области эмк' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
      when Group2='Пол' then decode(zsl.w,2,'Женщины',1,'Мужчины','Неопределен')
      when Group2='Возраст' then 'Возраст '||to_char(trunc(months_between(zsl.date_z_2,zsl.dr)/12),'00')
      when Group2='Трудоспособность' then (case when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<1 then 'Возраст до 1 года'
                                                when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<18 then 'Возраст до 18 лет'
                                                when (trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=55 and zsl.w=2)or(trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=60 and zsl.w=1)  then 'Старше трудоспособного возраста'
                                           else 'Трудоспособный' end)
      when Group2='Отделение по аналиту' then (select max(d.name) d_name   --в 10.2019 встречается дубль sl.sl_id
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id) 
      when Group2='Отделение группа по аналиту' then (select max(case when exists(select 1 from table(stat.parep.GetListDep(1)) t where t.id=d.id) then 'Дневной стационар'
                                                                      when exists(select 1 from table(stat.parep.GetListDep(0)) t where t.id=d.id) then 'Стационар'
                                                                 else 'АПП' end)
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id)                                                      
      when Group2='Принято' then (case when sl.accepted_tfoms=1 then 'Принят' else 'Не принят' end)
      when Group2='Первичный в случае' then (case when exists (select 1
                                         from HOSPITAL.Disease d2
                                              join HOSPITAL.ONCOLOGIC_DISEASE od2 on d2.ONCOLOGIC_DISEASE_ID = od2.ID
                                              join HOSPITAL.PROJECT p2 on d2.PROJECT_ID = p2.id
                                              join HOSPITAL.PROJECT_TYPE pt2 on p2.PROJECT_TYPE_ID = pt2.ID
                                              join HOSPITAL.DIAGNOSIS_TYPE dt2 on d2.DIAGNOSIS_TYPE_ID = dt2.ID
                                              join HOSPITAL.MKB m2 on d2.MKB_ID = m2.ID
                                        where  
                                              p2.id=p.id
                                              and (od2.SOURCE_CANCER_DATE is null)
                                              and pt2.CARE_TYPE_ID = 3
                                              and (od2.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                              and (dt2.Code in (2, 4, 7, 3))
                                              and not (exists (select d1.ID
                                                                 from HOSPITAL.Disease d1
                                                                      join HOSPITAL.PROJECT p1 on d1.PROJECT_ID = p1.ID
                                                                      join HOSPITAL.ONCOLOGIC_DISEASE od1 on d1.ONCOLOGIC_DISEASE_ID = od1.ID
                                                                      join HOSPITAL.DIAGNOSIS_TYPE dt1 on d1.DIAGNOSIS_TYPE_ID = dt1.ID
                                                                      join HOSPITAL.MKB m1 on d1.MKB_ID = m1.ID
                                                                where p1.CLIENT_ID = p2.CLIENT_ID
                                                                      and (od1.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                                                      and (dt1.Code in (2, 4, 7, 3))
                                                                      and d1.START_DATE < d2.START_DATE
                                                                      and substr(m1.code, 1, 3) = substr(m2.code, 1, 3)))                                              
                                    ) then 'Да' else 'Нет' end)   
      when Group2='Услуга в периоде сдачи' then (case when exists(
                                        select min(h.start_date) s,max(h.end_date) e 
                                          from registry_oms.schet sh join registry_oms.head h on h.id=sh.head_id
                                         where sh.year between y1 and y2 and sh.month between m1 and m2 and sh.type<>'00'
                                        having zsl.date_z_2 between min(h.start_date) and max(h.end_date)
                                    ) then 'Услуга в периоде сдачи' else 'Услуга вне периода сдачи'  end)        
      when Group2='Услуга подробно' then to_char(zsl.date_z_2,'dd.mm.yy')||' '||sl.code_usl||' '||sl.vid_vme||' '||t3.name||' на '||trim(to_char(zsl.sumv,'999999999990D00'))||' руб '||to_char(u.kol_usl)||'шт счет '||sh.nschet||' от '||to_char(sh.dschet,'dd.mm.yy') 
      when Group2='Медвмешательство присутсвует в случае эмк' then (case when exists(
                                        select 1
                                          from hospital.service_operation ro
                                               join hospital.service s on s.id=ro.service_id
                                               join hospital.service_type st on st.id=s.service_type_id
                                         where s.project_id=p.id and trunc(ro.operation_date)=zsl.date_z_2 and st.code2=sl.vid_vme 
                                               and ro.operation_type_id=4
                                               and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=10 and so1.id>ro.id)
                                               and exists (select pt.short_name t
                                                             from hospital.service_operation so
                                                                  join hospital.client_certificate cc on cc.id=so.client_certificate_id
                                                                  join hospital.client_certificate_type cct on cct.id=cc.certificate_type_id
                                                                  join hospital.pay_type pt on pt.id=cct.pay_type_id
                                                            where so.operation_type_id=2 and so.service_id=s.id and pt.id=801)
                                    ) then 'Есть' else 'Нет' end)   
      when Group2='Перечень выполненых услуг в случае эмк' then (
                     select listagg(c, '') WITHIN GROUP(order by d)
                       from (select stat.parep.GetServiceExecDate(s.id) d,
                                    case when trunc(stat.parep.GetServiceExecDate(s.id))=zsl.date_z_2 and st.code2=sl.vid_vme then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||'* '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<10 then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||' '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<13 then '.' end c
                               from hospital.service s left join hospital.service_type st on st.id=s.service_type_id
                              where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null and stat.parep.GetServicePayType(s.id)='ОМС'))                                  
     end) Группа2,
    (case 
      when Group3='Период' then to_char(h.end_date,'mm')||' '||trim(to_char(h.end_date,'Month'))||' '||to_char(h.end_date,'yyyy')
      when Group3='Счет GUID' then lower(regexp_replace(regexp_replace(sh.head_id,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group3='Счет период' then to_char(sh.year,'0000')||' '||to_char(sh.month,'00')
      when Group3='Счет префикс файла' then (select t014.prefixfile from registry_oms.t014 t014 where t014.code=sh.type)
      when Group3='Счет наименование' then (select t014.name from registry_oms.t014 t014 where t014.code=sh.type) 
      when Group3='Счет номер' then 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00'))
      when Group3='Счет код типа' then sh.type
      when Group3='Счет вид реестра' then case when sh.type in ('01','14') then 'База'
                                               when sh.type in ('02','15') then 'Сверхбаза'
                                               when sh.type in ('10','22') then 'Межтер'
                                               when sh.type in ('03','23') then 'Высокотех'
                                               else sh.type end
      when Group3='Услуга вид помощи' then case when sl.code_usl in ('1.2.1.013','1.2.1.032') then 'Паллиативная помощь' 
                                                when zsl.usl_ok=1 then 'Стационарная помощь'
                                                when zsl.usl_ok=2 then 'Помощь в дневном стационаре'
                                                when zsl.usl_ok=3 then 'Амбулаторная помощь'
                                                else to_char(zsl.usl_ok) end     
      when Group3='Услуга код' then sl.code_usl
      when Group3='Услуга наименование' then t3.name
      when Group3='Услуга код наименование' then sl.code_usl||' '||t3.name
      when Group3='ВМП вид' then sl.vid_hmp  
      when Group3='ВМП метод' then sl.metod_hmp
      when Group3='Перечень медвмешательств' then u.vid_vmes
      when Group3='Медвмешательство код' then sl.vid_vme
      when Group3='Медвмешательство код наименование' then  sl.vid_vme||' '||(select max(v001.caption) from registry_oms.v001 v001 where v001.code=sl.vid_vme)   
      when Group3='Лекарственная схема код' then sl.code_sh
      when Group3='Лекарственная схема код наименование' then sl.code_sh||' '||(select max(r.mnn_drugs) from hospital.register_drug_schema r where r.code=sl.code_sh and sl.date_2 between r.start_date and r.end_date)
      when Group3='Тариф' then to_char(sl.tarif,'999999999990D00')  
      when Group3='Пациент GUID' then lower(regexp_replace(regexp_replace(zsl.ID_PAC,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group3='Пациент' then zsl.fam||' '||zsl.im||' '||zsl.ot||' '||to_char(zsl.dr,'dd.mm.yyyy') 
      when Group3='Диагноз' then sl.ds1
      when Group3='Полис' then zsl.npolis
      when Group3='СМО' then zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group3='СМО тюменская' then (case when zsl.smo_ok='71000' then 'Тюменская' else 'Межтер' end)         
      when Group3='Полис СМО' then zsl.npolis||' '||zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group3='Пациент эмк' then cl.sur_name||' '||cl.first_name||' '||cl.patr_name||' '||to_char(cl.birthday,'dd.mm.yyyy') 
      when Group3='Стацкарта эмк' then (select hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)||' '||stat.parep.GetShortDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group3='Случай эмк' then decode(p.project_type_id,2,'стац ','амб ')||to_char(p.id)||' с '||to_char(p.start_date,'dd.mm.yyyy')||' по '||to_char(p.end_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
      when Group3='Случай эмк тип' then decode(p.project_type_id,2,'стационарный','амбулаторный')
      when Group3='Лечащий врач эмк' then stat.parep.GetFIOWorker(p.worker_id) 
      when Group3='Диагноз эмк' then stat.parep.GetProjectMKBCode(1,p.id)
      when Group3='Отделение выбытия эмк' then (select to_char(stat.parep.GetDepOrder(stat.parep.GetOuttakeDepID(hc.id)),'00')||' '||stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group3='Тип стационара эмк' then decode((select substr(stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)),1,7) 
                                                      from hospital.hospital_card hc where hc.project_id=p.id),null,'Амбулаторный','Дневной','Дневной стационар','Круглосуточный стационар')
      when Group3='Гражданство эмк' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
      when Group3='Инвалидность эмк' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
      when Group3='Умер эмк' then decode(p.project_result_type2_id, -34, 'Мертв', -25, 'Мертв', 'Жив')
      when Group3='Территория проживания эмк' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
      when Group3='Регион проживания эмк' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
      when Group3='Куст проживания эмк' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
      when Group3='Проживает в Тюмени и юге области эмк' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
      when Group3='Пол' then decode(zsl.w,2,'Женщины',1,'Мужчины','Неопределен')
      when Group3='Возраст' then 'Возраст '||to_char(trunc(months_between(zsl.date_z_2,zsl.dr)/12),'00')
      when Group3='Трудоспособность' then (case when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<1 then 'Возраст до 1 года'
                                                when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<18 then 'Возраст до 18 лет'
                                                when (trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=55 and zsl.w=2)or(trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=60 and zsl.w=1)  then 'Старше трудоспособного возраста'
                                           else 'Трудоспособный' end)
      when Group3='Отделение по аналиту' then (select max(d.name) d_name   --в 10.2019 встречается дубль sl.sl_id
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id)
      when Group3='Отделение группа по аналиту' then (select max(case when exists(select 1 from table(stat.parep.GetListDep(1)) t where t.id=d.id) then 'Дневной стационар'
                                                                      when exists(select 1 from table(stat.parep.GetListDep(0)) t where t.id=d.id) then 'Стационар'
                                                                 else 'АПП' end)
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id)                                                       
      when Group3='Принято' then (case when sl.accepted_tfoms=1 then 'Принят' else 'Не принят' end)
      when Group3='Первичный в случае' then (case when exists (select 1
                                         from HOSPITAL.Disease d2
                                              join HOSPITAL.ONCOLOGIC_DISEASE od2 on d2.ONCOLOGIC_DISEASE_ID = od2.ID
                                              join HOSPITAL.PROJECT p2 on d2.PROJECT_ID = p2.id
                                              join HOSPITAL.PROJECT_TYPE pt2 on p2.PROJECT_TYPE_ID = pt2.ID
                                              join HOSPITAL.DIAGNOSIS_TYPE dt2 on d2.DIAGNOSIS_TYPE_ID = dt2.ID
                                              join HOSPITAL.MKB m2 on d2.MKB_ID = m2.ID
                                        where  
                                              p2.id=p.id
                                              and (od2.SOURCE_CANCER_DATE is null)
                                              and pt2.CARE_TYPE_ID = 3
                                              and (od2.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                              and (dt2.Code in (2, 4, 7, 3))
                                              and not (exists (select d1.ID
                                                                 from HOSPITAL.Disease d1
                                                                      join HOSPITAL.PROJECT p1 on d1.PROJECT_ID = p1.ID
                                                                      join HOSPITAL.ONCOLOGIC_DISEASE od1 on d1.ONCOLOGIC_DISEASE_ID = od1.ID
                                                                      join HOSPITAL.DIAGNOSIS_TYPE dt1 on d1.DIAGNOSIS_TYPE_ID = dt1.ID
                                                                      join HOSPITAL.MKB m1 on d1.MKB_ID = m1.ID
                                                                where p1.CLIENT_ID = p2.CLIENT_ID
                                                                      and (od1.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                                                      and (dt1.Code in (2, 4, 7, 3))
                                                                      and d1.START_DATE < d2.START_DATE
                                                                      and substr(m1.code, 1, 3) = substr(m2.code, 1, 3)))                                              
                                    ) then 'Да' else 'Нет' end) 
      when Group3='Услуга в периоде сдачи' then (case when exists(
                                        select min(h.start_date) s,max(h.end_date) e 
                                          from registry_oms.schet sh join registry_oms.head h on h.id=sh.head_id
                                         where sh.year between y1 and y2 and sh.month between m1 and m2 and sh.type<>'00'
                                        having zsl.date_z_2 between min(h.start_date) and max(h.end_date)
                                    ) then 'Услуга в периоде сдачи' else 'Услуга вне периода сдачи'  end)        
      when Group3='Услуга подробно' then to_char(zsl.date_z_2,'dd.mm.yy')||' '||sl.code_usl||' '||sl.vid_vme||' '||t3.name||' на '||trim(to_char(zsl.sumv,'999999999990D00'))||' руб '||to_char(u.kol_usl)||'шт счет '||sh.nschet||' от '||to_char(sh.dschet,'dd.mm.yy') 
      when Group3='Медвмешательство присутсвует в случае эмк' then (case when exists(
                                        select 1
                                          from hospital.service_operation ro
                                               join hospital.service s on s.id=ro.service_id
                                               join hospital.service_type st on st.id=s.service_type_id
                                         where s.project_id=p.id and trunc(ro.operation_date)=zsl.date_z_2 and st.code2=sl.vid_vme 
                                               and ro.operation_type_id=4
                                               and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=10 and so1.id>ro.id)
                                               and exists (select pt.short_name t
                                                             from hospital.service_operation so
                                                                  join hospital.client_certificate cc on cc.id=so.client_certificate_id
                                                                  join hospital.client_certificate_type cct on cct.id=cc.certificate_type_id
                                                                  join hospital.pay_type pt on pt.id=cct.pay_type_id
                                                            where so.operation_type_id=2 and so.service_id=s.id and pt.id=801)
                                    ) then 'Есть' else 'Нет' end)   
      when Group3='Перечень выполненых услуг в случае эмк' then (
                     select listagg(c, '') WITHIN GROUP(order by d)
                       from (select stat.parep.GetServiceExecDate(s.id) d,
                                    case when trunc(stat.parep.GetServiceExecDate(s.id))=zsl.date_z_2 and st.code2=sl.vid_vme then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||'* '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<10 then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||' '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<13 then '.' end c
                               from hospital.service s left join hospital.service_type st on st.id=s.service_type_id
                              where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null and stat.parep.GetServicePayType(s.id)='ОМС'))                                   
     end) Группа3,
    (case 
      when Group4='Период' then to_char(h.end_date,'mm')||' '||trim(to_char(h.end_date,'Month'))||' '||to_char(h.end_date,'yyyy')
      when Group4='Счет GUID' then lower(regexp_replace(regexp_replace(sh.head_id,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group4='Счет период' then to_char(sh.year,'0000')||' '||to_char(sh.month,'00')
      when Group4='Счет префикс файла' then (select t014.prefixfile from registry_oms.t014 t014 where t014.code=sh.type)
      when Group4='Счет наименование' then (select t014.name from registry_oms.t014 t014 where t014.code=sh.type) 
      when Group4='Счет номер' then 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00'))
      when Group4='Счет код типа' then sh.type
      when Group4='Счет вид реестра' then case when sh.type in ('01','14') then 'База'
                                               when sh.type in ('02','15') then 'Сверхбаза'
                                               when sh.type in ('10','22') then 'Межтер'
                                               when sh.type in ('03','23') then 'Высокотех'
                                               else sh.type end
      when Group4='Услуга вид помощи' then case when sl.code_usl in ('1.2.1.013','1.2.1.032') then 'Паллиативная помощь' 
                                                when zsl.usl_ok=1 then 'Стационарная помощь'
                                                when zsl.usl_ok=2 then 'Помощь в дневном стационаре'
                                                when zsl.usl_ok=3 then 'Амбулаторная помощь'
                                                else to_char(zsl.usl_ok) end     
      when Group4='Услуга код' then sl.code_usl
      when Group4='Услуга наименование' then t3.name
      when Group4='Услуга код наименование' then sl.code_usl||' '||t3.name
      when Group4='ВМП вид' then sl.vid_hmp  
      when Group4='ВМП метод' then sl.metod_hmp
      when Group4='Перечень медвмешательств' then u.vid_vmes
      when Group4='Медвмешательство код' then sl.vid_vme
      when Group4='Медвмешательство код наименование' then  sl.vid_vme||' '||(select max(v001.caption) from registry_oms.v001 v001 where v001.code=sl.vid_vme)   
      when Group4='Лекарственная схема код' then sl.code_sh
      when Group4='Лекарственная схема код наименование' then sl.code_sh||' '||(select max(r.mnn_drugs) from hospital.register_drug_schema r where r.code=sl.code_sh and sl.date_2 between r.start_date and r.end_date)
      when Group4='Тариф' then to_char(sl.tarif,'999999999990D00')  
      when Group4='Пациент GUID' then lower(regexp_replace(regexp_replace(zsl.ID_PAC,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group4='Пациент' then zsl.fam||' '||zsl.im||' '||zsl.ot||' '||to_char(zsl.dr,'dd.mm.yyyy') 
      when Group4='Диагноз' then sl.ds1
      when Group4='Полис' then zsl.npolis
      when Group4='СМО' then zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group4='СМО тюменская' then (case when zsl.smo_ok='71000' then 'Тюменская' else 'Межтер' end)         
      when Group4='Полис СМО' then zsl.npolis||' '||zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group4='Пациент эмк' then cl.sur_name||' '||cl.first_name||' '||cl.patr_name||' '||to_char(cl.birthday,'dd.mm.yyyy') 
      when Group4='Стацкарта эмк' then (select hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)||' '||stat.parep.GetShortDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group4='Случай эмк' then decode(p.project_type_id,2,'стац ','амб ')||to_char(p.id)||' с '||to_char(p.start_date,'dd.mm.yyyy')||' по '||to_char(p.end_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
      when Group4='Случай эмк тип' then decode(p.project_type_id,2,'стационарный','амбулаторный')
      when Group4='Лечащий врач эмк' then stat.parep.GetFIOWorker(p.worker_id) 
      when Group4='Диагноз эмк' then stat.parep.GetProjectMKBCode(1,p.id)
      when Group4='Отделение выбытия эмк' then (select to_char(stat.parep.GetDepOrder(stat.parep.GetOuttakeDepID(hc.id)),'00')||' '||stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group4='Тип стационара эмк' then decode((select substr(stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)),1,7) 
                                                      from hospital.hospital_card hc where hc.project_id=p.id),null,'Амбулаторный','Дневной','Дневной стационар','Круглосуточный стационар')
      when Group4='Гражданство эмк' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
      when Group4='Инвалидность эмк' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
      when Group4='Умер эмк' then decode(p.project_result_type2_id, -34, 'Мертв', -25, 'Мертв', 'Жив')
      when Group4='Территория проживания эмк' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
      when Group4='Регион проживания эмк' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
      when Group4='Куст проживания эмк' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
      when Group4='Проживает в Тюмени и юге области эмк' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
      when Group4='Пол' then decode(zsl.w,2,'Женщины',1,'Мужчины','Неопределен')
      when Group4='Возраст' then 'Возраст '||to_char(trunc(months_between(zsl.date_z_2,zsl.dr)/12),'00')
      when Group4='Трудоспособность' then (case when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<1 then 'Возраст до 1 года'
                                                when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<18 then 'Возраст до 18 лет'
                                                when (trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=55 and zsl.w=2)or(trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=60 and zsl.w=1)  then 'Старше трудоспособного возраста'
                                           else 'Трудоспособный' end)
      when Group4='Отделение по аналиту' then (select max(d.name) d_name   --в 10.2019 встречается дубль sl.sl_id
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id) 
      when Group4='Отделение группа по аналиту' then (select max(case when exists(select 1 from table(stat.parep.GetListDep(1)) t where t.id=d.id) then 'Дневной стационар'
                                                                      when exists(select 1 from table(stat.parep.GetListDep(0)) t where t.id=d.id) then 'Стационар'
                                                                 else 'АПП' end)
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id)                                                      
      when Group4='Принято' then (case when sl.accepted_tfoms=1 then 'Принят' else 'Не принят' end)
      when Group4='Первичный в случае' then (case when exists (select 1
                                         from HOSPITAL.Disease d2
                                              join HOSPITAL.ONCOLOGIC_DISEASE od2 on d2.ONCOLOGIC_DISEASE_ID = od2.ID
                                              join HOSPITAL.PROJECT p2 on d2.PROJECT_ID = p2.id
                                              join HOSPITAL.PROJECT_TYPE pt2 on p2.PROJECT_TYPE_ID = pt2.ID
                                              join HOSPITAL.DIAGNOSIS_TYPE dt2 on d2.DIAGNOSIS_TYPE_ID = dt2.ID
                                              join HOSPITAL.MKB m2 on d2.MKB_ID = m2.ID
                                        where  
                                              p2.id=p.id
                                              and (od2.SOURCE_CANCER_DATE is null)
                                              and pt2.CARE_TYPE_ID = 3
                                              and (od2.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                              and (dt2.Code in (2, 4, 7, 3))
                                              and not (exists (select d1.ID
                                                                 from HOSPITAL.Disease d1
                                                                      join HOSPITAL.PROJECT p1 on d1.PROJECT_ID = p1.ID
                                                                      join HOSPITAL.ONCOLOGIC_DISEASE od1 on d1.ONCOLOGIC_DISEASE_ID = od1.ID
                                                                      join HOSPITAL.DIAGNOSIS_TYPE dt1 on d1.DIAGNOSIS_TYPE_ID = dt1.ID
                                                                      join HOSPITAL.MKB m1 on d1.MKB_ID = m1.ID
                                                                where p1.CLIENT_ID = p2.CLIENT_ID
                                                                      and (od1.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                                                      and (dt1.Code in (2, 4, 7, 3))
                                                                      and d1.START_DATE < d2.START_DATE
                                                                      and substr(m1.code, 1, 3) = substr(m2.code, 1, 3)))                                              
                                    ) then 'Да' else 'Нет' end)
      when Group4='Услуга в периоде сдачи' then (case when exists(
                                        select min(h.start_date) s,max(h.end_date) e 
                                          from registry_oms.schet sh join registry_oms.head h on h.id=sh.head_id
                                         where sh.year between y1 and y2 and sh.month between m1 and m2 and sh.type<>'00'
                                        having zsl.date_z_2 between min(h.start_date) and max(h.end_date)
                                    ) then 'Услуга в периоде сдачи' else 'Услуга вне периода сдачи'  end)        
      when Group4='Услуга подробно' then to_char(zsl.date_z_2,'dd.mm.yy')||' '||sl.code_usl||' '||sl.vid_vme||' '||t3.name||' на '||trim(to_char(zsl.sumv,'999999999990D00'))||' руб '||to_char(u.kol_usl)||'шт счет '||sh.nschet||' от '||to_char(sh.dschet,'dd.mm.yy') 
      when Group4='Медвмешательство присутсвует в случае эмк' then (case when exists(
                                        select 1
                                          from hospital.service_operation ro
                                               join hospital.service s on s.id=ro.service_id
                                               join hospital.service_type st on st.id=s.service_type_id
                                         where s.project_id=p.id and trunc(ro.operation_date)=zsl.date_z_2 and st.code2=sl.vid_vme 
                                               and ro.operation_type_id=4
                                               and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=10 and so1.id>ro.id)
                                               and exists (select pt.short_name t
                                                             from hospital.service_operation so
                                                                  join hospital.client_certificate cc on cc.id=so.client_certificate_id
                                                                  join hospital.client_certificate_type cct on cct.id=cc.certificate_type_id
                                                                  join hospital.pay_type pt on pt.id=cct.pay_type_id
                                                            where so.operation_type_id=2 and so.service_id=s.id and pt.id=801)
                                    ) then 'Есть' else 'Нет' end)   
      when Group4='Перечень выполненых услуг в случае эмк' then (
                     select listagg(c, '') WITHIN GROUP(order by d)
                       from (select stat.parep.GetServiceExecDate(s.id) d,
                                    case when trunc(stat.parep.GetServiceExecDate(s.id))=zsl.date_z_2 and st.code2=sl.vid_vme then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||'* '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<10 then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||' '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<13 then '.' end c
                               from hospital.service s left join hospital.service_type st on st.id=s.service_type_id
                              where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null and stat.parep.GetServicePayType(s.id)='ОМС'))                                            
     end) Группа4,
    (case 
      when Group5='Период' then to_char(h.end_date,'mm')||' '||trim(to_char(h.end_date,'Month'))||' '||to_char(h.end_date,'yyyy')
      when Group5='Счет GUID' then lower(regexp_replace(regexp_replace(sh.head_id,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group5='Счет период' then to_char(sh.year,'0000')||' '||to_char(sh.month,'00')
      when Group5='Счет префикс файла' then (select t014.prefixfile from registry_oms.t014 t014 where t014.code=sh.type)
      when Group5='Счет наименование' then (select t014.name from registry_oms.t014 t014 where t014.code=sh.type) 
      when Group5='Счет номер' then 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00'))
      when Group5='Счет код типа' then sh.type
      when Group5='Счет вид реестра' then case when sh.type in ('01','14') then 'База'
                                               when sh.type in ('02','15') then 'Сверхбаза'
                                               when sh.type in ('10','22') then 'Межтер'
                                               when sh.type in ('03','23') then 'Высокотех'
                                               else sh.type end
      when Group5='Услуга вид помощи' then case when sl.code_usl in ('1.2.1.013','1.2.1.032') then 'Паллиативная помощь' 
                                                when zsl.usl_ok=1 then 'Стационарная помощь'
                                                when zsl.usl_ok=2 then 'Помощь в дневном стационаре'
                                                when zsl.usl_ok=3 then 'Амбулаторная помощь'
                                                else to_char(zsl.usl_ok) end     
      when Group5='Услуга код' then sl.code_usl
      when Group5='Услуга наименование' then t3.name
      when Group5='Услуга код наименование' then sl.code_usl||' '||t3.name
      when Group5='ВМП вид' then sl.vid_hmp  
      when Group5='ВМП метод' then sl.metod_hmp
      when Group5='Перечень медвмешательств' then u.vid_vmes
      when Group5='Медвмешательство код' then sl.vid_vme
      when Group5='Медвмешательство код наименование' then  sl.vid_vme||' '||(select max(v001.caption) from registry_oms.v001 v001 where v001.code=sl.vid_vme)   
      when Group5='Лекарственная схема код' then sl.code_sh
      when Group5='Лекарственная схема код наименование' then sl.code_sh||' '||(select max(r.mnn_drugs) from hospital.register_drug_schema r where r.code=sl.code_sh and sl.date_2 between r.start_date and r.end_date)
      when Group5='Тариф' then to_char(sl.tarif,'999999999990D00')  
      when Group5='Пациент GUID' then lower(regexp_replace(regexp_replace(zsl.ID_PAC,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group5='Пациент' then zsl.fam||' '||zsl.im||' '||zsl.ot||' '||to_char(zsl.dr,'dd.mm.yyyy') 
      when Group5='Диагноз' then sl.ds1
      when Group5='Полис' then zsl.npolis
      when Group5='СМО' then zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group5='СМО тюменская' then (case when zsl.smo_ok='71000' then 'Тюменская' else 'Межтер' end)         
      when Group5='Полис СМО' then zsl.npolis||' '||zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group5='Пациент эмк' then cl.sur_name||' '||cl.first_name||' '||cl.patr_name||' '||to_char(cl.birthday,'dd.mm.yyyy') 
      when Group5='Стацкарта эмк' then (select hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)||' '||stat.parep.GetShortDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group5='Случай эмк' then decode(p.project_type_id,2,'стац ','амб ')||to_char(p.id)||' с '||to_char(p.start_date,'dd.mm.yyyy')||' по '||to_char(p.end_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
      when Group5='Случай эмк тип' then decode(p.project_type_id,2,'стационарный','амбулаторный')
      when Group5='Лечащий врач эмк' then stat.parep.GetFIOWorker(p.worker_id) 
      when Group5='Диагноз эмк' then stat.parep.GetProjectMKBCode(1,p.id)
      when Group5='Отделение выбытия эмк' then (select to_char(stat.parep.GetDepOrder(stat.parep.GetOuttakeDepID(hc.id)),'00')||' '||stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group5='Тип стационара эмк' then decode((select substr(stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)),1,7) 
                                                      from hospital.hospital_card hc where hc.project_id=p.id),null,'Амбулаторный','Дневной','Дневной стационар','Круглосуточный стационар')
      when Group5='Гражданство эмк' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
      when Group5='Инвалидность эмк' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
      when Group5='Умер эмк' then decode(p.project_result_type2_id, -34, 'Мертв', -25, 'Мертв', 'Жив')
      when Group5='Территория проживания эмк' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
      when Group5='Регион проживания эмк' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
      when Group5='Куст проживания эмк' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
      when Group5='Проживает в Тюмени и юге области эмк' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
      when Group5='Пол' then decode(zsl.w,2,'Женщины',1,'Мужчины','Неопределен')
      when Group5='Возраст' then 'Возраст '||to_char(trunc(months_between(zsl.date_z_2,zsl.dr)/12),'00')
      when Group5='Трудоспособность' then (case when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<1 then 'Возраст до 1 года'
                                                when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<18 then 'Возраст до 18 лет'
                                                when (trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=55 and zsl.w=2)or(trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=60 and zsl.w=1)  then 'Старше трудоспособного возраста'
                                           else 'Трудоспособный' end)
      when Group5='Отделение по аналиту' then (select max(d.name) d_name   --в 10.2019 встречается дубль sl.sl_id
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id) 
      when Group5='Отделение группа по аналиту' then (select max(case when exists(select 1 from table(stat.parep.GetListDep(1)) t where t.id=d.id) then 'Дневной стационар'
                                                                      when exists(select 1 from table(stat.parep.GetListDep(0)) t where t.id=d.id) then 'Стационар'
                                                                 else 'АПП' end)
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id)                                                      
      when Group5='Принято' then (case when sl.accepted_tfoms=1 then 'Принят' else 'Не принят' end)
      when Group5='Первичный в случае' then (case when exists (select 1
                                         from HOSPITAL.Disease d2
                                              join HOSPITAL.ONCOLOGIC_DISEASE od2 on d2.ONCOLOGIC_DISEASE_ID = od2.ID
                                              join HOSPITAL.PROJECT p2 on d2.PROJECT_ID = p2.id
                                              join HOSPITAL.PROJECT_TYPE pt2 on p2.PROJECT_TYPE_ID = pt2.ID
                                              join HOSPITAL.DIAGNOSIS_TYPE dt2 on d2.DIAGNOSIS_TYPE_ID = dt2.ID
                                              join HOSPITAL.MKB m2 on d2.MKB_ID = m2.ID
                                        where  
                                              p2.id=p.id
                                              and (od2.SOURCE_CANCER_DATE is null)
                                              and pt2.CARE_TYPE_ID = 3
                                              and (od2.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                              and (dt2.Code in (2, 4, 7, 3))
                                              and not (exists (select d1.ID
                                                                 from HOSPITAL.Disease d1
                                                                      join HOSPITAL.PROJECT p1 on d1.PROJECT_ID = p1.ID
                                                                      join HOSPITAL.ONCOLOGIC_DISEASE od1 on d1.ONCOLOGIC_DISEASE_ID = od1.ID
                                                                      join HOSPITAL.DIAGNOSIS_TYPE dt1 on d1.DIAGNOSIS_TYPE_ID = dt1.ID
                                                                      join HOSPITAL.MKB m1 on d1.MKB_ID = m1.ID
                                                                where p1.CLIENT_ID = p2.CLIENT_ID
                                                                      and (od1.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                                                      and (dt1.Code in (2, 4, 7, 3))
                                                                      and d1.START_DATE < d2.START_DATE
                                                                      and substr(m1.code, 1, 3) = substr(m2.code, 1, 3)))                                              
                                    ) then 'Да' else 'Нет' end)   
      when Group5='Услуга в периоде сдачи' then (case when exists(
                                        select min(h.start_date) s,max(h.end_date) e 
                                          from registry_oms.schet sh join registry_oms.head h on h.id=sh.head_id
                                         where sh.year between y1 and y2 and sh.month between m1 and m2 and sh.type<>'00'
                                        having zsl.date_z_2 between min(h.start_date) and max(h.end_date)
                                    ) then 'Услуга в периоде сдачи' else 'Услуга вне периода сдачи'  end)        
      when Group5='Услуга подробно' then to_char(zsl.date_z_2,'dd.mm.yy')||' '||sl.code_usl||' '||sl.vid_vme||' '||t3.name||' на '||trim(to_char(zsl.sumv,'999999999990D00'))||' руб '||to_char(u.kol_usl)||'шт счет '||sh.nschet||' от '||to_char(sh.dschet,'dd.mm.yy') 
      when Group5='Медвмешательство присутсвует в случае эмк' then (case when exists(
                                        select 1
                                          from hospital.service_operation ro
                                               join hospital.service s on s.id=ro.service_id
                                               join hospital.service_type st on st.id=s.service_type_id
                                         where s.project_id=p.id and trunc(ro.operation_date)=zsl.date_z_2 and st.code2=sl.vid_vme 
                                               and ro.operation_type_id=4
                                               and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=10 and so1.id>ro.id)
                                               and exists (select pt.short_name t
                                                             from hospital.service_operation so
                                                                  join hospital.client_certificate cc on cc.id=so.client_certificate_id
                                                                  join hospital.client_certificate_type cct on cct.id=cc.certificate_type_id
                                                                  join hospital.pay_type pt on pt.id=cct.pay_type_id
                                                            where so.operation_type_id=2 and so.service_id=s.id and pt.id=801)
                                    ) then 'Есть' else 'Нет' end)   
      when Group5='Перечень выполненых услуг в случае эмк' then (
                     select listagg(c, '') WITHIN GROUP(order by d)
                       from (select stat.parep.GetServiceExecDate(s.id) d,
                                    case when trunc(stat.parep.GetServiceExecDate(s.id))=zsl.date_z_2 and st.code2=sl.vid_vme then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||'* '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<10 then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||' '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<13 then '.' end c
                               from hospital.service s left join hospital.service_type st on st.id=s.service_type_id
                              where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null and stat.parep.GetServicePayType(s.id)='ОМС'))                                                       
     end) Группа5,
    (case 
      when Group6='Период' then to_char(h.end_date,'mm')||' '||trim(to_char(h.end_date,'Month'))||' '||to_char(h.end_date,'yyyy')
      when Group6='Счет GUID' then lower(regexp_replace(regexp_replace(sh.head_id,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group6='Счет период' then to_char(sh.year,'0000')||' '||to_char(sh.month,'00')
      when Group6='Счет префикс файла' then (select t014.prefixfile from registry_oms.t014 t014 where t014.code=sh.type)
      when Group6='Счет наименование' then (select t014.name from registry_oms.t014 t014 where t014.code=sh.type) 
      when Group6='Счет номер' then 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00'))
      when Group6='Счет код типа' then sh.type
      when Group6='Счет вид реестра' then case when sh.type in ('01','14') then 'База'
                                               when sh.type in ('02','15') then 'Сверхбаза'
                                               when sh.type in ('10','22') then 'Межтер'
                                               when sh.type in ('03','23') then 'Высокотех'
                                               else sh.type end
      when Group6='Услуга вид помощи' then case when sl.code_usl in ('1.2.1.013','1.2.1.032') then 'Паллиативная помощь' 
                                                when zsl.usl_ok=1 then 'Стационарная помощь'
                                                when zsl.usl_ok=2 then 'Помощь в дневном стационаре'
                                                when zsl.usl_ok=3 then 'Амбулаторная помощь'
                                                else to_char(zsl.usl_ok) end     
      when Group6='Услуга код' then sl.code_usl
      when Group6='Услуга наименование' then t3.name
      when Group6='Услуга код наименование' then sl.code_usl||' '||t3.name
      when Group6='ВМП вид' then sl.vid_hmp  
      when Group6='ВМП метод' then sl.metod_hmp
      when Group6='Перечень медвмешательств' then u.vid_vmes
      when Group6='Медвмешательство код' then sl.vid_vme
      when Group6='Медвмешательство код наименование' then  sl.vid_vme||' '||(select max(v001.caption) from registry_oms.v001 v001 where v001.code=sl.vid_vme)   
      when Group6='Лекарственная схема код' then sl.code_sh
      when Group6='Лекарственная схема код наименование' then sl.code_sh||' '||(select max(r.mnn_drugs) from hospital.register_drug_schema r where r.code=sl.code_sh and sl.date_2 between r.start_date and r.end_date)
      when Group6='Тариф' then to_char(sl.tarif,'999999999990D00')  
      when Group6='Пациент GUID' then lower(regexp_replace(regexp_replace(zsl.ID_PAC,'(.{8})(.{4})(.{4})(.{4})(.{12})','\1-\2-\3-\4-\5'),'(.{2})(.{2})(.{2})(.{2}).(.{2})(.{2}).(.{2})(.{2})(.{18})','\4\3\2\1-\6\5-\8\7\9'))
      when Group6='Пациент' then zsl.fam||' '||zsl.im||' '||zsl.ot||' '||to_char(zsl.dr,'dd.mm.yyyy') 
      when Group6='Диагноз' then sl.ds1
      when Group6='Полис' then zsl.npolis
      when Group6='СМО' then zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group6='СМО тюменская' then (case when zsl.smo_ok='71000' then 'Тюменская' else 'Межтер' end)         
      when Group6='Полис СМО' then zsl.npolis||' '||zsl.smo||' '||zsl.smo_ok||' '||zsl.smo_nam 
      when Group6='Пациент эмк' then cl.sur_name||' '||cl.first_name||' '||cl.patr_name||' '||to_char(cl.birthday,'dd.mm.yyyy') 
      when Group6='Стацкарта эмк' then (select hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)||' '||stat.parep.GetShortDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group6='Случай эмк' then decode(p.project_type_id,2,'стац ','амб ')||to_char(p.id)||' с '||to_char(p.start_date,'dd.mm.yyyy')||' по '||to_char(p.end_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
      when Group6='Случай эмк тип' then decode(p.project_type_id,2,'стационарный','амбулаторный')
      when Group6='Лечащий врач эмк' then stat.parep.GetFIOWorker(p.worker_id) 
      when Group6='Диагноз эмк' then stat.parep.GetProjectMKBCode(1,p.id)
      when Group6='Отделение выбытия эмк' then (select to_char(stat.parep.GetDepOrder(stat.parep.GetOuttakeDepID(hc.id)),'00')||' '||stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)) from hospital.hospital_card hc where hc.project_id=p.id)
      when Group6='Тип стационара эмк' then decode((select substr(stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id)),1,7) 
                                                      from hospital.hospital_card hc where hc.project_id=p.id),null,'Амбулаторный','Дневной','Дневной стационар','Круглосуточный стационар')
      when Group6='Гражданство эмк' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
      when Group6='Инвалидность эмк' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
      when Group6='Умер эмк' then decode(p.project_result_type2_id, -34, 'Мертв', -25, 'Мертв', 'Жив')
      when Group6='Территория проживания эмк' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
      when Group6='Регион проживания эмк' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
      when Group6='Куст проживания эмк' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
      when Group6='Проживает в Тюмени и юге области эмк' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
      when Group6='Пол' then decode(zsl.w,2,'Женщины',1,'Мужчины','Неопределен')
      when Group6='Возраст' then 'Возраст '||to_char(trunc(months_between(zsl.date_z_2,zsl.dr)/12),'00')
      when Group6='Трудоспособность' then (case when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<1 then 'Возраст до 1 года'
                                                when trunc(months_between(zsl.date_z_2,zsl.dr)/12)<18 then 'Возраст до 18 лет'
                                                when (trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=55 and zsl.w=2)or(trunc(months_between(zsl.date_z_2,zsl.dr)/12)>=60 and zsl.w=1)  then 'Старше трудоспособного возраста'
                                           else 'Трудоспособный' end)
      when Group6='Отделение по аналиту' then (select max(d.name) d_name   --в 10.2019 встречается дубль sl.sl_id
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id)
      when Group6='Отделение группа по аналиту' then (select max(case when exists(select 1 from table(stat.parep.GetListDep(1)) t where t.id=d.id) then 'Дневной стационар'
                                                                      when exists(select 1 from table(stat.parep.GetListDep(0)) t where t.id=d.id) then 'Стационар'
                                                                 else 'АПП' end)
                                                 from hospital.refund_register_oms rro, hospital.department d
                                                where rro.project_id=p.id and rro.mid=sl.sl_id 
                                                      and rro.year=sh.year and rro.month=sh.month and d.id=rro.department_id)                                                       
      when Group6='Принято' then (case when sl.accepted_tfoms=1 then 'Принят' else 'Не принят' end)
      when Group6='Первичный в случае' then (case when exists (select 1
                                         from HOSPITAL.Disease d2
                                              join HOSPITAL.ONCOLOGIC_DISEASE od2 on d2.ONCOLOGIC_DISEASE_ID = od2.ID
                                              join HOSPITAL.PROJECT p2 on d2.PROJECT_ID = p2.id
                                              join HOSPITAL.PROJECT_TYPE pt2 on p2.PROJECT_TYPE_ID = pt2.ID
                                              join HOSPITAL.DIAGNOSIS_TYPE dt2 on d2.DIAGNOSIS_TYPE_ID = dt2.ID
                                              join HOSPITAL.MKB m2 on d2.MKB_ID = m2.ID
                                        where  
                                              p2.id=p.id
                                              and (od2.SOURCE_CANCER_DATE is null)
                                              and pt2.CARE_TYPE_ID = 3
                                              and (od2.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                              and (dt2.Code in (2, 4, 7, 3))
                                              and not (exists (select d1.ID
                                                                 from HOSPITAL.Disease d1
                                                                      join HOSPITAL.PROJECT p1 on d1.PROJECT_ID = p1.ID
                                                                      join HOSPITAL.ONCOLOGIC_DISEASE od1 on d1.ONCOLOGIC_DISEASE_ID = od1.ID
                                                                      join HOSPITAL.DIAGNOSIS_TYPE dt1 on d1.DIAGNOSIS_TYPE_ID = dt1.ID
                                                                      join HOSPITAL.MKB m1 on d1.MKB_ID = m1.ID
                                                                where p1.CLIENT_ID = p2.CLIENT_ID
                                                                      and (od1.CANCER_CLINIC_GROUP_ID in (3, 6, 4))
                                                                      and (dt1.Code in (2, 4, 7, 3))
                                                                      and d1.START_DATE < d2.START_DATE
                                                                      and substr(m1.code, 1, 3) = substr(m2.code, 1, 3)))                                              
                                    ) then 'Да' else 'Нет' end) 
      when Group6='Услуга в периоде сдачи' then (case when exists(
                                        select min(h.start_date) s,max(h.end_date) e 
                                          from registry_oms.schet sh join registry_oms.head h on h.id=sh.head_id
                                         where sh.year between y1 and y2 and sh.month between m1 and m2 and sh.type<>'00'
                                        having zsl.date_z_2 between min(h.start_date) and max(h.end_date)
                                    ) then 'Услуга в периоде сдачи' else 'Услуга вне периода сдачи'  end)        
      when Group6='Услуга подробно' then to_char(zsl.date_z_2,'dd.mm.yy')||' '||sl.code_usl||' '||sl.vid_vme||' '||t3.name||' на '||trim(to_char(zsl.sumv,'999999999990D00'))||' руб '||to_char(u.kol_usl)||'шт счет '||sh.nschet||' от '||to_char(sh.dschet,'dd.mm.yy') 
      when Group6='Медвмешательство присутсвует в случае эмк' then (case when exists(
                                        select 1
                                          from hospital.service_operation ro
                                               join hospital.service s on s.id=ro.service_id
                                               join hospital.service_type st on st.id=s.service_type_id
                                         where s.project_id=p.id and trunc(ro.operation_date)=zsl.date_z_2 and st.code2=sl.vid_vme 
                                               and ro.operation_type_id=4
                                               and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=10 and so1.id>ro.id)
                                               and exists (select pt.short_name t
                                                             from hospital.service_operation so
                                                                  join hospital.client_certificate cc on cc.id=so.client_certificate_id
                                                                  join hospital.client_certificate_type cct on cct.id=cc.certificate_type_id
                                                                  join hospital.pay_type pt on pt.id=cct.pay_type_id
                                                            where so.operation_type_id=2 and so.service_id=s.id and pt.id=801)
                                    ) then 'Есть' else 'Нет' end)   
      when Group6='Перечень выполненых услуг в случае эмк' then (
                     select listagg(c, '') WITHIN GROUP(order by d)
                       from (select stat.parep.GetServiceExecDate(s.id) d,
                                    case when trunc(stat.parep.GetServiceExecDate(s.id))=zsl.date_z_2 and st.code2=sl.vid_vme then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||'* '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<10 then to_char(stat.parep.GetServiceExecDate(s.id),'dd.mm.yy ')||st.code||' '||st.code2||' '
                                         when row_number() over(order by stat.parep.GetServiceExecDate(s.id))<13 then '.' end c
                               from hospital.service s left join hospital.service_type st on st.id=s.service_type_id
                              where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null and stat.parep.GetServicePayType(s.id)='ОМС'))
                                                                                  

     end) Группа6,
    sh.id ИД_счета, 
    sh.head_id GUID_счета,
    sh.year Год,
    sh.month Месяц,
    h.start_date Период_с,
    h.end_date Период_по,
    zsl.id ZSL_ID,  --законченый случай
    p.client_id,
    zsl.id_pac,
    zsl.fam||' '||zsl.im||' '||zsl.ot||' '||to_char(zsl.dr,'dd.mm.yyyy') Пациент,
    zsl.smo СМО,
    zsl.date_z_1 Дата_лечения_с,
    zsl.date_z_2 Дата_лечения_по,
    zsl.sumv Сумма_счет,
    sl.id SL_ID,    --сведения о случае
    sl.code_usl Код_услуги,
    t3.name Услуга,
    sl.sum_m Сумма,
    sl.accepted_tfoms Принят_ТФОМС,
    sl.accepted_smo Принят_СМО,
    u.kol_usl Услуг,
    u.kol_usl_npl Услуг_неполных,
    sl.kd Койкодни 
  from
   dd, registry_oms.schet sh
   join registry_oms.z_sl zsl on zsl.schet_id=sh.id 
   join registry_oms.sl sl on sl.z_sl_id=zsl.id
   join registry_oms.head h on h.id=sl.head_id
   left join registry_oms.t003 t3 on sl.code_usl = t3.code and t3.year=sh.year
   outer apply
         (select sum(u.kol_usl) as kol_usl,
                 sum(case when nvl(u.nplcoefficient,1)<>1 then u.kol_usl end) as kol_usl_npl,
                 nvl(u.nplcoefficient,1) coeff,
                 listagg(u.vid_vme, ', ') WITHIN GROUP(order by u.vid_vme) vid_vmes
            from registry_oms.usl u 
           where u.sl_id = sl.id and u.is_main = 1
           group by u.nplcoefficient) u            
   left join hospital.project p on p.id=zsl.project_id
   left join hospital.client cl on cl.id=p.client_id
  where 
   sh.year between y1 and y2 and 
   sh.month between m1 and m2 and 
   sh.type<>'00' and sl.accepted_tfoms in (acce-1,1)
)
where
 fn1 = case when regexp_like(Группа1||' ',fl1,'i') then 0 else 1 end and
 fn2 = case when regexp_like(Группа2||' ',fl2,'i') then 0 else 1 end and
 fn3 = case when regexp_like(Группа3||' ',fl3,'i') then 0 else 1 end and
 fn4 = case when regexp_like(Группа4||' ',fl4,'i') then 0 else 1 end and
 fn5 = case when regexp_like(Группа5||' ',fl5,'i') then 0 else 1 end and
 fn6 = case when regexp_like(Группа6||' ',fl6,'i') then 0 else 1 end
group by
 Группа1,Группа2,Группа3,Группа4,Группа5,Группа6
order by
 Группа1,Группа2,Группа3,Группа4,Группа5,Группа6
