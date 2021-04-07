--хирургические операции
--информация по наличию хирургических операций у выписанных пациентов
--для сверок и т.д.
--19 06 2018
--20 06 2018
--08 08 2018 протасов, баг исправлен - если бригада ни фед ни в эмк не указано - теряется
--09 08 2018 протасов, баг исправлен, 3 операции из ЭМК не в статусе Done попадали
--05 09 2018 диагноз
--07 09 2018 врач
--06 05 2019 отдельно врач в хирбригаде выписки и эмк, нов ДС
--15 05 2018 признак умерший
--19 11 2019 getlistdep, множественность осложнений
--09 12 2019 фильтр по осложнениям
--10 12 2019 вид оплаты
--13 12 2019 кдней до после, фильтр отделению выписки

--15 01 2020 фильтр по диагнозу заключительному
--15 01 2020 фильтр регулярками
--31 01 2020 фильтр по отделению хирурга выписки БЗН, первого, колво совпадет с отчетом деятельность хирургов

/*
with dd as (select :DTF dtf , :DTT dtt, :DS ds,
                   upper(:VDEAD) VDEAD, upper(:VNULL) VNULL, upper(:SURGERYF) SURGERYF, upper(:SURGERY) SURGERY, upper(:WORKER) WORKER, upper(:DEPWORKER) DEPWORKER,
                   upper(:WORKERС) WORKERС, upper(:CLIENT) CLIENT, upper(:COMPL) COMPL, upper(:DEPN) DEPN, upper(:DIAG) DIAG  from dual)
*/
/*
with dd as (select to_date('26.12.2018','dd.mm.yyyy') dtf , to_date('25.12.2019','dd.mm.yyyy') dtt, 0 ds,
                   0 VDEAD, 'N' VNULL, '*' SURGERYF, 'A16.18.025|A16.18.027|A16.16.052' SURGERY, '*' WORKER,
                   '*' WORKERС, '*' CLIENT, '*' COMPL, '*' DEPN, 'C16|C18|C19|C20' DIAG   from dual)
*/
with dd as (select to_date('26.12.2018','dd.mm.yyyy') dtf , to_date('25.12.2019','dd.mm.yyyy') dtt, 0 ds,
                   0 VDEAD, 'Y' VNULL, '*' SURGERYF, '*' SURGERY, '*' WORKER, 'Хирургическое' DEPWORKER,
                   '*' WORKERС, '*' CLIENT, '*' COMPL, '*' DEPN, '*' DIAG   from dual)


select
 dd.dtf С,
 dd.dtt По,
 hc.id ИД_стацкарты,
 hc.num Стацкарта,
 stat.parep.GetProjectMKBCode(1, p.id) Диагноз,
 stat.parep.GetShortFIOWorker(p.worker_id) Врач,
 stat.parep.GetFIOClient(cl.id) Пациент,
 stat.parep.GetBirthDayClient(cl.id) Дата_рождения,
 decode(p.project_result_type2_id, -34, 1, -25, 1, 0) Мертв,
 trunc(hc.receive_date) Поступил,
 trunc(hc.outtake_date) Выписан,
 dout.id ИД_отделения,
 stat.parep.GetDepname(dout.id) Отделение,
 stat.parep.GetProjectPayType(p.id) Вид_оплаты,

 csst.id ИД_операции_фед,
 (case when csst.id = (LAG(csst.id,1) over (order by csst.id,s.id)) then 'Да' else 'Нет' end)  Дубль_фед,
 csst.surgery_id ИД_операции_ссылка,
 csst.start_date Начало_фед,
 cst.code Код_операции_фед,
 cst.name Операция_фед,
 stat.parep.GetShortCancerSurgeryCommand(csst.id) Бригада_фед,
 surcop.cnt Постосложнений,
 surcop.names Код_постосложнения,
 surcoi.cnt Интраосложнений,
 surcoi.names Код_интраосложнения,
 s.id ИД_операции,
 (case when s.id = (LAG(s.id,1) over (order by s.id,csst.id)) then 'Да' else 'Нет' end)  Дубль,
 s.start_date Начало,
 s.end_date Конец,
 round((s.end_date-s.start_date)*24,2) Часов,
 st.code Код_эмк,
 st.code2 Код_операции,
 st.name Операция,
 stat.parep.GetShortSurgeryCommand(s.id) Бригада,
 (case when hc.id <> nvl((LAG(hc.id,1) over (order by hc.id,s.id)),s.id) then 'Да' else 'Нет' end) Первая
-- (case when hc.id <> (LEAD(hc.id,1) over (order by hc.id,csst.id)) then trunc(s.start_date)-trunc(hc.receive_date) end) Койкодней_до,
-- (case when hc.id <> (LEAD(hc.id,1) over (order by hc.id,csst.id)) then trunc(hc.outtake_date)-trunc(s.end_date) end) Койкодней_после
 ,trunc(s.start_date)-trunc(hc.receive_date) Койкодней_до
 ,trunc(hc.outtake_date)-trunc(s.end_date)  Койкодней_после


