--выписаны, универсальный отчет
--для FReport
--10 06 2019, протасов аа
--14 06 2019
--17 06 2019
--18 06 2019
--21 06 2019
--25 06 2019
--15 07 2019  лек схема поменьше
--18 07 2019 выбор - отобразить в процентах
--25 07 2019 ХБС
--26 07 2019 Вид стационара
--30 07 2019 GetDrugs   из паруса инфа
--06 08 2019 Наличие хирургических операций в выписке
--15 08 2019 по периодам
--02 09 2019 Списаные наркотики, Наличие случая В ТФОМС (Принято, Отправлено, Отсутсвует)
--18 10 2019 + комбинации препаратов таргет, гормоно, все из выписок
--15 11 2019 regexp_like
--15 11 2019 Наличие в федрегистре
--15 11 2019 наличие лекарственной терапии
--15 11 2019 осложнения вывести
--22 11 2019 поликлиника из адреса поликлиника из направления
--28 11 2019 фильтрация с без
--02 12 2019 цель госпитализации, обстоятельства выявления, Проживает в Тюмени и юге области
--04 12 2019 В ТФОМС различные группы..
--11 12 2019 куст проживания
--17 12 2019 В ТФОМС принято с медвмешательством
--30 06 2020 Вид стационара испр, КСГ - full_code
--12 08 2020 выписаны в календарный год, выписаны в отчетный год 26-25 число, первая госпитализация
--02 10 2020 КСГ тип, СМО тюменская, Полис
--26 10 2020 Койкодней, Врач химиотерапии, Врач гормонотерапии, Врач таргетной терапии, Врачи лекарственной терапии, Врач лучевой терапии
--07 12 2020 Возрастная группа вместо трудоспособность
--19 01 2021 Экспортирован в федрегистр


/*
with dd as (select :DTF dtf, :DTT dtt,
            :VGROUP1 vGroup1, :VGROUP2 vGroup2, :VGROUP3 vGroup3, :VGROUP4 vGroup4, :VGROUP5 vGroup5, :VGROUP6 vGroup6,
              :FL1 fl1, :FL2 fl2, :FL3 fl3, :FL4 fl4, :FL5 fl5, :FL6 fl6,
                :fn1 fn1, :fn2 fn2, :fn3 fn3, :fn4 fn4, :fn5 fn5, :fn6 fn6,
                :chPct chPct  from dual),
     dep as (select * from table(stat.parep.GetListDep(:DS)) )
*/
with dd as (select to_date('01.01.2018','dd.mm.yyyy') dtf, to_date('25.12.2020','dd.mm.yyyy') dtt,
              ''  vGroup1, '' vGroup2, '' vGroup3, ''  vGroup4, 'Выписан в отчетный год 26-25 число' vGroup5, 'Экспортирован в федрегистр' vGroup6,
--              ''  vGroup1, '' vGroup2, '' vGroup3, ''  vGroup4, 'Отделение' vGroup5, 'Врачи лекарственной терапии' vGroup6,
--              ''  vGroup1, '' vGroup2, '' vGroup3, ''  vGroup4, 'Отделение' vGroup5, 'Койкодней' vGroup6,
--            'Вид оплаты'  vGroup1, 'Страховая компания' vGroup2, 'Пациент' vGroup3, ''  vGroup4, 'СМО тюменская' vGroup5, 'Полис' vGroup6,
--            'Куст проживания'  vGroup1, '' vGroup2, '' vGroup3, 'Наличие в ТФОМС'  vGroup4, 'В ТФОМС принято СМО тюменской' vGroup5, 'В ТФОМС принято с ВМП' vGroup6,
--            'Регион проживания'  vGroup1, '' vGroup2, '' vGroup3, ''  vGroup4, '' vGroup5, 'Проживает в Тюмени и юге области' vGroup6,
--            ''  vGroup1, '' vGroup2, '' vGroup3, ''  vGroup4, '' vGroup5, 'Цель госпитализации в выписке' vGroup6,
--            ''  vGroup1, '' vGroup2, '' vGroup3, ''  vGroup4, '' vGroup5, 'Комбинации препаратов гормонотерапии' vGroup6,
--            '*' fl1, '*' fl2, '*' fl3, '*' fl4, '*' fl5, 'C34|C50' fl6, 0 chPct from dual),
--            '*' fl1, '*' fl2, '^ $' fl3, '*' fl4, '^I гр|^II гр' fl5, 'c34|C50' fl6, 0 chPct from dual),
--              'ОМС' fl1, '*' fl2, '*' fl3, '*' fl4, 'СМО без окато' fl5, '*' fl6,
              '*' fl1, '*' fl2, '^ $' fl3, '*' fl4, '*' fl5, '*' fl6,
              0 fn1, 0 fn2, 0 fn3, 0 fn4, 0 fn5, 0 fn6,
              0 chPct from dual),
     dep as (select * from table(stat.parep.GetListDep(2)) )


select
  Группа1,
  Группа2,
  Группа3,
  Группа4,
  Группа5,
  Группа6,
  case when chPct=0 then count(hospital_card_id) else 100*RATIO_TO_REPORT(count(hospital_card_id)) OVER () end Госпитализаций,
  count(distinct client_id) Пациентов,
  case when chPct=0 then sum(kdays) else 100*RATIO_TO_REPORT(sum(kdays)) OVER () end Койкодней