from
 dd,hospital.hospital_card hc
 join hospital.project p on p.id=hc.project_id
 join hospital.client cl on cl.id=p.client_id
 left join hospital.cancer_summary cas on cas.hospital_card_id=hc.id
 left join hospital.cancer_register_document crd on crd.id=cas.document_id

 --отделение выписывающее из стацкарты
 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id, hcmr.execute_worker_id
            from hospital.hospital_card_movement hcmr
            where hcmr.state='Discharged'  --получаем дату последнего нахождения в момент выписки hc
                  and not exists( select 1 from hospital.hospital_card_movement hcmx
                                  where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='Discharged' and hcmx.id>hcmr.id )
           ) hcmout on hcmout.hospital_card_id=hc.id
 left join hospital.department dout on dout.id=hcmout.department_id

--хирургическое лечение
 left join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id = cas.id   --операции из канцервыписки
 left join hospital.surgery s on (s.id=csst.surgery_id and s.execute_state='Done') --операция из стацкарты связанная с операцией в выписке, выполненные
                                 or (s.project_id=p.id and s.execute_state='Done' and s.id not in (select nvl(x.surgery_id,0) from hospital.cancer_sum_surgery_treat x where x.cancer_summary_id=cas.id ))

 left join hospital.cancer_surgery_type cst on cst.id=csst.surgery_type_id --название операции федеральное
 left join hospital.service_type st on st.id=s.service_type_id   --название операции в стацкарте
--осложнения
 left join (select csc.cancer_summary_surgery_id, count(sc.id) cnt, listagg(sc.code, ' ') WITHIN GROUP(order by sc.code) names
              from hospital.cancer_sum_surgery_compl csc
                   join hospital.surgery_complication sc on sc.id=csc.complication_id
             where csc.type='Postoperative'
             group by csc.cancer_summary_surgery_id) surcop on surcop.cancer_summary_surgery_id=csst.id
 left join (select csc.cancer_summary_surgery_id, count(sc.id) cnt, listagg(sc.code, ' ') WITHIN GROUP(order by sc.code) names
              from hospital.cancer_sum_surgery_compl csc
                   join hospital.surgery_complication sc on sc.id=csc.complication_id
             where csc.type='Intraoperative'
             group by csc.cancer_summary_surgery_id) surcoi on surcoi.cancer_summary_surgery_id=csst.id


where
--по дате выписки в стацкарте
 trunc(hc.outtake_date) between dtf and dtt
--только нормальные выписывающие отделения
 and dout.id in (select id from table(stat.parep.getlistdep(ds)))

--только с операциями список стац случаев
 and (s.id is not null or csst.id is not null)

--если хотим только операции из стацкарты
-- and s.id is not null

--если хотим только операции фед
-- and csst.id is not null

--только с операциями связанные между выпиской и стацкартой
-- and (s.id is not null and csst.id is not null)

-- and s.id=21649  --тест
-- and hc.id in (61012,61520,60602)  --дубли возникают
and (VDEAD=0 or p.project_result_type2_id in (-34,-25) )

and (
(
 VNULL='N'
 and regexp_like(cst.code||' '||cst.name,SURGERYF,'i')
 and regexp_like(st.code||' '||st.code2||' '||st.name,SURGERY,'i')
 and regexp_like(stat.parep.GetShortSurgeryCommand(s.id)||' ',WORKER,'i')
 and regexp_like(stat.parep.GetShortCancerSurgeryCommand(csst.id)||' ',WORKERС,'i')
 and regexp_like(stat.parep.GetFIOClient(cl.id),CLIENT,'i')
 and regexp_like(surcop.names||' ',COMPL,'i')
 and regexp_like(dout.name,DEPN,'i')
 and regexp_like(stat.parep.GetProjectMKBCode(1, p.id)||' ',DIAG,'i')
    
 and (DEPWORKER='*' or exists( select 1 from hospital.cancer_sum_surgery_worker ssw 
                                where ssw.cancer_summary_surgery_id=csst.id and ssw.role_id in (1)
                                      and not exists (select 1 from hospital.cancer_sum_surgery_worker sswx   --для хирургов считаем только одного, первого в порядке ssw.id
                                                       where sswx.cancer_summary_surgery_id=ssw.cancer_summary_surgery_id and sswx.role_id=1 and sswx.id<ssw.id)
                                      and regexp_like(stat.parep.GetDepname(stat.parep.GetWorkerDepID(ssw.worker_id))||' ',DEPWORKER,'i') ) )
)
or
(
 VNULL='Y'
 and (cst.id is null)
)
)

order by
 stat.parep.GetDepOrder(ИД_отделения), Выписан, Пациент, ИД_операции, ИД_операции_фед