from
dd,(
select
 (case when vGroup1='Пациент' then stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
       when vGroup1='Стацкарта' then hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)
       when vGroup1='Территория проживания' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
       when vGroup1='Регион проживания' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup1='Куст проживания' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup1='Проживает в Тюмени и юге области' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
       when vGroup1='Поликлиника из адреса' then stat.parep.GetCancerPolyclinic(stat.parep.GetCancerPolyclinicID(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup1='Поликлиника из направления' then stat.parep.GetDirectPolyclinic(cl.id,hc.receive_date)
       when vGroup1='Пол' then decode(cl.sex,'Ж','Женщины','М','Мужчины','Неопределен')
       when vGroup1='Возраст' then 'Возраст '||to_char(stat.parep.GetClientAge(cl.id,hc.outtake_date),'00' )
       when vGroup1='Возрастная группа' then (case when stat.parep.GetClientAge(cl.id,hc.outtake_date)<1 then   'Возраст до 1 года'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<3 then   'Возраст от 1 до 3 лет'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<18 then  'Возраст от 3 до 18 лет'
                                                   when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 'Старше трудоспособного возраста'
                                             else 'Возраст трудоспособный' end)
       when vGroup1='Инвалидность' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
       when vGroup1='Этническая группа' then (select eg.name from hospital.ethnic_group eg where eg.id=cl.ethnic_group)
       when vGroup1='Социально-профессиональная группа' then (select sg.name from hospital.social_prof_group sg where sg.id=cl.profession)
       when vGroup1='Гражданство' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
       when vGroup1='Умерший' then decode(p.project_result_type2_id, -34, 'Мертвые', -25, 'Мертвые', 'Живые')
       when vGroup1='Номер госпитализации' then (select 'Госпитализация номер '||to_char(count(hc1.id)) from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)
       when vGroup1='Первая госпитализация' then case when (select count(hc1.id) from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)=1 then 'Первая госпитализация' else 'Повторная госпитализация' end
       when vGroup1='Лечащий врач' then stat.parep.GetFIOWorker(p.worker_id)||' '||stat.parep.GetWorkerSpeciality(p.worker_id)
       when vGroup1='Отделение' then to_char(dep.ordernum,'00')||' '||stat.parep.GetDepname(dep.id)
       when vGroup1='Вид стационара' then dep.dayhospital
       when vGroup1='Обстоятельства выявления в выписке' then (select stat.parep.GetCancerDetectionCircum(cas.detection_circumstances) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Цель госпитализации в выписке' then (select stat.parep.GetCancerHospitalizationGoal(cas.hospitalization_goal) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Результат лечения в выписке' then (select stat.parep.GetCancerTreatmentResult(cas.hosp_treat_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Характер лечения в выписке' then (select stat.parep.GetCancerHospitalizationResult(cas.hospitalization_resid_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Диагноз' then (select substr(mkb.code,1,3)||' '||m.n
                                      from hospital.disease dis
                                           left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                           left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkb.code,1,3)
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup1='Хронический болевой синдром' then (select stat.parep.GetHBS(dis.chronic_pain_syndrome)
                                      from hospital.disease dis
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup1='Клиническая группа' then (select 'Клиническая группа '||cg.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_clinic_group cg on cg.id=od.cancer_clinic_group_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup1='Стадия опухоли' then (select stat.parep.GetCancerStage(od.cancer_stage_value)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup1='Морфологический тип опухоли' then (select t.code||' '||t.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_type t on t.id=od.cancer_type_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup1='TNM' then (select 'T'||od.tnm_t||' N'||od.tnm_n||' M'||od.tnm_m
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup1='Локализации метастазов' then (select stat.parep.GetCancerMetastasisAreas(od.metastasis_areas)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup1='Метод подтверждения' then (select stat.parep.GetCancerConfirmMethods(od.disease_confirm_methods)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup1='Диагноз в выписке' then (select substr(mkbcrd.code,1,3)||' '||m.n
                                                from hospital.cancer_summary cas
                                                     left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                     left join hospital.mkb mkbcrd on mkbcrd.id=crd.mkb_id
                                                     left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkbcrd.code,1,3)
                                               where cas.hospital_card_id=hc.id)
       when vGroup1='Клиническая группа в выписке' then (select 'Клиническая группа в выписке '||cg.name
                                                           from hospital.cancer_summary cas
                                                                left join hospital.cancer_clinic_group cg on cg.id=cas.cancer_clinic_group_id
                                                          where cas.hospital_card_id=hc.id)
       when vGroup1='Стадия опухоли в выписке' then (select stat.parep.GetCancerStage(cas.cancer_stage)
                                                           from hospital.cancer_summary cas
                                                          where cas.hospital_card_id=hc.id)
       when vGroup1='Морфологический тип опухоли в выписке' then (select ct.code||' '||ct.name
                                                                    from hospital.cancer_summary cas
                                                                         left join hospital.cancer_type ct on ct.id=cas.cancer_type_id
                                                                   where cas.hospital_card_id=hc.id)
       when vGroup1='TNM в выписке' then (select 'T'||cas.tnm_t||' N'||cas.tnm_n||' M'||cas.tnm_m
                                            from hospital.cancer_summary cas
                                           where cas.hospital_card_id=hc.id)
       when vGroup1='Локализации метастазов в выписке' then (select stat.parep.GetCancerMetastasisAreas(cas.metastasis_areas)
                                                               from hospital.cancer_summary cas
                                                              where cas.hospital_card_id=hc.id)
       when vGroup1='Метод подтверждения в выписке' then (select stat.parep.GetCancerConfirmMethods(cas.disease_confirm_methods)
                                                            from hospital.cancer_summary cas
                                                           where cas.hospital_card_id=hc.id)
       when vGroup1='Вид диагноза' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                     when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                else 'Неопухолевый диагноз' end
                                           from hospital.disease dis left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                          where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                                and not exists (select 1 from hospital.disease disx where disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)
                                         )
       when vGroup1='Вид диагноза по выписке' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                                when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                           else 'Неопухолевый диагноз' end
                                                      from hospital.cancer_summary cas
                                                           left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                           left join hospital.mkb mkb on mkb.id=crd.mkb_id
                                                     where cas.hospital_card_id=hc.id
                                                    )
       when vGroup1='Лечение' then stat.parep.GetCancerTreatment(hc.id)
       when vGroup1='Вид оплаты' then stat.parep.GetProjectPayType(p.id)
       when vGroup1='В ТФОМС принято СМО тюменской' then (select max(case when substr(zsl.smo,1,2)='72' then 'Да' else 'Нет' end)
                                                         from registry_oms.z_sl zsl
                                                              join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        where zsl.project_id=p.id)
       when vGroup1='В ТФОМС принято СМО' then (select max(zsl.smo||' '||smo.name)
                                                   from registry_oms.z_sl zsl
                                                        join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        left join registry_oms.smo smo on smo.code=zsl.smo
                                                  where zsl.project_id=p.id)
       when vGroup1='В ТФОМС принято с доктором' then (select listagg(s,', ') within group(order by s)
                                                  from (select distinct sl.iddokt||' '||t005.fam||' '||t005.im||' '||t005.ot||' '||sl.prvs||' '||t005.caption as s
                                                          from registry_oms.z_sl zsl
                                                               join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                               left join registry_oms.t005 t005 on t005.iddokt=sl.iddokt and t005.prvs=sl.prvs
                                                         where zsl.project_id=p.id) )
       when vGroup1='В ТФОМС принято с услугой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_usl||' '||t003.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.t003 t003 on t003.code=sl.code_usl and t003.year=to_number(to_char(hc.outtake_date,'yyyy'))
                                                          where zsl.project_id=p.id) )
       when vGroup1='В ТФОМС принято с лекарственной схемой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_sh||' '||sh.mnn_drugs as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.code_sh is not null
                                                                left join hospital.register_drug_schema sh on sh.code=sl.code_sh
                                                                          and hc.outtake_date between nvl(sh.start_date,to_date('25.12.2017','dd.mm.yyyy')) and sh.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup1='В ТФОМС принято в счете' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00')) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.schet sh on sh.id=zsl.schet_id
                                                          where zsl.project_id=p.id) )
       when vGroup1='В ТФОМС принято с ВМП' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.vid_hmp||'.'||sl.metod_hmp||' '||m.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.metod_hmp is not null
                                                                left join hospital.hitech_treatment_method m on m.id=sl.metod_hmp and m.hitech_treatment_code=sl.vid_hmp
                                                                          and hc.outtake_date between m.start_date and m.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup1='В ТФОМС принято с медвмешательством' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct trim(nvl(usl.vid_vme,sl.vid_vme)||' '||v.capt) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.usl usl on usl.sl_id=sl.id and usl.is_main=1
                                                                left join (select v001.code, max(v001.caption) capt
                                                                             from registry_oms.v001 v001 group by v001.code
                                                                           ) v on v.code=nvl(usl.vid_vme,sl.vid_vme)
                                                          where zsl.project_id=p.id) )
       when vGroup1='Страховая компания' then (select o.name
                                                 from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                                where cc.id=p.client_certificate_id )
       when vGroup1='Полис' then (select cc.num
                                                from hospital.client_certificate cc
                                               where cc.id=p.client_certificate_id )                                                
       when vGroup1='СМО тюменская' then (select (case when o.okato='71000' then 'Тюменская'
                                                       when o.okato<>'71000' then 'Межтер' else 'СМО без окато' end)
                                            from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                           where cc.id=p.client_certificate_id)                                               
       when vGroup1='КСГ тип' then (select stat.parep.GetCSGType(pcsg.group_id)
                                      from hospital.project_clinic_stat_group pcsg
                                     where pcsg.project_id=p.id)  
       when vGroup1='КСГ' then (select csg.full_code||' '||csg.name
                                  from hospital.project_clinic_stat_group pcsg left join hospital.clinical_statistic_group csg on csg.id=pcsg.group_id
                                 where pcsg.project_id=p.id)
       when vGroup1='Лекарственная схема' then (select sh.code||' '||InitCap(sh.mnn_drugs)
                                                  from hospital.project_clinic_stat_group pcsg left join hospital.register_drug_schema sh on sh.id=pcsg.drug_schema_id
                                                 where pcsg.project_id=p.id)
       when vGroup1='Комбинации препаратов химиолечения' then (select stat.parep.GetCancerListDrugs(cas.id,'ChemoTherapeutic')
                                                                 from hospital.cancer_summary cas
                                                                where cas.hospital_card_id=hc.id)
       when vGroup1='Комбинации препаратов гормонотерапии' then (select stat.parep.GetCancerListDrugs(cas.id,'HormoneImmuneTherapeutic')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup1='Комбинации препаратов таргетной терапии' then (select stat.parep.GetCancerListDrugs(cas.id,'Targeted')
                                                                      from hospital.cancer_summary cas
                                                                     where cas.hospital_card_id=hc.id)
       when vGroup1='Комбинации всех препаратов в выписке' then (select stat.parep.GetCancerListDrugs(cas.id,'')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup1='Применённые препараты' then stat.parep.GetDrugs(p.id,'name')
       when vGroup1='Применённые препараты по МНН' then stat.parep.GetDrugs(p.id,'mnn')
       when vGroup1='Применённые препараты по типу' then stat.parep.GetDrugs(p.id,'type')
       when vGroup1='Хирургические операции' then (select listagg(decode(st.id,null,'нет услуги',st.code||' '||substr(st.name,1,100)), ', ') WITHIN GROUP(order by s.start_date, s.id) text
                                                             from hospital.surgery s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and s.execute_state='Done'
                                                           group by s.project_id)
       when vGroup1='Хирургические операции из выписок' then (select listagg(decode(cst.id,null,'нет кода',cst.code||' '||substr(cst.name,1,100)), ', ') WITHIN GROUP(order by csst.start_date, csst.surgery_id, csst.id) text
                                                             from hospital.cancer_summary cas
                                                                  join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                                                                  left join hospital.cancer_surgery_type cst on cst.id=csst.surgery_type_id
                                                            where cas.hospital_card_id=hc.id
                                                           group by csst.cancer_summary_id)
       when vGroup1='Лучевые воздействия из выписок' then (select listagg(ra1.name||' '||crtm1.summary_dose, ', ') WITHIN GROUP(order by ra1.name) text
                                                                   from hospital.cancer_summary cas
                                                                        join hospital.cancer_sum_rad_treat_meth crtm1 on crtm1.cancer_summary_id=cas.id
                                                                        left join hospital.radiation_area ra1 on ra1.id=crtm1.area_id
                                                                  where cas.hospital_card_id=hc.id
                                                                 group by crtm1.cancer_summary_id)
       when vGroup1='Перечень выполненых услуг' then (select listagg(c, ', ') WITHIN GROUP(order by c) text
                                                        from(select distinct st.code c
                                                             from hospital.service s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null) )
       when vGroup1='Наличие хирургических операций' then (case when exists(select 1 from hospital.surgery s
                                                           where s.project_id=p.id and s.execute_state='Done')
                                                           then 'Есть хирургические операции' else 'Нет хирургических операций' end)
       when vGroup1='Наличие хирургических операций в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть хирургические операции в выписке' else 'Нет хирургических операций в выписке' end)
       when vGroup1='Наличие лучевых воздействий в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_rad_treat_meth crtm on crtm.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лучевые воздействия в выписке' else 'Нет лучевых воздействий в выписке' end)
       when vGroup1='Наличие химиотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='ChemoTherapeutic')
                         then 'Есть химиотерапия в выписке' else 'Нет химиотерапии в выписке' end)
       when vGroup1='Наличие гормонотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='HormoneImmuneTherapeutic')
                         then 'Есть гормонотерапии в выписке' else 'Нет гормонотерапии в выписке' end)
       when vGroup1='Наличие таргетной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='Targeted')
                         then 'Есть таргетные терапии в выписке' else 'Нет таргетной терапии в выписке' end)
       when vGroup1='Наличие лекарственной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лекарственные терапии в выписке' else 'Нет лекарственной терапии в выписке' end)
       when vGroup1='Выписан в день недели' then to_char(hc.outtake_date,'D Day')
       when vGroup1='Выписан в календарный год' then to_char(hc.outtake_date,'YYYY')||' год '
       when vGroup1='Выписан в календарный квартал' then to_char(hc.outtake_date,'Q')||' квартал '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup1='Выписан в календарный месяц' then 'Месяц '||trim(to_char(hc.outtake_date,'MM, month'))||' '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup1='Выписан в отчетный год 26-25 число' then to_char(hc.outtake_date+6,'YYYY')||' год '  
       when vGroup1='Выписан в отчетный год 21-20 число' then to_char(hc.outtake_date+11,'YYYY')||' год '  
       when vGroup1='Выписан в отчетный квартал 26-25 число' then to_char(add_months(hc.outtake_date-25,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup1='Выписан в отчетный квартал 21-20 число' then to_char(add_months(hc.outtake_date-20,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup1='Выписан в отчетный месяц 26-25 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-25,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup1='Выписан в отчетный месяц 21-20 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-20,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup1='Наличие в ТФОМС' then (case when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 1 and zsl.project_id=p.id) then 'Принято в ТФОМС'
                                                 when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 0 and zsl.project_id=p.id) then 'Непринято в ТФОМС'
                                                 else 'Неотправлено в ТФОМС' end )

       when vGroup1='Наличие в федрегистре' then (case when stat.parep.FindFederalPatient(cl.sur_name,cl.first_name,cl.patr_name,cl.birthday) is not null
                                                  then 'Присутсвует в федрегистре' else 'Отсутсвует в федрегистре' end )
       when vGroup1='Экспортирован в федрегистр' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_document_operation cdo on cdo.document_id=cas.document_id and cdo.operation='ExportPatientCard'
                           where cas.hospital_card_id=hc.id)
                         then 'Стацкарта экспортирована в федрегистр' else 'Стацкарта не экспортирована в федрегистр' end)                                                    
       when vGroup1='Списано наркотических' then stat.parep.GetDrugsParus(hc.id,'НАРКОТИКИ СИЛЬНОДЕЙСТВУЮЩИЕ')
       when vGroup1='Осложнения анестезии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Anesthesia') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Осложнения постоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Postoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Осложнения интраоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Intraoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Осложнения лучевой терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Radiation') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Осложнения химиотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'ChemoTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Осложнения гормонотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'HormoneImmuneTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Осложнения таргетной терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Targeted') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Осложнения любые в выписке' then (select stat.parep.GetCancerComplic(cas.id) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup1='Врач химиотерапии' then (select stat.parep.GetFIOWorker(cas.chemother_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.chemother_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup1='Врач гормонотерапии' then (select stat.parep.GetFIOWorker(cas.hormone_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.hormone_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup1='Врач таргетной терапии' then (select stat.parep.GetFIOWorker(cas.target_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.target_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup1='Врачи лекарственной терапии' then (select trim(nvl2(cas.chemother_treat_worker_id,'химио '||stat.parep.GetShortFIOWorker(cas.chemother_treat_worker_id),'')
                                                             ||' '||nvl2(cas.hormone_treat_worker_id,'гормоно '||stat.parep.GetShortFIOWorker(cas.hormone_treat_worker_id),'')
                                                             ||' '||nvl2(cas.target_treat_worker_id,'таргет '||stat.parep.GetShortFIOWorker(cas.target_treat_worker_id),'') )
                                                          from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup1='Врач лучевой терапии' then (select stat.parep.GetFIOWorker(cas.rad_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.rad_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)           
       when vGroup1='Койкодней' then (case when stat.parep.GetBedDays(hc.id) between 0 and 1 then '00..01 койкодня'
                                           when stat.parep.GetBedDays(hc.id) between 2 and 3 then '02..03 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 4 and 6 then '04..06 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 7 and 9 then '07..09 койкодней' 
                                           when stat.parep.GetBedDays(hc.id) between 10 and 13 then '10..13 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 14 and 19 then '14..19 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 20 and 29 then '20..29 койкодней'  
                                           when stat.parep.GetBedDays(hc.id) between 30 and 49 then '30..49 койкодней'  
                                      else '50 и более койкодней' end)
  
  else null end) Группа1,
 (case when vGroup2='Пациент' then stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
       when vGroup2='Стацкарта' then hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)
       when vGroup2='Территория проживания' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
       when vGroup2='Регион проживания' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup2='Куст проживания' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup2='Проживает в Тюмени и юге области' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
       when vGroup2='Поликлиника из адреса' then stat.parep.GetCancerPolyclinic(stat.parep.GetCancerPolyclinicID(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup2='Поликлиника из направления' then stat.parep.GetDirectPolyclinic(cl.id,hc.receive_date)
       when vGroup2='Пол' then decode(cl.sex,'Ж','Женщины','М','Мужчины','Неопределен')
       when vGroup2='Возраст' then 'Возраст '||to_char(stat.parep.GetClientAge(cl.id,hc.outtake_date),'00' )
       when vGroup2='Возрастная группа' then (case when stat.parep.GetClientAge(cl.id,hc.outtake_date)<1 then   'Возраст до 1 года'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<3 then   'Возраст от 1 до 3 лет'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<18 then  'Возраст от 3 до 18 лет'
                                                   when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 'Старше трудоспособного возраста'
                                             else 'Возраст трудоспособный' end)
       when vGroup2='Инвалидность' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
       when vGroup2='Этническая группа' then (select eg.name from hospital.ethnic_group eg where eg.id=cl.ethnic_group)
       when vGroup2='Социально-профессиональная группа' then (select sg.name from hospital.social_prof_group sg where sg.id=cl.profession)
       when vGroup2='Гражданство' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
       when vGroup2='Умерший' then decode(p.project_result_type2_id, -34, 'Мертвые', -25, 'Мертвые', 'Живые')
       when vGroup2='Номер госпитализации' then (select 'Госпитализация номер '||to_char(count(hc1.id),'00') from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)
       when vGroup2='Первая госпитализация' then case when (select count(hc1.id) from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)=1 then 'Первая госпитализация' else 'Повторная госпитализация' end
       when vGroup2='Лечащий врач' then stat.parep.GetFIOWorker(p.worker_id)||' '||stat.parep.GetWorkerSpeciality(p.worker_id)
       when vGroup2='Отделение' then to_char(dep.ordernum,'00')||' '||stat.parep.GetDepname(dep.id)
       when vGroup2='Вид стационара' then dep.dayhospital
       when vGroup2='Обстоятельства выявления в выписке' then (select stat.parep.GetCancerDetectionCircum(cas.detection_circumstances) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Цель госпитализации в выписке' then (select stat.parep.GetCancerHospitalizationGoal(cas.hospitalization_goal) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Результат лечения в выписке' then (select stat.parep.GetCancerTreatmentResult(cas.hosp_treat_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Характер лечения в выписке' then (select stat.parep.GetCancerHospitalizationResult(cas.hospitalization_resid_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Диагноз' then (select substr(mkb.code,1,3)||' '||m.n
                                      from hospital.disease dis
                                           left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                           left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkb.code,1,3)
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup2='Хронический болевой синдром' then (select stat.parep.GetHBS(dis.chronic_pain_syndrome)
                                      from hospital.disease dis
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup2='Клиническая группа' then (select 'Клиническая группа '||cg.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_clinic_group cg on cg.id=od.cancer_clinic_group_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup2='Стадия опухоли' then (select stat.parep.GetCancerStage(od.cancer_stage_value)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup2='Морфологический тип опухоли' then (select t.code||' '||t.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_type t on t.id=od.cancer_type_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup2='TNM' then (select 'T'||od.tnm_t||' N'||od.tnm_n||' M'||od.tnm_m
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup2='Локализации метастазов' then (select stat.parep.GetCancerMetastasisAreas(od.metastasis_areas)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup2='Метод подтверждения' then (select stat.parep.GetCancerConfirmMethods(od.disease_confirm_methods)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup2='Диагноз в выписке' then (select substr(mkbcrd.code,1,3)||' '||m.n
                                                from hospital.cancer_summary cas
                                                     left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                     left join hospital.mkb mkbcrd on mkbcrd.id=crd.mkb_id
                                                     left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkbcrd.code,1,3)
                                               where cas.hospital_card_id=hc.id)
       when vGroup2='Клиническая группа в выписке' then (select 'Клиническая группа в выписке '||cg.name
                                                           from hospital.cancer_summary cas
                                                                left join hospital.cancer_clinic_group cg on cg.id=cas.cancer_clinic_group_id
                                                          where cas.hospital_card_id=hc.id)
       when vGroup2='Стадия опухоли в выписке' then (select stat.parep.GetCancerStage(cas.cancer_stage)
                                                           from hospital.cancer_summary cas
                                                          where cas.hospital_card_id=hc.id)
       when vGroup2='Морфологический тип опухоли в выписке' then (select ct.code||' '||ct.name
                                                                    from hospital.cancer_summary cas
                                                                         left join hospital.cancer_type ct on ct.id=cas.cancer_type_id
                                                                   where cas.hospital_card_id=hc.id)
       when vGroup2='TNM в выписке' then (select 'T'||cas.tnm_t||' N'||cas.tnm_n||' M'||cas.tnm_m
                                            from hospital.cancer_summary cas
                                           where cas.hospital_card_id=hc.id)
       when vGroup2='Локализации метастазов в выписке' then (select stat.parep.GetCancerMetastasisAreas(cas.metastasis_areas)
                                                               from hospital.cancer_summary cas
                                                              where cas.hospital_card_id=hc.id)
       when vGroup2='Метод подтверждения в выписке' then (select stat.parep.GetCancerConfirmMethods(cas.disease_confirm_methods)
                                                            from hospital.cancer_summary cas
                                                           where cas.hospital_card_id=hc.id)
       when vGroup2='Вид диагноза' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                     when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                else 'Неопухолевый диагноз' end
                                           from hospital.disease dis left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                          where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                                and not exists (select 1 from hospital.disease disx where disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)
                                         )
       when vGroup2='Вид диагноза по выписке' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                                when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                           else 'Неопухолевый диагноз' end
                                                      from hospital.cancer_summary cas
                                                           left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                           left join hospital.mkb mkb on mkb.id=crd.mkb_id
                                                     where cas.hospital_card_id=hc.id
                                                    )
       when vGroup2='Лечение' then stat.parep.GetCancerTreatment(hc.id)
       when vGroup2='Вид оплаты' then stat.parep.GetProjectPayType(p.id)
       when vGroup2='В ТФОМС принято СМО тюменской' then (select max(case when substr(zsl.smo,1,2)='72' then 'Да' else 'Нет' end)
                                                         from registry_oms.z_sl zsl
                                                              join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        where zsl.project_id=p.id)
       when vGroup2='В ТФОМС принято СМО' then (select max(zsl.smo||' '||smo.name)
                                                   from registry_oms.z_sl zsl
                                                        join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        left join registry_oms.smo smo on smo.code=zsl.smo
                                                  where zsl.project_id=p.id)
       when vGroup2='В ТФОМС принято с доктором' then (select listagg(s,', ') within group(order by s)
                                                  from (select distinct sl.iddokt||' '||t005.fam||' '||t005.im||' '||t005.ot||' '||sl.prvs||' '||t005.caption as s
                                                          from registry_oms.z_sl zsl
                                                               join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                               left join registry_oms.t005 t005 on t005.iddokt=sl.iddokt and t005.prvs=sl.prvs
                                                         where zsl.project_id=p.id) )
       when vGroup2='В ТФОМС принято с услугой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_usl||' '||t003.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.t003 t003 on t003.code=sl.code_usl and t003.year=to_number(to_char(hc.outtake_date,'yyyy'))
                                                          where zsl.project_id=p.id) )
       when vGroup2='В ТФОМС принято с лекарственной схемой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_sh||' '||sh.mnn_drugs as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.code_sh is not null
                                                                left join hospital.register_drug_schema sh on sh.code=sl.code_sh
                                                                          and hc.outtake_date between nvl(sh.start_date,to_date('25.12.2017','dd.mm.yyyy')) and sh.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup2='В ТФОМС принято в счете' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00')) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.schet sh on sh.id=zsl.schet_id
                                                          where zsl.project_id=p.id) )
       when vGroup2='В ТФОМС принято с ВМП' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.vid_hmp||'.'||sl.metod_hmp||' '||m.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.metod_hmp is not null
                                                                left join hospital.hitech_treatment_method m on m.id=sl.metod_hmp and m.hitech_treatment_code=sl.vid_hmp
                                                                          and hc.outtake_date between m.start_date and m.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup2='В ТФОМС принято с медвмешательством' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct trim(nvl(usl.vid_vme,sl.vid_vme)||' '||v.capt) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.usl usl on usl.sl_id=sl.id and usl.is_main=1
                                                                left join (select v001.code, max(v001.caption) capt
                                                                             from registry_oms.v001 v001 group by v001.code
                                                                           ) v on v.code=nvl(usl.vid_vme,sl.vid_vme)
                                                          where zsl.project_id=p.id) )
       when vGroup2='Страховая компания' then (select o.name
                                                 from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                                where cc.id=p.client_certificate_id )
       when vGroup2='Полис' then (select cc.num
                                                from hospital.client_certificate cc
                                               where cc.id=p.client_certificate_id )                                                
       when vGroup2='СМО тюменская' then (select (case when o.okato='71000' then 'Тюменская'
                                                       when o.okato<>'71000' then 'Межтер' else 'СМО без окато' end)
                                            from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                           where cc.id=p.client_certificate_id)                                               
       when vGroup2='КСГ тип' then (select stat.parep.GetCSGType(pcsg.group_id)
                                      from hospital.project_clinic_stat_group pcsg
                                     where pcsg.project_id=p.id)  
       when vGroup2='КСГ' then (select csg.full_code||' '||csg.name
                                  from hospital.project_clinic_stat_group pcsg left join hospital.clinical_statistic_group csg on csg.id=pcsg.group_id
                                 where pcsg.project_id=p.id)
       when vGroup2='Лекарственная схема' then (select sh.code||' '||InitCap(sh.mnn_drugs)
                                                  from hospital.project_clinic_stat_group pcsg left join hospital.register_drug_schema sh on sh.id=pcsg.drug_schema_id
                                                 where pcsg.project_id=p.id)
       when vGroup2='Комбинации препаратов химиолечения' then (select stat.parep.GetCancerListDrugs(cas.id,'ChemoTherapeutic')
                                                              from hospital.cancer_summary cas
                                                             where cas.hospital_card_id=hc.id)
       when vGroup2='Комбинации препаратов гормонотерапии' then (select stat.parep.GetCancerListDrugs(cas.id,'HormoneImmuneTherapeutic')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup2='Комбинации препаратов таргетной терапии' then (select stat.parep.GetCancerListDrugs(cas.id,'Targeted')
                                                                      from hospital.cancer_summary cas
                                                                     where cas.hospital_card_id=hc.id)
       when vGroup2='Комбинации всех препаратов в выписке' then (select stat.parep.GetCancerListDrugs(cas.id,'')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup2='Применённые препараты' then stat.parep.GetDrugs(p.id,'name')
       when vGroup2='Применённые препараты по МНН' then stat.parep.GetDrugs(p.id,'mnn')
       when vGroup2='Применённые препараты по типу' then stat.parep.GetDrugs(p.id,'type')
       when vGroup2='Хирургические операции' then (select listagg(decode(st.id,null,'нет услуги',st.code||' '||substr(st.name,1,100)), ', ') WITHIN GROUP(order by s.start_date, s.id) text
                                                             from hospital.surgery s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and s.execute_state='Done'
                                                           group by s.project_id)
       when vGroup2='Хирургические операции из выписок' then (select listagg(decode(cst.id,null,'нет кода',cst.code||' '||substr(cst.name,1,100)), ', ') WITHIN GROUP(order by csst.start_date, csst.surgery_id, csst.id) text
                                                             from hospital.cancer_summary cas
                                                                  join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                                                                  left join hospital.cancer_surgery_type cst on cst.id=csst.surgery_type_id
                                                            where cas.hospital_card_id=hc.id
                                                           group by csst.cancer_summary_id)
       when vGroup2='Лучевые воздействия из выписок' then (select listagg(ra1.name||' '||crtm1.summary_dose, ', ') WITHIN GROUP(order by ra1.name) text
                                                                   from hospital.cancer_summary cas
                                                                        join hospital.cancer_sum_rad_treat_meth crtm1 on crtm1.cancer_summary_id=cas.id
                                                                        left join hospital.radiation_area ra1 on ra1.id=crtm1.area_id
                                                                  where cas.hospital_card_id=hc.id
                                                                 group by crtm1.cancer_summary_id)
       when vGroup2='Перечень выполненых услуг' then (select listagg(c, ', ') WITHIN GROUP(order by c) text
                                                        from(select distinct st.code c
                                                             from hospital.service s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null) )
       when vGroup2='Наличие хирургических операций' then (case when exists(select 1 from hospital.surgery s
                                                           where s.project_id=p.id and s.execute_state='Done')
                                                           then 'Есть хирургические операции' else 'Нет хирургических операций' end)
       when vGroup2='Наличие хирургических операций в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть хирургические операции в выписке' else 'Нет хирургических операций в выписке' end)
       when vGroup2='Наличие лучевых воздействий в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_rad_treat_meth crtm on crtm.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лучевые воздействия в выписке' else 'Нет лучевых воздействий в выписке' end)
       when vGroup2='Наличие химиотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='ChemoTherapeutic')
                         then 'Есть химиотерапия в выписке' else 'Нет химиотерапии в выписке' end)
       when vGroup2='Наличие гормонотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='HormoneImmuneTherapeutic')
                         then 'Есть гормонотерапии в выписке' else 'Нет гормонотерапии в выписке' end)
       when vGroup2='Наличие таргетной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='Targeted')
                         then 'Есть таргетные терапии в выписке' else 'Нет таргетной терапии в выписке' end)
       when vGroup2='Наличие лекарственной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лекарственные терапии в выписке' else 'Нет лекарственной терапии в выписке' end)
       when vGroup2='Выписан в день недели' then to_char(hc.outtake_date,'D Day')
       when vGroup2='Выписан в календарный год' then to_char(hc.outtake_date,'YYYY')||' год '
       when vGroup2='Выписан в календарный квартал' then to_char(hc.outtake_date,'Q')||' квартал '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup2='Выписан в календарный месяц' then 'Месяц '||trim(to_char(hc.outtake_date,'MM, month'))||' '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup2='Выписан в отчетный год 26-25 число' then to_char(hc.outtake_date+6,'YYYY')||' год '  
       when vGroup2='Выписан в отчетный год 21-20 число' then to_char(hc.outtake_date+11,'YYYY')||' год '  
       when vGroup2='Выписан в отчетный квартал 26-25 число' then to_char(add_months(hc.outtake_date-25,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup2='Выписан в отчетный квартал 21-20 число' then to_char(add_months(hc.outtake_date-20,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup2='Выписан в отчетный месяц 26-25 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-25,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup2='Выписан в отчетный месяц 21-20 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-20,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup2='Наличие в ТФОМС' then (case when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 1 and zsl.project_id=p.id) then 'Принято в ТФОМС'
                                                 when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 0 and zsl.project_id=p.id) then 'Непринято в ТФОМС'
                                                 else 'Неотправлено в ТФОМС' end )

       when vGroup2='Наличие в федрегистре' then (case when stat.parep.FindFederalPatient(cl.sur_name,cl.first_name,cl.patr_name,cl.birthday) is not null
                                                  then 'Присутсвует в федрегистре' else 'Отсутсвует в федрегистре' end )
       when vGroup2='Экспортирован в федрегистр' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_document_operation cdo on cdo.document_id=cas.document_id and cdo.operation='ExportPatientCard'
                           where cas.hospital_card_id=hc.id)
                         then 'Стацкарта экспортирована в федрегистр' else 'Стацкарта не экспортирована в федрегистр' end)                                                    
       when vGroup2='Списано наркотических' then stat.parep.GetDrugsParus(hc.id,'НАРКОТИКИ СИЛЬНОДЕЙСТВУЮЩИЕ')
       when vGroup2='Осложнения анестезии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Anesthesia') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Осложнения постоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Postoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Осложнения интраоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Intraoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Осложнения лучевой терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Radiation') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Осложнения химиотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'ChemoTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Осложнения гормонотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'HormoneImmuneTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Осложнения таргетной терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Targeted') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Осложнения любые в выписке' then (select stat.parep.GetCancerComplic(cas.id) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup2='Врач химиотерапии' then (select stat.parep.GetFIOWorker(cas.chemother_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.chemother_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup2='Врач гормонотерапии' then (select stat.parep.GetFIOWorker(cas.hormone_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.hormone_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup2='Врач таргетной терапии' then (select stat.parep.GetFIOWorker(cas.target_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.target_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup2='Врачи лекарственной терапии' then (select trim(nvl2(cas.chemother_treat_worker_id,'химио '||stat.parep.GetShortFIOWorker(cas.chemother_treat_worker_id),'')
                                                             ||' '||nvl2(cas.hormone_treat_worker_id,'гормоно '||stat.parep.GetShortFIOWorker(cas.hormone_treat_worker_id),'')
                                                             ||' '||nvl2(cas.target_treat_worker_id,'таргет '||stat.parep.GetShortFIOWorker(cas.target_treat_worker_id),'') )
                                                          from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup2='Врач лучевой терапии' then (select stat.parep.GetFIOWorker(cas.rad_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.rad_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)           
       when vGroup2='Койкодней' then (case when stat.parep.GetBedDays(hc.id) between 0 and 1 then '00..01 койкодня'
                                           when stat.parep.GetBedDays(hc.id) between 2 and 3 then '02..03 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 4 and 6 then '04..06 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 7 and 9 then '07..09 койкодней' 
                                           when stat.parep.GetBedDays(hc.id) between 10 and 13 then '10..13 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 14 and 19 then '14..19 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 20 and 29 then '20..29 койкодней'  
                                           when stat.parep.GetBedDays(hc.id) between 30 and 49 then '30..49 койкодней'  
                                      else '50 и более койкодней' end)
  
  else null end) Группа2,
 (case when vGroup3='Пациент' then stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
       when vGroup3='Стацкарта' then hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)
       when vGroup3='Территория проживания' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
       when vGroup3='Регион проживания' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup3='Куст проживания' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup3='Проживает в Тюмени и юге области' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
       when vGroup3='Поликлиника из адреса' then stat.parep.GetCancerPolyclinic(stat.parep.GetCancerPolyclinicID(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup3='Поликлиника из направления' then stat.parep.GetDirectPolyclinic(cl.id,hc.receive_date)
       when vGroup3='Пол' then decode(cl.sex,'Ж','Женщины','М','Мужчины','Неопределен')
       when vGroup3='Возраст' then 'Возраст '||to_char(stat.parep.GetClientAge(cl.id,hc.outtake_date),'00' )
       when vGroup3='Возрастная группа' then (case when stat.parep.GetClientAge(cl.id,hc.outtake_date)<1 then   'Возраст до 1 года'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<3 then   'Возраст от 1 до 3 лет'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<18 then  'Возраст от 3 до 18 лет'
                                                   when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 'Старше трудоспособного возраста'
                                             else 'Возраст трудоспособный' end)
       when vGroup3='Инвалидность' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
       when vGroup3='Этническая группа' then (select eg.name from hospital.ethnic_group eg where eg.id=cl.ethnic_group)
       when vGroup3='Социально-профессиональная группа' then (select sg.name from hospital.social_prof_group sg where sg.id=cl.profession)
       when vGroup3='Гражданство' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
       when vGroup3='Умерший' then decode(p.project_result_type2_id, -34, 'Мертвые', -25, 'Мертвые', 'Живые')
       when vGroup3='Номер госпитализации' then (select 'Госпитализация номер '||to_char(count(hc1.id),'00') from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state not in ('Deleted','Refused') and trunc(hc1.outtake_date)<=dd.dtt)
       when vGroup3='Первая госпитализация' then case when (select count(hc1.id) from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)=1 then 'Первая госпитализация' else 'Повторная госпитализация' end
       when vGroup3='Лечащий врач' then stat.parep.GetFIOWorker(p.worker_id)||' '||stat.parep.GetWorkerSpeciality(p.worker_id)
       when vGroup3='Отделение' then to_char(dep.ordernum,'00')||' '||stat.parep.GetDepname(dep.id)
       when vGroup3='Вид стационара' then dep.dayhospital
       when vGroup3='Обстоятельства выявления в выписке' then (select stat.parep.GetCancerDetectionCircum(cas.detection_circumstances) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Цель госпитализации в выписке' then (select stat.parep.GetCancerHospitalizationGoal(cas.hospitalization_goal) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Результат лечения в выписке' then (select stat.parep.GetCancerTreatmentResult(cas.hosp_treat_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Характер лечения в выписке' then (select stat.parep.GetCancerHospitalizationResult(cas.hospitalization_resid_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Диагноз' then (select substr(mkb.code,1,3)||' '||m.n
                                      from hospital.disease dis
                                           left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                           left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkb.code,1,3)
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup3='Хронический болевой синдром' then (select stat.parep.GetHBS(dis.chronic_pain_syndrome)
                                      from hospital.disease dis
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup3='Клиническая группа' then (select 'Клиническая группа '||cg.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_clinic_group cg on cg.id=od.cancer_clinic_group_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup3='Стадия опухоли' then (select stat.parep.GetCancerStage(od.cancer_stage_value)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup3='Морфологический тип опухоли' then (select t.code||' '||t.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_type t on t.id=od.cancer_type_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup3='TNM' then (select 'T'||od.tnm_t||' N'||od.tnm_n||' M'||od.tnm_m
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup3='Локализации метастазов' then (select stat.parep.GetCancerMetastasisAreas(od.metastasis_areas)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup3='Метод подтверждения' then (select stat.parep.GetCancerConfirmMethods(od.disease_confirm_methods)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup3='Диагноз в выписке' then (select substr(mkbcrd.code,1,3)||' '||m.n
                                                from hospital.cancer_summary cas
                                                     left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                     left join hospital.mkb mkbcrd on mkbcrd.id=crd.mkb_id
                                                     left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkbcrd.code,1,3)
                                               where cas.hospital_card_id=hc.id)
       when vGroup3='Клиническая группа в выписке' then (select 'Клиническая группа в выписке '||cg.name
                                                           from hospital.cancer_summary cas
                                                                left join hospital.cancer_clinic_group cg on cg.id=cas.cancer_clinic_group_id
                                                          where cas.hospital_card_id=hc.id)
       when vGroup3='Стадия опухоли в выписке' then (select stat.parep.GetCancerStage(cas.cancer_stage)
                                                           from hospital.cancer_summary cas
                                                          where cas.hospital_card_id=hc.id)
       when vGroup3='Морфологический тип опухоли в выписке' then (select ct.code||' '||ct.name
                                                                    from hospital.cancer_summary cas
                                                                         left join hospital.cancer_type ct on ct.id=cas.cancer_type_id
                                                                   where cas.hospital_card_id=hc.id)
       when vGroup3='TNM в выписке' then (select 'T'||cas.tnm_t||' N'||cas.tnm_n||' M'||cas.tnm_m
                                            from hospital.cancer_summary cas
                                           where cas.hospital_card_id=hc.id)
       when vGroup3='Локализации метастазов в выписке' then (select stat.parep.GetCancerMetastasisAreas(cas.metastasis_areas)
                                                               from hospital.cancer_summary cas
                                                              where cas.hospital_card_id=hc.id)
       when vGroup3='Метод подтверждения в выписке' then (select stat.parep.GetCancerConfirmMethods(cas.disease_confirm_methods)
                                                            from hospital.cancer_summary cas
                                                           where cas.hospital_card_id=hc.id)
       when vGroup3='Вид диагноза' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                     when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                else 'Неопухолевый диагноз' end
                                           from hospital.disease dis left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                          where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                                and not exists (select 1 from hospital.disease disx where disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)
                                         )
       when vGroup3='Вид диагноза по выписке' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                                when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                           else 'Неопухолевый диагноз' end
                                                      from hospital.cancer_summary cas
                                                           left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                           left join hospital.mkb mkb on mkb.id=crd.mkb_id
                                                     where cas.hospital_card_id=hc.id
                                                    )
       when vGroup3='Лечение' then stat.parep.GetCancerTreatment(hc.id)
       when vGroup3='Вид оплаты' then stat.parep.GetProjectPayType(p.id)
       when vGroup3='В ТФОМС принято СМО тюменской' then (select max(case when substr(zsl.smo,1,2)='72' then 'Да' else 'Нет' end)
                                                         from registry_oms.z_sl zsl
                                                              join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        where zsl.project_id=p.id)
       when vGroup3='В ТФОМС принято СМО' then (select max(zsl.smo||' '||smo.name)
                                                   from registry_oms.z_sl zsl
                                                        join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        left join registry_oms.smo smo on smo.code=zsl.smo
                                                  where zsl.project_id=p.id)
       when vGroup3='В ТФОМС принято с доктором' then (select listagg(s,', ') within group(order by s)
                                                  from (select distinct sl.iddokt||' '||t005.fam||' '||t005.im||' '||t005.ot||' '||sl.prvs||' '||t005.caption as s
                                                          from registry_oms.z_sl zsl
                                                               join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                               left join registry_oms.t005 t005 on t005.iddokt=sl.iddokt and t005.prvs=sl.prvs
                                                         where zsl.project_id=p.id) )
       when vGroup3='В ТФОМС принято с услугой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_usl||' '||t003.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.t003 t003 on t003.code=sl.code_usl and t003.year=to_number(to_char(hc.outtake_date,'yyyy'))
                                                          where zsl.project_id=p.id) )
       when vGroup3='В ТФОМС принято с лекарственной схемой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_sh||' '||sh.mnn_drugs as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.code_sh is not null
                                                                left join hospital.register_drug_schema sh on sh.code=sl.code_sh
                                                                          and hc.outtake_date between nvl(sh.start_date,to_date('25.12.2017','dd.mm.yyyy')) and sh.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup3='В ТФОМС принято в счете' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00')) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.schet sh on sh.id=zsl.schet_id
                                                          where zsl.project_id=p.id) )
       when vGroup3='В ТФОМС принято с ВМП' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.vid_hmp||'.'||sl.metod_hmp||' '||m.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.metod_hmp is not null
                                                                left join hospital.hitech_treatment_method m on m.id=sl.metod_hmp and m.hitech_treatment_code=sl.vid_hmp
                                                                          and hc.outtake_date between m.start_date and m.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup3='В ТФОМС принято с медвмешательством' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct trim(nvl(usl.vid_vme,sl.vid_vme)||' '||v.capt) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.usl usl on usl.sl_id=sl.id and usl.is_main=1
                                                                left join (select v001.code, max(v001.caption) capt
                                                                             from registry_oms.v001 v001 group by v001.code
                                                                           ) v on v.code=nvl(usl.vid_vme,sl.vid_vme)
                                                          where zsl.project_id=p.id) )
       when vGroup3='Страховая компания' then (select o.name
                                                 from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                                where cc.id=p.client_certificate_id )
       when vGroup3='Полис' then (select cc.num
                                                from hospital.client_certificate cc
                                               where cc.id=p.client_certificate_id )                                                
       when vGroup3='СМО тюменская' then (select (case when o.okato='71000' then 'Тюменская'
                                                       when o.okato<>'71000' then 'Межтер' else 'СМО без окато' end)
                                            from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                           where cc.id=p.client_certificate_id)                                               
       when vGroup3='КСГ тип' then (select stat.parep.GetCSGType(pcsg.group_id)
                                      from hospital.project_clinic_stat_group pcsg
                                     where pcsg.project_id=p.id)  
       when vGroup3='КСГ' then (select csg.full_code||' '||csg.name
                                  from hospital.project_clinic_stat_group pcsg left join hospital.clinical_statistic_group csg on csg.id=pcsg.group_id
                                 where pcsg.project_id=p.id)
       when vGroup3='Лекарственная схема' then (select sh.code||' '||InitCap(sh.mnn_drugs)
                                                  from hospital.project_clinic_stat_group pcsg left join hospital.register_drug_schema sh on sh.id=pcsg.drug_schema_id
                                                 where pcsg.project_id=p.id)
       when vGroup3='Комбинации препаратов химиолечения' then (select stat.parep.GetCancerListDrugs(cas.id,'ChemoTherapeutic')
                                                              from hospital.cancer_summary cas
                                                             where cas.hospital_card_id=hc.id)
       when vGroup3='Комбинации препаратов гормонотерапии' then (select stat.parep.GetCancerListDrugs(cas.id,'HormoneImmuneTherapeutic')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup3='Комбинации препаратов таргетной терапии' then (select stat.parep.GetCancerListDrugs(cas.id,'Targeted')
                                                                      from hospital.cancer_summary cas
                                                                     where cas.hospital_card_id=hc.id)
       when vGroup3='Комбинации всех препаратов в выписке' then (select stat.parep.GetCancerListDrugs(cas.id,'')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup3='Применённые препараты' then stat.parep.GetDrugs(p.id,'name')
       when vGroup3='Применённые препараты по МНН' then stat.parep.GetDrugs(p.id,'mnn')
       when vGroup3='Применённые препараты по типу' then stat.parep.GetDrugs(p.id,'type')
       when vGroup3='Хирургические операции' then (select listagg(decode(st.id,null,'нет услуги',st.code||' '||substr(st.name,1,100)), ', ') WITHIN GROUP(order by s.start_date, s.id) text
                                                             from hospital.surgery s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and s.execute_state='Done'
                                                           group by s.project_id)
       when vGroup3='Хирургические операции из выписок' then (select listagg(decode(cst.id,null,'нет кода',cst.code||' '||substr(cst.name,1,100)), ', ') WITHIN GROUP(order by csst.start_date, csst.surgery_id, csst.id) text
                                                             from hospital.cancer_summary cas
                                                                  join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                                                                  left join hospital.cancer_surgery_type cst on cst.id=csst.surgery_type_id
                                                            where cas.hospital_card_id=hc.id
                                                           group by csst.cancer_summary_id)
       when vGroup3='Лучевые воздействия из выписок' then (select listagg(ra1.name||' '||crtm1.summary_dose, ', ') WITHIN GROUP(order by ra1.name) text
                                                                   from hospital.cancer_summary cas
                                                                        join hospital.cancer_sum_rad_treat_meth crtm1 on crtm1.cancer_summary_id=cas.id
                                                                        left join hospital.radiation_area ra1 on ra1.id=crtm1.area_id
                                                                  where cas.hospital_card_id=hc.id
                                                                 group by crtm1.cancer_summary_id)
       when vGroup3='Перечень выполненых услуг' then (select listagg(c, ', ') WITHIN GROUP(order by c) text
                                                        from(select distinct st.code c
                                                             from hospital.service s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null) )
       when vGroup3='Наличие хирургических операций' then (case when exists(select 1 from hospital.surgery s
                                                           where s.project_id=p.id and s.execute_state='Done')
                                                           then 'Есть хирургические операции' else 'Нет хирургических операций' end)
       when vGroup3='Наличие хирургических операций в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть хирургические операции в выписке' else 'Нет хирургических операций в выписке' end)
       when vGroup3='Наличие лучевых воздействий в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_rad_treat_meth crtm on crtm.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лучевые воздействия в выписке' else 'Нет лучевых воздействий в выписке' end)
       when vGroup3='Наличие химиотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='ChemoTherapeutic')
                         then 'Есть химиотерапия в выписке' else 'Нет химиотерапии в выписке' end)
       when vGroup3='Наличие гормонотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='HormoneImmuneTherapeutic')
                         then 'Есть гормонотерапии в выписке' else 'Нет гормонотерапии в выписке' end)
       when vGroup3='Наличие таргетной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='Targeted')
                         then 'Есть таргетные терапии в выписке' else 'Нет таргетной терапии в выписке' end)
       when vGroup3='Наличие лекарственной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лекарственные терапии в выписке' else 'Нет лекарственной терапии в выписке' end)
       when vGroup3='Выписан в день недели' then to_char(hc.outtake_date,'D Day')
       when vGroup3='Выписан в календарный год' then to_char(hc.outtake_date,'YYYY')||' год '
       when vGroup3='Выписан в календарный квартал' then to_char(hc.outtake_date,'Q')||' квартал '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup3='Выписан в календарный месяц' then 'Месяц '||trim(to_char(hc.outtake_date,'MM, month'))||' '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup3='Выписан в отчетный год 26-25 число' then to_char(hc.outtake_date+6,'YYYY')||' год '  
       when vGroup3='Выписан в отчетный год 21-20 число' then to_char(hc.outtake_date+11,'YYYY')||' год '  
       when vGroup3='Выписан в отчетный квартал 26-25 число' then to_char(add_months(hc.outtake_date-25,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup3='Выписан в отчетный квартал 21-20 число' then to_char(add_months(hc.outtake_date-20,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup3='Выписан в отчетный месяц 26-25 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-25,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup3='Выписан в отчетный месяц 21-20 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-20,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup3='Наличие в ТФОМС' then (case when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 1 and zsl.project_id=p.id) then 'Принято в ТФОМС'
                                                 when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 0 and zsl.project_id=p.id) then 'Непринято в ТФОМС'
                                                 else 'Неотправлено в ТФОМС' end )

       when vGroup3='Наличие в федрегистре' then (case when stat.parep.FindFederalPatient(cl.sur_name,cl.first_name,cl.patr_name,cl.birthday) is not null
                                                  then 'Присутсвует в федрегистре' else 'Отсутсвует в федрегистре' end )
       when vGroup3='Экспортирован в федрегистр' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_document_operation cdo on cdo.document_id=cas.document_id and cdo.operation='ExportPatientCard'
                           where cas.hospital_card_id=hc.id)
                         then 'Стацкарта экспортирована в федрегистр' else 'Стацкарта не экспортирована в федрегистр' end)                                                    
       when vGroup3='Списано наркотических' then stat.parep.GetDrugsParus(hc.id,'НАРКОТИКИ СИЛЬНОДЕЙСТВУЮЩИЕ')
       when vGroup3='Осложнения анестезии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Anesthesia') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Осложнения постоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Postoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Осложнения интраоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Intraoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Осложнения лучевой терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Radiation') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Осложнения химиотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'ChemoTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Осложнения гормонотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'HormoneImmuneTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Осложнения таргетной терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Targeted') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Осложнения любые в выписке' then (select stat.parep.GetCancerComplic(cas.id) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup3='Врач химиотерапии' then (select stat.parep.GetFIOWorker(cas.chemother_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.chemother_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup3='Врач гормонотерапии' then (select stat.parep.GetFIOWorker(cas.hormone_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.hormone_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup3='Врач таргетной терапии' then (select stat.parep.GetFIOWorker(cas.target_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.target_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup3='Врачи лекарственной терапии' then (select trim(nvl2(cas.chemother_treat_worker_id,'химио '||stat.parep.GetShortFIOWorker(cas.chemother_treat_worker_id),'')
                                                             ||' '||nvl2(cas.hormone_treat_worker_id,'гормоно '||stat.parep.GetShortFIOWorker(cas.hormone_treat_worker_id),'')
                                                             ||' '||nvl2(cas.target_treat_worker_id,'таргет '||stat.parep.GetShortFIOWorker(cas.target_treat_worker_id),'') )
                                                          from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup3='Врач лучевой терапии' then (select stat.parep.GetFIOWorker(cas.rad_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.rad_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)           
       when vGroup3='Койкодней' then (case when stat.parep.GetBedDays(hc.id) between 0 and 1 then '00..01 койкодня'
                                           when stat.parep.GetBedDays(hc.id) between 2 and 3 then '02..03 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 4 and 6 then '04..06 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 7 and 9 then '07..09 койкодней' 
                                           when stat.parep.GetBedDays(hc.id) between 10 and 13 then '10..13 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 14 and 19 then '14..19 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 20 and 29 then '20..29 койкодней'  
                                           when stat.parep.GetBedDays(hc.id) between 30 and 49 then '30..49 койкодней'  
                                      else '50 и более койкодней' end)
  
  else null end) Группа3,
 (case when vGroup4='Пациент' then stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
       when vGroup4='Стацкарта' then hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)
       when vGroup4='Территория проживания' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
       when vGroup4='Регион проживания' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup4='Куст проживания' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup4='Проживает в Тюмени и юге области' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
       when vGroup4='Поликлиника из адреса' then stat.parep.GetCancerPolyclinic(stat.parep.GetCancerPolyclinicID(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup4='Поликлиника из направления' then stat.parep.GetDirectPolyclinic(cl.id,hc.receive_date)
       when vGroup4='Пол' then decode(cl.sex,'Ж','Женщины','М','Мужчины','Неопределен')
       when vGroup4='Возраст' then 'Возраст '||to_char(stat.parep.GetClientAge(cl.id,hc.outtake_date),'00' )
       when vGroup4='Возрастная группа' then (case when stat.parep.GetClientAge(cl.id,hc.outtake_date)<1 then   'Возраст до 1 года'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<3 then   'Возраст от 1 до 3 лет'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<18 then  'Возраст от 3 до 18 лет'
                                                   when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 'Старше трудоспособного возраста'
                                             else 'Возраст трудоспособный' end)
       when vGroup4='Инвалидность' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
       when vGroup4='Этническая группа' then (select eg.name from hospital.ethnic_group eg where eg.id=cl.ethnic_group)
       when vGroup4='Социально-профессиональная группа' then (select sg.name from hospital.social_prof_group sg where sg.id=cl.profession)
       when vGroup4='Гражданство' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
       when vGroup4='Умерший' then decode(p.project_result_type2_id, -34, 'Мертвые', -25, 'Мертвые', 'Живые')
       when vGroup4='Номер госпитализации' then (select 'Госпитализация номер '||to_char(count(hc1.id),'00') from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)
       when vGroup4='Первая госпитализация' then case when (select count(hc1.id) from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)=1 then 'Первая госпитализация' else 'Повторная госпитализация' end
       when vGroup4='Лечащий врач' then stat.parep.GetFIOWorker(p.worker_id)||' '||stat.parep.GetWorkerSpeciality(p.worker_id)
       when vGroup4='Отделение' then to_char(dep.ordernum,'00')||' '||stat.parep.GetDepname(dep.id)
       when vGroup4='Вид стационара' then dep.dayhospital
       when vGroup4='Обстоятельства выявления в выписке' then (select stat.parep.GetCancerDetectionCircum(cas.detection_circumstances) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Цель госпитализации в выписке' then (select stat.parep.GetCancerHospitalizationGoal(cas.hospitalization_goal) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Результат лечения в выписке' then (select stat.parep.GetCancerTreatmentResult(cas.hosp_treat_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Характер лечения в выписке' then (select stat.parep.GetCancerHospitalizationResult(cas.hospitalization_resid_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Диагноз' then (select substr(mkb.code,1,3)||' '||m.n
                                      from hospital.disease dis
                                           left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                           left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkb.code,1,3)
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup4='Хронический болевой синдром' then (select stat.parep.GetHBS(dis.chronic_pain_syndrome)
                                      from hospital.disease dis
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup4='Клиническая группа' then (select 'Клиническая группа '||cg.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_clinic_group cg on cg.id=od.cancer_clinic_group_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup4='Стадия опухоли' then (select stat.parep.GetCancerStage(od.cancer_stage_value)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup4='Морфологический тип опухоли' then (select t.code||' '||t.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_type t on t.id=od.cancer_type_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup4='TNM' then (select 'T'||od.tnm_t||' N'||od.tnm_n||' M'||od.tnm_m
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup4='Локализации метастазов' then (select stat.parep.GetCancerMetastasisAreas(od.metastasis_areas)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup4='Метод подтверждения' then (select stat.parep.GetCancerConfirmMethods(od.disease_confirm_methods)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup4='Диагноз в выписке' then (select substr(mkbcrd.code,1,3)||' '||m.n
                                                from hospital.cancer_summary cas
                                                     left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                     left join hospital.mkb mkbcrd on mkbcrd.id=crd.mkb_id
                                                     left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkbcrd.code,1,3)
                                               where cas.hospital_card_id=hc.id)
       when vGroup4='Клиническая группа в выписке' then (select 'Клиническая группа в выписке '||cg.name
                                                           from hospital.cancer_summary cas
                                                                left join hospital.cancer_clinic_group cg on cg.id=cas.cancer_clinic_group_id
                                                          where cas.hospital_card_id=hc.id)
       when vGroup4='Стадия опухоли в выписке' then (select stat.parep.GetCancerStage(cas.cancer_stage)
                                                           from hospital.cancer_summary cas
                                                          where cas.hospital_card_id=hc.id)
       when vGroup4='Морфологический тип опухоли в выписке' then (select ct.code||' '||ct.name
                                                                    from hospital.cancer_summary cas
                                                                         left join hospital.cancer_type ct on ct.id=cas.cancer_type_id
                                                                   where cas.hospital_card_id=hc.id)
       when vGroup4='TNM в выписке' then (select 'T'||cas.tnm_t||' N'||cas.tnm_n||' M'||cas.tnm_m
                                            from hospital.cancer_summary cas
                                           where cas.hospital_card_id=hc.id)
       when vGroup4='Локализации метастазов в выписке' then (select stat.parep.GetCancerMetastasisAreas(cas.metastasis_areas)
                                                               from hospital.cancer_summary cas
                                                              where cas.hospital_card_id=hc.id)
       when vGroup4='Метод подтверждения в выписке' then (select stat.parep.GetCancerConfirmMethods(cas.disease_confirm_methods)
                                                            from hospital.cancer_summary cas
                                                           where cas.hospital_card_id=hc.id)
       when vGroup4='Вид диагноза' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                     when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                else 'Неопухолевый диагноз' end
                                           from hospital.disease dis left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                          where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                                and not exists (select 1 from hospital.disease disx where disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)
                                         )
       when vGroup4='Вид диагноза по выписке' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                                when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                           else 'Неопухолевый диагноз' end
                                                      from hospital.cancer_summary cas
                                                           left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                           left join hospital.mkb mkb on mkb.id=crd.mkb_id
                                                     where cas.hospital_card_id=hc.id
                                                    )
       when vGroup4='Лечение' then stat.parep.GetCancerTreatment(hc.id)
       when vGroup4='Вид оплаты' then stat.parep.GetProjectPayType(p.id)
       when vGroup4='В ТФОМС принято СМО тюменской' then (select max(case when substr(zsl.smo,1,2)='72' then 'Да' else 'Нет' end)
                                                         from registry_oms.z_sl zsl
                                                              join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        where zsl.project_id=p.id)
       when vGroup4='В ТФОМС принято СМО' then (select max(zsl.smo||' '||smo.name)
                                                   from registry_oms.z_sl zsl
                                                        join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        left join registry_oms.smo smo on smo.code=zsl.smo
                                                  where zsl.project_id=p.id)
       when vGroup4='В ТФОМС принято с доктором' then (select listagg(s,', ') within group(order by s)
                                                  from (select distinct sl.iddokt||' '||t005.fam||' '||t005.im||' '||t005.ot||' '||sl.prvs||' '||t005.caption as s
                                                          from registry_oms.z_sl zsl
                                                               join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                               left join registry_oms.t005 t005 on t005.iddokt=sl.iddokt and t005.prvs=sl.prvs
                                                         where zsl.project_id=p.id) )
       when vGroup4='В ТФОМС принято с услугой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_usl||' '||t003.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.t003 t003 on t003.code=sl.code_usl and t003.year=to_number(to_char(hc.outtake_date,'yyyy'))
                                                          where zsl.project_id=p.id) )
       when vGroup4='В ТФОМС принято с лекарственной схемой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_sh||' '||sh.mnn_drugs as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.code_sh is not null
                                                                left join hospital.register_drug_schema sh on sh.code=sl.code_sh
                                                                          and hc.outtake_date between nvl(sh.start_date,to_date('25.12.2017','dd.mm.yyyy')) and sh.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup4='В ТФОМС принято в счете' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00')) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.schet sh on sh.id=zsl.schet_id
                                                          where zsl.project_id=p.id) )
       when vGroup4='В ТФОМС принято с ВМП' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.vid_hmp||'.'||sl.metod_hmp||' '||m.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.metod_hmp is not null
                                                                left join hospital.hitech_treatment_method m on m.id=sl.metod_hmp and m.hitech_treatment_code=sl.vid_hmp
                                                                          and hc.outtake_date between m.start_date and m.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup4='В ТФОМС принято с медвмешательством' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct trim(nvl(usl.vid_vme,sl.vid_vme)||' '||v.capt) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.usl usl on usl.sl_id=sl.id and usl.is_main=1
                                                                left join (select v001.code, max(v001.caption) capt
                                                                             from registry_oms.v001 v001 group by v001.code
                                                                           ) v on v.code=nvl(usl.vid_vme,sl.vid_vme)
                                                          where zsl.project_id=p.id) )
       when vGroup4='Страховая компания' then (select o.name
                                                 from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                                where cc.id=p.client_certificate_id )
       when vGroup4='Полис' then (select cc.num
                                                from hospital.client_certificate cc
                                               where cc.id=p.client_certificate_id )                                                
       when vGroup4='СМО тюменская' then (select (case when o.okato='71000' then 'Тюменская'
                                                       when o.okato<>'71000' then 'Межтер' else 'СМО без окато' end)
                                            from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                           where cc.id=p.client_certificate_id)                                               
       when vGroup4='КСГ тип' then (select stat.parep.GetCSGType(pcsg.group_id)
                                      from hospital.project_clinic_stat_group pcsg
                                     where pcsg.project_id=p.id)  
       when vGroup4='КСГ' then (select csg.full_code||' '||csg.name
                                  from hospital.project_clinic_stat_group pcsg left join hospital.clinical_statistic_group csg on csg.id=pcsg.group_id
                                 where pcsg.project_id=p.id)
       when vGroup4='Лекарственная схема' then (select sh.code||' '||InitCap(sh.mnn_drugs)
                                                  from hospital.project_clinic_stat_group pcsg left join hospital.register_drug_schema sh on sh.id=pcsg.drug_schema_id
                                                 where pcsg.project_id=p.id)
       when vGroup4='Комбинации препаратов химиолечения' then (select stat.parep.GetCancerListDrugs(cas.id,'ChemoTherapeutic')
                                                              from hospital.cancer_summary cas
                                                             where cas.hospital_card_id=hc.id)
       when vGroup4='Комбинации препаратов гормонотерапии' then (select stat.parep.GetCancerListDrugs(cas.id,'HormoneImmuneTherapeutic')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup4='Комбинации препаратов таргетной терапии' then (select stat.parep.GetCancerListDrugs(cas.id,'Targeted')
                                                                      from hospital.cancer_summary cas
                                                                     where cas.hospital_card_id=hc.id)
       when vGroup4='Комбинации всех препаратов в выписке' then (select stat.parep.GetCancerListDrugs(cas.id,'')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup4='Применённые препараты' then stat.parep.GetDrugs(p.id,'name')
       when vGroup4='Применённые препараты по МНН' then stat.parep.GetDrugs(p.id,'mnn')
       when vGroup4='Применённые препараты по типу' then stat.parep.GetDrugs(p.id,'type')
       when vGroup4='Хирургические операции' then (select listagg(decode(st.id,null,'нет услуги',st.code||' '||substr(st.name,1,100)), ', ') WITHIN GROUP(order by s.start_date, s.id) text
                                                             from hospital.surgery s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and s.execute_state='Done'
                                                           group by s.project_id)
       when vGroup4='Хирургические операции из выписок' then (select listagg(decode(cst.id,null,'нет кода',cst.code||' '||substr(cst.name,1,100)), ', ') WITHIN GROUP(order by csst.start_date, csst.surgery_id, csst.id) text
                                                             from hospital.cancer_summary cas
                                                                  join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                                                                  left join hospital.cancer_surgery_type cst on cst.id=csst.surgery_type_id
                                                            where cas.hospital_card_id=hc.id
                                                           group by csst.cancer_summary_id)
       when vGroup4='Лучевые воздействия из выписок' then (select listagg(ra1.name||' '||crtm1.summary_dose, ', ') WITHIN GROUP(order by ra1.name) text
                                                                   from hospital.cancer_summary cas
                                                                        join hospital.cancer_sum_rad_treat_meth crtm1 on crtm1.cancer_summary_id=cas.id
                                                                        left join hospital.radiation_area ra1 on ra1.id=crtm1.area_id
                                                                  where cas.hospital_card_id=hc.id
                                                                 group by crtm1.cancer_summary_id)
       when vGroup4='Перечень выполненых услуг' then (select listagg(c, ', ') WITHIN GROUP(order by c) text
                                                        from(select distinct st.code c
                                                             from hospital.service s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null) )
       when vGroup4='Наличие хирургических операций' then (case when exists(select 1 from hospital.surgery s
                                                           where s.project_id=p.id and s.execute_state='Done')
                                                           then 'Есть хирургические операции' else 'Нет хирургических операций' end)
       when vGroup4='Наличие хирургических операций в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть хирургические операции в выписке' else 'Нет хирургических операций в выписке' end)
       when vGroup4='Наличие лучевых воздействий в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_rad_treat_meth crtm on crtm.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лучевые воздействия в выписке' else 'Нет лучевых воздействий в выписке' end)
       when vGroup4='Наличие химиотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='ChemoTherapeutic')
                         then 'Есть химиотерапия в выписке' else 'Нет химиотерапии в выписке' end)
       when vGroup4='Наличие гормонотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='HormoneImmuneTherapeutic')
                         then 'Есть гормонотерапии в выписке' else 'Нет гормонотерапии в выписке' end)
       when vGroup4='Наличие таргетной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='Targeted')
                         then 'Есть таргетные терапии в выписке' else 'Нет таргетной терапии в выписке' end)
       when vGroup4='Наличие лекарственной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лекарственные терапии в выписке' else 'Нет лекарственной терапии в выписке' end)
       when vGroup4='Выписан в день недели' then to_char(hc.outtake_date,'D Day')
       when vGroup4='Выписан в календарный год' then to_char(hc.outtake_date,'YYYY')||' год '
       when vGroup4='Выписан в календарный квартал' then to_char(hc.outtake_date,'Q')||' квартал '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup4='Выписан в календарный месяц' then 'Месяц '||trim(to_char(hc.outtake_date,'MM, month'))||' '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup4='Выписан в отчетный год 26-25 число' then to_char(hc.outtake_date+6,'YYYY')||' год '  
       when vGroup4='Выписан в отчетный год 21-20 число' then to_char(hc.outtake_date+11,'YYYY')||' год '  
       when vGroup4='Выписан в отчетный квартал 26-25 число' then to_char(add_months(hc.outtake_date-25,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup4='Выписан в отчетный квартал 21-20 число' then to_char(add_months(hc.outtake_date-20,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup4='Выписан в отчетный месяц 26-25 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-25,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup4='Выписан в отчетный месяц 21-20 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-20,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup4='Наличие в ТФОМС' then (case when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 1 and zsl.project_id=p.id) then 'Принято в ТФОМС'
                                                 when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 0 and zsl.project_id=p.id) then 'Непринято в ТФОМС'
                                                 else 'Неотправлено в ТФОМС' end )
       when vGroup4='Наличие в федрегистре' then (case when stat.parep.FindFederalPatient(cl.sur_name,cl.first_name,cl.patr_name,cl.birthday) is not null
                                                  then 'Присутсвует в федрегистре' else 'Отсутсвует в федрегистре' end )
       when vGroup4='Экспортирован в федрегистр' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_document_operation cdo on cdo.document_id=cas.document_id and cdo.operation='ExportPatientCard'
                           where cas.hospital_card_id=hc.id)
                         then 'Стацкарта экспортирована в федрегистр' else 'Стацкарта не экспортирована в федрегистр' end)                                                    
       when vGroup4='Списано наркотических' then stat.parep.GetDrugsParus(hc.id,'НАРКОТИКИ СИЛЬНОДЕЙСТВУЮЩИЕ')
       when vGroup4='Осложнения анестезии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Anesthesia') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Осложнения постоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Postoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Осложнения интраоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Intraoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Осложнения лучевой терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Radiation') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Осложнения химиотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'ChemoTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Осложнения гормонотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'HormoneImmuneTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Осложнения таргетной терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Targeted') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Осложнения любые в выписке' then (select stat.parep.GetCancerComplic(cas.id) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup4='Врач химиотерапии' then (select stat.parep.GetFIOWorker(cas.chemother_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.chemother_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup4='Врач гормонотерапии' then (select stat.parep.GetFIOWorker(cas.hormone_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.hormone_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup4='Врач таргетной терапии' then (select stat.parep.GetFIOWorker(cas.target_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.target_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup4='Врачи лекарственной терапии' then (select trim(nvl2(cas.chemother_treat_worker_id,'химио '||stat.parep.GetShortFIOWorker(cas.chemother_treat_worker_id),'')
                                                             ||' '||nvl2(cas.hormone_treat_worker_id,'гормоно '||stat.parep.GetShortFIOWorker(cas.hormone_treat_worker_id),'')
                                                             ||' '||nvl2(cas.target_treat_worker_id,'таргет '||stat.parep.GetShortFIOWorker(cas.target_treat_worker_id),'') )
                                                          from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup4='Врач лучевой терапии' then (select stat.parep.GetFIOWorker(cas.rad_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.rad_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)           
       when vGroup4='Койкодней' then (case when stat.parep.GetBedDays(hc.id) between 0 and 1 then '00..01 койкодня'
                                           when stat.parep.GetBedDays(hc.id) between 2 and 3 then '02..03 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 4 and 6 then '04..06 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 7 and 9 then '07..09 койкодней' 
                                           when stat.parep.GetBedDays(hc.id) between 10 and 13 then '10..13 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 14 and 19 then '14..19 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 20 and 29 then '20..29 койкодней'  
                                           when stat.parep.GetBedDays(hc.id) between 30 and 49 then '30..49 койкодней'  
                                      else '50 и более койкодней' end)
  
  else null end) Группа4,
 (case when vGroup5='Пациент' then stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
       when vGroup5='Стацкарта' then hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)
       when vGroup5='Территория проживания' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
       when vGroup5='Регион проживания' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup5='Куст проживания' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup5='Проживает в Тюмени и юге области' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
       when vGroup5='Поликлиника из адреса' then stat.parep.GetCancerPolyclinic(stat.parep.GetCancerPolyclinicID(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup5='Поликлиника из направления' then stat.parep.GetDirectPolyclinic(cl.id,hc.receive_date)
       when vGroup5='Пол' then decode(cl.sex,'Ж','Женщины','М','Мужчины','Неопределен')
       when vGroup5='Возраст' then 'Возраст '||to_char(stat.parep.GetClientAge(cl.id,hc.outtake_date),'00' )
       when vGroup5='Возрастная группа' then (case when stat.parep.GetClientAge(cl.id,hc.outtake_date)<1 then   'Возраст до 1 года'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<3 then   'Возраст от 1 до 3 лет'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<18 then  'Возраст от 3 до 18 лет'
                                                   when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 'Старше трудоспособного возраста'
                                             else 'Возраст трудоспособный' end)
       when vGroup5='Инвалидность' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
       when vGroup5='Этническая группа' then (select eg.name from hospital.ethnic_group eg where eg.id=cl.ethnic_group)
       when vGroup5='Социально-профессиональная группа' then (select sg.name from hospital.social_prof_group sg where sg.id=cl.profession)
       when vGroup5='Гражданство' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
       when vGroup5='Умерший' then decode(p.project_result_type2_id, -34, 'Мертвые', -25, 'Мертвые', 'Живые')
       when vGroup5='Номер госпитализации' then (select 'Госпитализация номер '||to_char(count(hc1.id),'00') from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state  not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)
       when vGroup5='Первая госпитализация' then case when (select count(hc1.id) from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)=1 then 'Первая госпитализация' else 'Повторная госпитализация' end
       when vGroup5='Лечащий врач' then stat.parep.GetFIOWorker(p.worker_id)||' '||stat.parep.GetWorkerSpeciality(p.worker_id)
       when vGroup5='Отделение' then to_char(dep.ordernum,'00')||' '||stat.parep.GetDepname(dep.id)
       when vGroup5='Вид стационара' then dep.dayhospital
       when vGroup5='Обстоятельства выявления в выписке' then (select stat.parep.GetCancerDetectionCircum(cas.detection_circumstances) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Цель госпитализации в выписке' then (select stat.parep.GetCancerHospitalizationGoal(cas.hospitalization_goal) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Результат лечения в выписке' then (select stat.parep.GetCancerTreatmentResult(cas.hosp_treat_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Характер лечения в выписке' then (select stat.parep.GetCancerHospitalizationResult(cas.hospitalization_resid_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Диагноз' then (select substr(mkb.code,1,3)||' '||m.n
                                      from hospital.disease dis
                                           left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                           left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkb.code,1,3)
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup5='Хронический болевой синдром' then (select stat.parep.GetHBS(dis.chronic_pain_syndrome)
                                      from hospital.disease dis
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup5='Клиническая группа' then (select 'Клиническая группа '||cg.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_clinic_group cg on cg.id=od.cancer_clinic_group_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup5='Стадия опухоли' then (select stat.parep.GetCancerStage(od.cancer_stage_value)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup5='Морфологический тип опухоли' then (select t.code||' '||t.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_type t on t.id=od.cancer_type_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup5='TNM' then (select 'T'||od.tnm_t||' N'||od.tnm_n||' M'||od.tnm_m
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup5='Локализации метастазов' then (select stat.parep.GetCancerMetastasisAreas(od.metastasis_areas)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup5='Метод подтверждения' then (select stat.parep.GetCancerConfirmMethods(od.disease_confirm_methods)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup5='Диагноз в выписке' then (select substr(mkbcrd.code,1,3)||' '||m.n
                                                from hospital.cancer_summary cas
                                                     left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                     left join hospital.mkb mkbcrd on mkbcrd.id=crd.mkb_id
                                                     left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkbcrd.code,1,3)
                                               where cas.hospital_card_id=hc.id)
       when vGroup5='Клиническая группа в выписке' then (select 'Клиническая группа в выписке '||cg.name
                                                           from hospital.cancer_summary cas
                                                                left join hospital.cancer_clinic_group cg on cg.id=cas.cancer_clinic_group_id
                                                          where cas.hospital_card_id=hc.id)
       when vGroup5='Стадия опухоли в выписке' then (select stat.parep.GetCancerStage(cas.cancer_stage)
                                                           from hospital.cancer_summary cas
                                                          where cas.hospital_card_id=hc.id)
       when vGroup5='Морфологический тип опухоли в выписке' then (select ct.code||' '||ct.name
                                                                    from hospital.cancer_summary cas
                                                                         left join hospital.cancer_type ct on ct.id=cas.cancer_type_id
                                                                   where cas.hospital_card_id=hc.id)
       when vGroup5='TNM в выписке' then (select 'T'||cas.tnm_t||' N'||cas.tnm_n||' M'||cas.tnm_m
                                            from hospital.cancer_summary cas
                                           where cas.hospital_card_id=hc.id)
       when vGroup5='Локализации метастазов в выписке' then (select stat.parep.GetCancerMetastasisAreas(cas.metastasis_areas)
                                                               from hospital.cancer_summary cas
                                                              where cas.hospital_card_id=hc.id)
       when vGroup5='Метод подтверждения в выписке' then (select stat.parep.GetCancerConfirmMethods(cas.disease_confirm_methods)
                                                            from hospital.cancer_summary cas
                                                           where cas.hospital_card_id=hc.id)
       when vGroup5='Вид диагноза' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                     when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                else 'Неопухолевый диагноз' end
                                           from hospital.disease dis left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                          where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                                and not exists (select 1 from hospital.disease disx where disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)
                                         )
       when vGroup5='Вид диагноза по выписке' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                                when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                           else 'Неопухолевый диагноз' end
                                                      from hospital.cancer_summary cas
                                                           left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                           left join hospital.mkb mkb on mkb.id=crd.mkb_id
                                                     where cas.hospital_card_id=hc.id
                                                    )
       when vGroup5='Лечение' then stat.parep.GetCancerTreatment(hc.id)
       when vGroup5='Вид оплаты' then stat.parep.GetProjectPayType(p.id)
       when vGroup5='В ТФОМС принято СМО тюменской' then (select max(case when substr(zsl.smo,1,2)='72' then 'Да' else 'Нет' end)
                                                         from registry_oms.z_sl zsl
                                                              join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        where zsl.project_id=p.id)
       when vGroup5='В ТФОМС принято СМО' then (select max(zsl.smo||' '||smo.name)
                                                   from registry_oms.z_sl zsl
                                                        join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        left join registry_oms.smo smo on smo.code=zsl.smo
                                                  where zsl.project_id=p.id)
       when vGroup5='В ТФОМС принято с доктором' then (select listagg(s,', ') within group(order by s)
                                                  from (select distinct sl.iddokt||' '||t005.fam||' '||t005.im||' '||t005.ot||' '||sl.prvs||' '||t005.caption as s
                                                          from registry_oms.z_sl zsl
                                                               join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                               left join registry_oms.t005 t005 on t005.iddokt=sl.iddokt and t005.prvs=sl.prvs
                                                         where zsl.project_id=p.id) )
       when vGroup5='В ТФОМС принято с услугой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_usl||' '||t003.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.t003 t003 on t003.code=sl.code_usl and t003.year=to_number(to_char(hc.outtake_date,'yyyy'))
                                                          where zsl.project_id=p.id) )
       when vGroup5='В ТФОМС принято с лекарственной схемой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_sh||' '||sh.mnn_drugs as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.code_sh is not null
                                                                left join hospital.register_drug_schema sh on sh.code=sl.code_sh
                                                                          and hc.outtake_date between nvl(sh.start_date,to_date('25.12.2017','dd.mm.yyyy')) and sh.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup5='В ТФОМС принято в счете' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00')) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.schet sh on sh.id=zsl.schet_id
                                                          where zsl.project_id=p.id) )
       when vGroup5='В ТФОМС принято с ВМП' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.vid_hmp||'.'||sl.metod_hmp||' '||m.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.metod_hmp is not null
                                                                left join hospital.hitech_treatment_method m on m.id=sl.metod_hmp and m.hitech_treatment_code=sl.vid_hmp
                                                                          and hc.outtake_date between m.start_date and m.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup5='В ТФОМС принято с медвмешательством' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct trim(nvl(usl.vid_vme,sl.vid_vme)||' '||v.capt) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.usl usl on usl.sl_id=sl.id and usl.is_main=1
                                                                left join (select v001.code, max(v001.caption) capt
                                                                             from registry_oms.v001 v001 group by v001.code
                                                                           ) v on v.code=nvl(usl.vid_vme,sl.vid_vme)
                                                          where zsl.project_id=p.id) )
       when vGroup5='Страховая компания' then (select o.name
                                                 from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                                where cc.id=p.client_certificate_id )
       when vGroup5='Полис' then (select cc.num
                                                from hospital.client_certificate cc
                                               where cc.id=p.client_certificate_id )                                                
       when vGroup5='СМО тюменская' then (select (case when o.okato='71000' then 'Тюменская'
                                                       when o.okato<>'71000' then 'Межтер' else 'СМО без окато' end)
                                            from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                           where cc.id=p.client_certificate_id)                                               
       when vGroup5='КСГ тип' then (select stat.parep.GetCSGType(pcsg.group_id)
                                      from hospital.project_clinic_stat_group pcsg
                                     where pcsg.project_id=p.id)  
       when vGroup5='КСГ' then (select csg.full_code||' '||csg.name
                                  from hospital.project_clinic_stat_group pcsg left join hospital.clinical_statistic_group csg on csg.id=pcsg.group_id
                                 where pcsg.project_id=p.id)
       when vGroup5='Лекарственная схема' then (select sh.code||' '||InitCap(sh.mnn_drugs)
                                                  from hospital.project_clinic_stat_group pcsg left join hospital.register_drug_schema sh on sh.id=pcsg.drug_schema_id
                                                 where pcsg.project_id=p.id)
       when vGroup5='Комбинации препаратов химиолечения' then (select stat.parep.GetCancerListDrugs(cas.id,'ChemoTherapeutic')
                                                              from hospital.cancer_summary cas
                                                             where cas.hospital_card_id=hc.id)
       when vGroup5='Комбинации препаратов гормонотерапии' then (select stat.parep.GetCancerListDrugs(cas.id,'HormoneImmuneTherapeutic')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup5='Комбинации препаратов таргетной терапии' then (select stat.parep.GetCancerListDrugs(cas.id,'Targeted')
                                                                      from hospital.cancer_summary cas
                                                                     where cas.hospital_card_id=hc.id)
       when vGroup5='Комбинации всех препаратов в выписке' then (select stat.parep.GetCancerListDrugs(cas.id,'')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup5='Применённые препараты' then stat.parep.GetDrugs(p.id,'name')
       when vGroup5='Применённые препараты по МНН' then stat.parep.GetDrugs(p.id,'mnn')
       when vGroup5='Применённые препараты по типу' then stat.parep.GetDrugs(p.id,'type')
       when vGroup5='Хирургические операции' then (select listagg(decode(st.id,null,'нет услуги',st.code||' '||substr(st.name,1,100)), ', ') WITHIN GROUP(order by s.start_date, s.id) text
                                                             from hospital.surgery s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and s.execute_state='Done'
                                                           group by s.project_id)
       when vGroup5='Хирургические операции из выписок' then (select listagg(decode(cst.id,null,'нет кода',cst.code||' '||substr(cst.name,1,100)), ', ') WITHIN GROUP(order by csst.start_date, csst.surgery_id, csst.id) text
                                                             from hospital.cancer_summary cas
                                                                  join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                                                                  left join hospital.cancer_surgery_type cst on cst.id=csst.surgery_type_id
                                                            where cas.hospital_card_id=hc.id
                                                           group by csst.cancer_summary_id)
       when vGroup5='Лучевые воздействия из выписок' then (select listagg(ra1.name||' '||crtm1.summary_dose, ', ') WITHIN GROUP(order by ra1.name) text
                                                                   from hospital.cancer_summary cas
                                                                        join hospital.cancer_sum_rad_treat_meth crtm1 on crtm1.cancer_summary_id=cas.id
                                                                        left join hospital.radiation_area ra1 on ra1.id=crtm1.area_id
                                                                  where cas.hospital_card_id=hc.id
                                                                 group by crtm1.cancer_summary_id)
       when vGroup5='Перечень выполненых услуг' then (select listagg(c, ', ') WITHIN GROUP(order by c) text
                                                        from(select distinct st.code c
                                                             from hospital.service s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null) )
       when vGroup5='Наличие хирургических операций' then (case when exists(select 1 from hospital.surgery s
                                                           where s.project_id=p.id and s.execute_state='Done')
                                                           then 'Есть хирургические операции' else 'Нет хирургических операций' end)
       when vGroup5='Наличие хирургических операций в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть хирургические операции в выписке' else 'Нет хирургических операций в выписке' end)
       when vGroup5='Наличие лучевых воздействий в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_rad_treat_meth crtm on crtm.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лучевые воздействия в выписке' else 'Нет лучевых воздействий в выписке' end)
       when vGroup5='Наличие химиотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='ChemoTherapeutic')
                         then 'Есть химиотерапия в выписке' else 'Нет химиотерапии в выписке' end)
       when vGroup5='Наличие гормонотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='HormoneImmuneTherapeutic')
                         then 'Есть гормонотерапии в выписке' else 'Нет гормонотерапии в выписке' end)
       when vGroup5='Наличие таргетной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='Targeted')
                         then 'Есть таргетные терапии в выписке' else 'Нет таргетной терапии в выписке' end)
       when vGroup5='Наличие лекарственной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лекарственные терапии в выписке' else 'Нет лекарственной терапии в выписке' end)
       when vGroup5='Выписан в день недели' then to_char(hc.outtake_date,'D Day')
       when vGroup5='Выписан в календарный год' then to_char(hc.outtake_date,'YYYY')||' год '
       when vGroup5='Выписан в календарный квартал' then to_char(hc.outtake_date,'Q')||' квартал '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup5='Выписан в календарный месяц' then 'Месяц '||trim(to_char(hc.outtake_date,'MM, month'))||' '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup5='Выписан в отчетный год 26-25 число' then to_char(hc.outtake_date+6,'YYYY')||' год '  
       when vGroup5='Выписан в отчетный год 21-20 число' then to_char(hc.outtake_date+11,'YYYY')||' год '  
       when vGroup5='Выписан в отчетный квартал 26-25 число' then to_char(add_months(hc.outtake_date-25,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup5='Выписан в отчетный квартал 21-20 число' then to_char(add_months(hc.outtake_date-20,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup5='Выписан в отчетный месяц 26-25 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-25,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup5='Выписан в отчетный месяц 21-20 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-20,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup5='Наличие в ТФОМС' then (case when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 1 and zsl.project_id=p.id) then 'Принято в ТФОМС'
                                                 when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 0 and zsl.project_id=p.id) then 'Непринято в ТФОМС'
                                                 else 'Неотправлено в ТФОМС' end )
       when vGroup5='Наличие в федрегистре' then (case when stat.parep.FindFederalPatient(cl.sur_name,cl.first_name,cl.patr_name,cl.birthday) is not null
                                                  then 'Присутсвует в федрегистре' else 'Отсутсвует в федрегистре' end )
       when vGroup5='Экспортирован в федрегистр' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_document_operation cdo on cdo.document_id=cas.document_id and cdo.operation='ExportPatientCard'
                           where cas.hospital_card_id=hc.id)
                         then 'Стацкарта экспортирована в федрегистр' else 'Стацкарта не экспортирована в федрегистр' end)                                                    
       when vGroup5='Списано наркотических' then stat.parep.GetDrugsParus(hc.id,'НАРКОТИКИ СИЛЬНОДЕЙСТВУЮЩИЕ')
       when vGroup5='Осложнения анестезии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Anesthesia') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Осложнения постоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Postoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Осложнения интраоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Intraoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Осложнения лучевой терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Radiation') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Осложнения химиотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'ChemoTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Осложнения гормонотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'HormoneImmuneTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Осложнения таргетной терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Targeted') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Осложнения любые в выписке' then (select stat.parep.GetCancerComplic(cas.id) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup5='Врач химиотерапии' then (select stat.parep.GetFIOWorker(cas.chemother_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.chemother_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup5='Врач гормонотерапии' then (select stat.parep.GetFIOWorker(cas.hormone_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.hormone_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup5='Врач таргетной терапии' then (select stat.parep.GetFIOWorker(cas.target_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.target_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup5='Врачи лекарственной терапии' then (select trim(nvl2(cas.chemother_treat_worker_id,'химио '||stat.parep.GetShortFIOWorker(cas.chemother_treat_worker_id),'')
                                                             ||' '||nvl2(cas.hormone_treat_worker_id,'гормоно '||stat.parep.GetShortFIOWorker(cas.hormone_treat_worker_id),'')
                                                             ||' '||nvl2(cas.target_treat_worker_id,'таргет '||stat.parep.GetShortFIOWorker(cas.target_treat_worker_id),'') )
                                                          from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup5='Врач лучевой терапии' then (select stat.parep.GetFIOWorker(cas.rad_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.rad_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)           
       when vGroup5='Койкодней' then (case when stat.parep.GetBedDays(hc.id) between 0 and 1 then '00..01 койкодня'
                                           when stat.parep.GetBedDays(hc.id) between 2 and 3 then '02..03 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 4 and 6 then '04..06 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 7 and 9 then '07..09 койкодней' 
                                           when stat.parep.GetBedDays(hc.id) between 10 and 13 then '10..13 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 14 and 19 then '14..19 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 20 and 29 then '20..29 койкодней'  
                                           when stat.parep.GetBedDays(hc.id) between 30 and 49 then '30..49 койкодней'  
                                      else '50 и более койкодней' end)
  
  else null end) Группа5,
 (case when vGroup6='Пациент' then stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
       when vGroup6='Стацкарта' then hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)
       when vGroup6='Территория проживания' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
       when vGroup6='Регион проживания' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup6='Куст проживания' then ltrim(stat.parep.GetTerritoryBush(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup6='Проживает в Тюмени и юге области' then case when ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id))) in ('Тюмень','Юг Тюменской области') then 'Да' else 'Нет' end
       when vGroup6='Поликлиника из адреса' then stat.parep.GetCancerPolyclinic(stat.parep.GetCancerPolyclinicID(stat.parep.GetClientLiveAddress(cl.id)))
       when vGroup6='Поликлиника из направления' then stat.parep.GetDirectPolyclinic(cl.id,hc.receive_date)
       when vGroup6='Пол' then decode(cl.sex,'Ж','Женщины','М','Мужчины','Неопределен')
       when vGroup6='Возраст' then 'Возраст '||to_char(stat.parep.GetClientAge(cl.id,hc.outtake_date),'00' )
       when vGroup6='Возрастная группа' then (case when stat.parep.GetClientAge(cl.id,hc.outtake_date)<1 then   'Возраст до 1 года'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<3 then   'Возраст от 1 до 3 лет'
                                                   when stat.parep.GetClientAge(cl.id,hc.outtake_date)<18 then  'Возраст от 3 до 18 лет'
                                                   when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 'Старше трудоспособного возраста'
                                             else 'Возраст трудоспособный' end)
       when vGroup6='Инвалидность' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)
       when vGroup6='Этническая группа' then (select eg.name from hospital.ethnic_group eg where eg.id=cl.ethnic_group)
       when vGroup6='Социально-профессиональная группа' then (select sg.name from hospital.social_prof_group sg where sg.id=cl.profession)
       when vGroup6='Гражданство' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
       when vGroup6='Умерший' then decode(p.project_result_type2_id, -34, 'Мертвые', -25, 'Мертвые', 'Живые')
       when vGroup6='Номер госпитализации' then (select 'Госпитализация номер '||to_char(count(hc1.id),'00') from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state  not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)
       when vGroup6='Первая госпитализация' then case when (select count(hc1.id) from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)=1 then 'Первая госпитализация' else 'Повторная госпитализация' end
       when vGroup6='Лечащий врач' then stat.parep.GetFIOWorker(p.worker_id)||' '||stat.parep.GetWorkerSpeciality(p.worker_id)
       when vGroup6='Отделение' then to_char(dep.ordernum,'00')||' '||stat.parep.GetDepname(dep.id)
       when vGroup6='Вид стационара' then dep.dayhospital
       when vGroup6='Обстоятельства выявления в выписке' then (select stat.parep.GetCancerDetectionCircum(cas.detection_circumstances) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Цель госпитализации в выписке' then (select stat.parep.GetCancerHospitalizationGoal(cas.hospitalization_goal) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Результат лечения в выписке' then (select stat.parep.GetCancerTreatmentResult(cas.hosp_treat_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Характер лечения в выписке' then (select stat.parep.GetCancerHospitalizationResult(cas.hospitalization_resid_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Диагноз' then (select substr(mkb.code,1,3)||' '||m.n
                                      from hospital.disease dis
                                           left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                           left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkb.code,1,3)
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup6='Хронический болевой синдром' then (select stat.parep.GetHBS(dis.chronic_pain_syndrome)
                                      from hospital.disease dis
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup6='Клиническая группа' then (select 'Клиническая группа '||cg.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_clinic_group cg on cg.id=od.cancer_clinic_group_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup6='Стадия опухоли' then (select stat.parep.GetCancerStage(od.cancer_stage_value)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup6='Морфологический тип опухоли' then (select t.code||' '||t.name
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                           left join hospital.cancer_type t on t.id=od.cancer_type_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup6='TNM' then (select 'T'||od.tnm_t||' N'||od.tnm_n||' M'||od.tnm_m
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup6='Локализации метастазов' then (select stat.parep.GetCancerMetastasisAreas(od.metastasis_areas)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup6='Метод подтверждения' then (select stat.parep.GetCancerConfirmMethods(od.disease_confirm_methods)
                                      from hospital.disease dis
                                           left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                     where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                           and not exists (select 1 from hospital.disease disx where
                                                           disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
       when vGroup6='Диагноз в выписке' then (select substr(mkbcrd.code,1,3)||' '||m.n
                                                from hospital.cancer_summary cas
                                                     left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                     left join hospital.mkb mkbcrd on mkbcrd.id=crd.mkb_id
                                                     left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkbcrd.code,1,3)
                                               where cas.hospital_card_id=hc.id)
       when vGroup6='Клиническая группа в выписке' then (select 'Клиническая группа в выписке '||cg.name
                                                           from hospital.cancer_summary cas
                                                                left join hospital.cancer_clinic_group cg on cg.id=cas.cancer_clinic_group_id
                                                          where cas.hospital_card_id=hc.id)
       when vGroup6='Стадия опухоли в выписке' then (select stat.parep.GetCancerStage(cas.cancer_stage)
                                                           from hospital.cancer_summary cas
                                                          where cas.hospital_card_id=hc.id)
       when vGroup6='Морфологический тип опухоли в выписке' then (select ct.code||' '||ct.name
                                                                    from hospital.cancer_summary cas
                                                                         left join hospital.cancer_type ct on ct.id=cas.cancer_type_id
                                                                   where cas.hospital_card_id=hc.id)
       when vGroup6='TNM в выписке' then (select 'T'||cas.tnm_t||' N'||cas.tnm_n||' M'||cas.tnm_m
                                            from hospital.cancer_summary cas
                                           where cas.hospital_card_id=hc.id)
       when vGroup6='Локализации метастазов в выписке' then (select stat.parep.GetCancerMetastasisAreas(cas.metastasis_areas)
                                                               from hospital.cancer_summary cas
                                                              where cas.hospital_card_id=hc.id)
       when vGroup6='Метод подтверждения в выписке' then (select stat.parep.GetCancerConfirmMethods(cas.disease_confirm_methods)
                                                            from hospital.cancer_summary cas
                                                           where cas.hospital_card_id=hc.id)
       when vGroup6='Вид диагноза' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                     when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                else 'Неопухолевый диагноз' end
                                           from hospital.disease dis left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                          where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)
                                                and not exists (select 1 from hospital.disease disx where disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)
                                         )
       when vGroup6='Вид диагноза по выписке' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                                when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                           else 'Неопухолевый диагноз' end
                                                      from hospital.cancer_summary cas
                                                           left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                           left join hospital.mkb mkb on mkb.id=crd.mkb_id
                                                     where cas.hospital_card_id=hc.id
                                                    )
       when vGroup6='Лечение' then stat.parep.GetCancerTreatment(hc.id)
       when vGroup6='Вид оплаты' then stat.parep.GetProjectPayType(p.id)
       when vGroup6='В ТФОМС принято СМО тюменской' then (select max(case when substr(zsl.smo,1,2)='72' then 'Да' else 'Нет' end)
                                                         from registry_oms.z_sl zsl
                                                              join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        where zsl.project_id=p.id)
       when vGroup6='В ТФОМС принято СМО' then (select max(zsl.smo||' '||smo.name)
                                                   from registry_oms.z_sl zsl
                                                        join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                        left join registry_oms.smo smo on smo.code=zsl.smo
                                                  where zsl.project_id=p.id)
       when vGroup6='В ТФОМС принято с доктором' then (select listagg(s,', ') within group(order by s)
                                                  from (select distinct sl.iddokt||' '||t005.fam||' '||t005.im||' '||t005.ot||' '||sl.prvs||' '||t005.caption as s
                                                          from registry_oms.z_sl zsl
                                                               join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                               left join registry_oms.t005 t005 on t005.iddokt=sl.iddokt and t005.prvs=sl.prvs
                                                         where zsl.project_id=p.id) )
       when vGroup6='В ТФОМС принято с услугой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_usl||' '||t003.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.t003 t003 on t003.code=sl.code_usl and t003.year=to_number(to_char(hc.outtake_date,'yyyy'))
                                                          where zsl.project_id=p.id) )
       when vGroup6='В ТФОМС принято с лекарственной схемой' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.code_sh||' '||sh.mnn_drugs as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.code_sh is not null
                                                                left join hospital.register_drug_schema sh on sh.code=sl.code_sh
                                                                          and hc.outtake_date between nvl(sh.start_date,to_date('25.12.2017','dd.mm.yyyy')) and sh.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup6='В ТФОМС принято в счете' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct 'Счет '||sh.nschet||' тип '||sh.type||' от '||to_char(sh.dschet,'dd.mm.yyyy')||' на сумму '||trim(to_char(sh.summav,'999999999990D00')) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.schet sh on sh.id=zsl.schet_id
                                                          where zsl.project_id=p.id) )
       when vGroup6='В ТФОМС принято с ВМП' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct sl.vid_hmp||'.'||sl.metod_hmp||' '||m.name as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1 and sl.metod_hmp is not null
                                                                left join hospital.hitech_treatment_method m on m.id=sl.metod_hmp and m.hitech_treatment_code=sl.vid_hmp
                                                                          and hc.outtake_date between m.start_date and m.end_date
                                                          where zsl.project_id=p.id) )
       when vGroup6='В ТФОМС принято с медвмешательством' then (select listagg(s,', ') within group(order by s)
                                                   from (select distinct trim(nvl(usl.vid_vme,sl.vid_vme)||' '||v.capt) as s
                                                           from registry_oms.z_sl zsl
                                                                join registry_oms.sl sl on sl.z_sl_id=zsl.id and sl.accepted_tfoms=1
                                                                left join registry_oms.usl usl on usl.sl_id=sl.id and usl.is_main=1
                                                                left join (select v001.code, max(v001.caption) capt
                                                                             from registry_oms.v001 v001 group by v001.code
                                                                           ) v on v.code=nvl(usl.vid_vme,sl.vid_vme)
                                                          where zsl.project_id=p.id) )
       when vGroup6='Страховая компания' then (select o.name
                                                 from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                                where cc.id=p.client_certificate_id )
       when vGroup6='Полис' then (select trim(cc.ser||' ')||cc.num
                                                from hospital.client_certificate cc
                                               where cc.id=p.client_certificate_id )                                                
       when vGroup6='СМО тюменская' then (select (case when o.okato='71000' then 'Тюменская'
                                                       when o.okato<>'71000' then 'Межтер' else 'СМО без окато' end)
                                            from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                           where cc.id=p.client_certificate_id)                                               
       when vGroup6='КСГ тип' then (select stat.parep.GetCSGType(pcsg.group_id)
                                      from hospital.project_clinic_stat_group pcsg
                                     where pcsg.project_id=p.id)  
       when vGroup6='КСГ' then (select csg.full_code||' '||csg.name
                                  from hospital.project_clinic_stat_group pcsg left join hospital.clinical_statistic_group csg on csg.id=pcsg.group_id
                                 where pcsg.project_id=p.id)
       when vGroup6='Лекарственная схема' then (select sh.code||' '||InitCap(sh.mnn_drugs)
                                                  from hospital.project_clinic_stat_group pcsg left join hospital.register_drug_schema sh on sh.id=pcsg.drug_schema_id
                                                 where pcsg.project_id=p.id)
       when vGroup6='Комбинации препаратов химиолечения' then (select stat.parep.GetCancerListDrugs(cas.id,'ChemoTherapeutic')
                                                                 from hospital.cancer_summary cas
                                                                where cas.hospital_card_id=hc.id)
       when vGroup6='Комбинации препаратов гормонотерапии' then (select stat.parep.GetCancerListDrugs(cas.id,'HormoneImmuneTherapeutic')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup6='Комбинации препаратов таргетной терапии' then (select stat.parep.GetCancerListDrugs(cas.id,'Targeted')
                                                                      from hospital.cancer_summary cas
                                                                     where cas.hospital_card_id=hc.id)
       when vGroup6='Комбинации всех препаратов в выписке' then (select stat.parep.GetCancerListDrugs(cas.id,'')
                                                                   from hospital.cancer_summary cas
                                                                  where cas.hospital_card_id=hc.id)
       when vGroup6='Применённые препараты' then stat.parep.GetDrugs(p.id,'name')
       when vGroup6='Применённые препараты по МНН' then stat.parep.GetDrugs(p.id,'mnn')
       when vGroup6='Применённые препараты по типу' then stat.parep.GetDrugs(p.id,'type')
       when vGroup6='Хирургические операции' then (select listagg(decode(st.id,null,'нет услуги',st.code||' '||substr(st.name,1,100)), ', ') WITHIN GROUP(order by s.start_date, s.id) text
                                                             from hospital.surgery s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and s.execute_state='Done'
                                                           group by s.project_id)
       when vGroup6='Хирургические операции из выписок' then (select listagg(decode(cst.id,null,'нет кода',cst.code||' '||substr(cst.name,1,100)), ', ') WITHIN GROUP(order by csst.start_date, csst.surgery_id, csst.id) text
                                                             from hospital.cancer_summary cas
                                                                  join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                                                                  left join hospital.cancer_surgery_type cst on cst.id=csst.surgery_type_id
                                                            where cas.hospital_card_id=hc.id
                                                           group by csst.cancer_summary_id)
       when vGroup6='Лучевые воздействия из выписок' then (select listagg(ra1.name||' '||crtm1.summary_dose, ', ') WITHIN GROUP(order by ra1.name) text
                                                                   from hospital.cancer_summary cas
                                                                        join hospital.cancer_sum_rad_treat_meth crtm1 on crtm1.cancer_summary_id=cas.id
                                                                        left join hospital.radiation_area ra1 on ra1.id=crtm1.area_id
                                                                  where cas.hospital_card_id=hc.id
                                                                 group by crtm1.cancer_summary_id)
       when vGroup6='Перечень выполненых услуг' then (select listagg(c, ', ') WITHIN GROUP(order by c) text
                                                        from(select distinct st.code c
                                                             from hospital.service s
                                                                  left join hospital.service_type st on st.id=s.service_type_id
                                                            where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null) )
       when vGroup6='Наличие хирургических операций' then (case when exists(select 1 from hospital.surgery s
                                                           where s.project_id=p.id and s.execute_state='Done')
                                                           then 'Есть хирургические операции' else 'Нет хирургических операций' end)
       when vGroup6='Наличие хирургических операций в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть хирургические операции в выписке' else 'Нет хирургических операций в выписке' end)
       when vGroup6='Наличие лучевых воздействий в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_rad_treat_meth crtm on crtm.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лучевые воздействия в выписке' else 'Нет лучевых воздействий в выписке' end)
       when vGroup6='Наличие химиотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='ChemoTherapeutic')
                         then 'Есть химиотерапия в выписке' else 'Нет химиотерапии в выписке' end)
       when vGroup6='Наличие гормонотерапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='HormoneImmuneTherapeutic')
                         then 'Есть гормонотерапии в выписке' else 'Нет гормонотерапии в выписке' end)
       when vGroup6='Наличие таргетной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id and csdt.drug_treatment_type='Targeted')
                         then 'Есть таргетные терапии в выписке' else 'Нет таргетной терапии в выписке' end)
       when vGroup6='Наличие лекарственной терапии в выписке' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_sum_drug_treat csdt on csdt.cancer_summary_id=cas.id
                           where cas.hospital_card_id=hc.id)
                         then 'Есть лекарственные терапии в выписке' else 'Нет лекарственной терапии в выписке' end)
       when vGroup6='Выписан в день недели' then to_char(hc.outtake_date,'D Day')
       when vGroup6='Выписан в календарный год' then to_char(hc.outtake_date,'YYYY')||' год '
       when vGroup6='Выписан в календарный квартал' then to_char(hc.outtake_date,'Q')||' квартал '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup6='Выписан в календарный месяц' then 'Месяц '||trim(to_char(hc.outtake_date,'MM, month'))||' '||to_char(hc.outtake_date,'YYYY')||' года'
       when vGroup6='Выписан в отчетный год 26-25 число' then to_char(hc.outtake_date+6,'YYYY')||' год '  
       when vGroup6='Выписан в отчетный год 21-20 число' then to_char(hc.outtake_date+11,'YYYY')||' год '  
       when vGroup6='Выписан в отчетный квартал 26-25 число' then to_char(add_months(hc.outtake_date-25,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup6='Выписан в отчетный квартал 21-20 число' then to_char(add_months(hc.outtake_date-20,1),'Q')||' квартал '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup6='Выписан в отчетный месяц 26-25 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-25,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-25,1),'YYYY')||' года'
       when vGroup6='Выписан в отчетный месяц 21-20 число' then 'Месяц '||trim(to_char(add_months(hc.outtake_date-20,1),'MM, month'))||' '||to_char(add_months(hc.outtake_date-20,1),'YYYY')||' года'
       when vGroup6='Наличие в ТФОМС' then (case when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 1 and zsl.project_id=p.id) then 'Принято в ТФОМС'
                                                 when exists (select 1 from registry_oms.z_sl zsl join registry_oms.sl sl on zsl.id = sl.z_sl_id
                                                               where sl.accepted_tfoms = 0 and zsl.project_id=p.id) then 'Непринято в ТФОМС'
                                                 else 'Неотправлено в ТФОМС' end )
       when vGroup6='Наличие в федрегистре' then (case when stat.parep.FindFederalPatient(cl.sur_name,cl.first_name,cl.patr_name,cl.birthday) is not null
                                                  then 'Присутсвует в федрегистре' else 'Отсутсвует в федрегистре' end )
       when vGroup6='Экспортирован в федрегистр' then (case when exists(
                           select 1 from hospital.cancer_summary cas join hospital.cancer_document_operation cdo on cdo.document_id=cas.document_id and cdo.operation='ExportPatientCard'
                           where cas.hospital_card_id=hc.id)
                         then 'Стацкарта экспортирована в федрегистр' else 'Стацкарта не экспортирована в федрегистр' end)
       when vGroup6='Списано наркотических' then stat.parep.GetDrugsParus(hc.id,'НАРКОТИКИ СИЛЬНОДЕЙСТВУЮЩИЕ')
       when vGroup6='Осложнения анестезии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Anesthesia') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Осложнения постоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Postoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Осложнения интраоперационные в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Intraoperative') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Осложнения лучевой терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Radiation') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Осложнения химиотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'ChemoTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Осложнения гормонотерапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'HormoneImmuneTherapeutic') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Осложнения таргетной терапии в выписке' then (select stat.parep.GetCancerComplic(cas.id,'Targeted') from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Осложнения любые в выписке' then (select stat.parep.GetCancerComplic(cas.id) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
       when vGroup6='Врач химиотерапии' then (select stat.parep.GetFIOWorker(cas.chemother_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.chemother_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup6='Врач гормонотерапии' then (select stat.parep.GetFIOWorker(cas.hormone_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.hormone_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup6='Врач таргетной терапии' then (select stat.parep.GetFIOWorker(cas.target_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.target_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup6='Врачи лекарственной терапии' then (select trim(nvl2(cas.chemother_treat_worker_id,'химио '||stat.parep.GetShortFIOWorker(cas.chemother_treat_worker_id),'')
                                                             ||' '||nvl2(cas.hormone_treat_worker_id,'гормоно '||stat.parep.GetShortFIOWorker(cas.hormone_treat_worker_id),'')
                                                             ||' '||nvl2(cas.target_treat_worker_id,'таргет '||stat.parep.GetShortFIOWorker(cas.target_treat_worker_id),'') )
                                                          from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)  
       when vGroup6='Врач лучевой терапии' then (select stat.parep.GetFIOWorker(cas.rad_treat_worker_id)||' '||stat.parep.GetDepname(stat.parep.GetWorkerDepID(cas.rad_treat_worker_id)) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)           
       when vGroup6='Койкодней' then (case when stat.parep.GetBedDays(hc.id) between 0 and 1 then '00..01 койкодня'
                                           when stat.parep.GetBedDays(hc.id) between 2 and 3 then '02..03 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 4 and 6 then '04..06 койкодня' 
                                           when stat.parep.GetBedDays(hc.id) between 7 and 9 then '07..09 койкодней' 
                                           when stat.parep.GetBedDays(hc.id) between 10 and 13 then '10..13 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 14 and 19 then '14..19 койкодней'
                                           when stat.parep.GetBedDays(hc.id) between 20 and 29 then '20..29 койкодней'  
                                           when stat.parep.GetBedDays(hc.id) between 30 and 49 then '30..49 койкодней'  
                                      else '50 и более койкодней' end)
  else null end) Группа6,
 x.hospital_card_id,
 p.client_id,
 stat.parep.GetBedDays(hc.id) kdays
from
 dd,dep,table(stat.parep.GetListBedDischargedPeriod(dd.dtf,dd.dtt,dep.id)) x, hospital.hospital_card hc, hospital.project p, hospital.client cl
where
 hc.id=x.hospital_card_id and p.id=hc.project_id and cl.id=p.client_id
)
where
 fn1 = case when regexp_like(Группа1||' ',fl1,'i') then 0 else 1 end and
 fn2 = case when regexp_like(Группа2||' ',fl2,'i') then 0 else 1 end and
 fn3 = case when regexp_like(Группа3||' ',fl3,'i') then 0 else 1 end and
 fn4 = case when regexp_like(Группа4||' ',fl4,'i') then 0 else 1 end and
 fn5 = case when regexp_like(Группа5||' ',fl5,'i') then 0 else 1 end and
 fn6 = case when regexp_like(Группа6||' ',fl6,'i') then 0 else 1 end
group by
 chPct,Группа1,Группа2,Группа3,Группа4,Группа5,Группа6
order by
 Группа1,Группа2,Группа3,Группа4,Группа5,Группа6
