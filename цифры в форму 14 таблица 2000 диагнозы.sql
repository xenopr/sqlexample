--для проверки форма14
--протасов
--15062018
--28 06 2018
--02 07 2018

--31 07 2018 в 12с теперь не работает заглядывать в di

--09 01 2019 
--09 01 2019 коррекция - каждый нетрудоспособный минус 1 койкодень
--10 01 2019

--17 01 2019 коррекция - подделка, убрать диагнозы J
--18 01 2019 еще подделка цифр согласно указанию Пиняковой подтвержденным Гайсиным Т.А. - из строк 15.0, 12.0,5.0 по нетрудоспособным уменьшить койкодни
--09 12 2019 к 2019 году 

--17 01 2019 коррекции, согласовано с Гайсин
--28 12 2020 за 2020
--11 01 2021 IsPensioner
--14 01 2021 I11


--with dd as (select :DTF dtf, :DTT dtt, :COR cor from dual),       --период
with dd as (select to_date('26.12.2019','dd.mm.yyyy') dtf, to_date('25.12.2020','dd.mm.yyyy') dtt, 1 cor  from dual),       --период
     dep as (select id from table(stat.parep.GetListDep(0)))  --круглосуточные стационары

select
 lpad('                        ',length(stat.parep.GetFormGroupOrder(gr.fgroupcode)),' ')||ltrim(gr.fgroup) Группа_имя,
 gr.fgroupcode Группа,
 stat.parep.GetFormGroupMKBs(gr.fgroupcode)  Диагнозы,

--в том же порядке в эксель
 sum(x.ВозрастомОт18) ВозрастомОт18, --4
 null к5,  --5
 null к6,  --6
 sum(x.ВозрастомОт18_койкодней) ВозрастомОт18_койкодней,  --7
 sum(x.ВозрастомОт18_умерло) ВозрастомОт18_умерло,  --8
 null к9, --9  пат вскрытий
 null к10,  --10  расхождений диагнозов
 null к11,  --11  судебных вскрытий
 null к12,  --12  расхождений
 sum(x.Нетрудоспособные) Нетрудоспособные,  --13
 null к14,  --14 
 null к15,  --15 
 sum(x.Нетрудоспособные_койкодней) Нетрудоспособные_койкодней,  --16
 sum(x.Нетрудоспособные_умерло) Нетрудоспособные_умерло, --17
 null к18,  --18  пат вскрытий
 null к19,  --19  расхождений диагнозов
 null к20,  --20  судебных вскрытий
 null к21,  --21  расхождений 
 sum(x.ВозрастомДо18) ВозрастомДо18,   --22
 null к23,  --23 
 null к24,  --24 
 sum(x.ВозрастомДо1) ВозрастомДо1,   --25
 sum(x.ВозрастомДо18_койкодней) ВозрастомДо18_койкодней,  --26
 sum(x.ВозрастомДо1_койкодней) ВозрастомДо1_койкодней,  --27
 sum(x.ВозрастомДо18_умерло) ВозрастомДо18_умерло,   --28
 null к29,  --29  пат вскрытий
 null к30,  --30  расхождений диагнозов
 null к31,  --31  судебных вскрытий
 null к32,  --32  расхождений 
 sum(x.ВозрастомДо1_умерло) ВозрастомДо1_умерло,   --33
 --для контроля
 sum(x.Всего) Всего,
 sum(x.Всего_койкодней) Всего_койкодней,
 sum(x.Всего_умерло) Всего_умерло,
 sum(x.ВозрастомОт18до65_умерло) ВозрастомОт18до65_умерло   --в таблицу 2500 пойдет
from
stat.formgroupmkb gr left join
(
select
 z.Диагноз,
 count(ИД_стацкарты) Всего,
 count(case when (Мертв=1) then ИД_стацкарты else null end) Всего_умерло,
 sum(Койкодней) Всего_койкодней,
 count(case when Возраст<1 and (Мертв<>1) then ИД_стацкарты else null end) ВозрастомДо1,
 sum(case when Возраст<1 then Койкодней else null end) ВозрастомДо1_койкодней,
 count(case when (Возраст<1)and(Мертв=1) then ИД_стацкарты else null end) ВозрастомДо1_умерло, 
 count(case when Возраст<18 and (Мертв<>1) then ИД_стацкарты else null end) ВозрастомДо18,
 sum(case when Возраст<18 then Койкодней else null end) ВозрастомДо18_койкодней,
 count(case when (Возраст<18)and(Мертв=1) then ИД_стацкарты else null end) ВозрастомДо18_умерло,
 count(case when Возраст>=18and (Мертв<>1) then ИД_стацкарты else null end) ВозрастомОт18,
 sum(case when Возраст>=18 then Койкодней else null end) ВозрастомОт18_койкодней,
 count(case when (Возраст>=18)and(Мертв=1) then ИД_стацкарты else null end) ВозрастомОт18_умерло,
 count(case when (Возраст>=18)and(Возраст<=65)and(Мертв=1) then ИД_стацкарты else null end) ВозрастомОт18до65_умерло,
 count(case when (Нетрудоспособный=1)and (Мертв<>1) then ИД_стацкарты else null end) Нетрудоспособные,
 sum(case when Нетрудоспособный=1 then Койкодней else null end) Нетрудоспособные_койкодней,
 count(case when (Нетрудоспособный=1)and(Мертв=1) then ИД_стацкарты else null end) Нетрудоспособные_умерло
from
(
select
 cl.id ИД_пациента,
 hc.id ИД_стацкарты,
 cl.mnemo Мнемокод,
 stat.parep.GetFIOClient(cl.id) Пациент,
 cl.birthday Дата_рождения,
 cl.sex Пол,
 trunc(months_between(hc.outtake_date,cl.birthday)/12) Возраст,
 stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date) Нетрудоспособный,
 (case when p.project_result_type2_id in (-34,-25) then 1 else 0 end) Мертв,
-- p.id ИД_случая,
-- trunc(p.start_date) Начало_случая,
-- trunc(p.end_date) Конец_случая,
 hc.receive_date Поступил,
 hc.outtake_date Выписан,
 stat.parep.GetBedDays(hc.id) Койкодней_некорр,
 /* в 2018 было
 stat.parep.GetBedDays(hc.id)-decode(stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date),1,dd.cor,0) 
   -(case when dd.cor=1 and stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 
                        and substr(mkbfi.code,1,1)='N' and substr(mkbfi.code,1,3)<>'N60' and substr(mkbfi.code,1,2)<>'N7' and substr(mkbfi.code,1,3)<>'N80'  then 3 else 0 end)  Койкодней,
 stat.parep.GetDepname(dep.id) Отделение,
 replace(mkbfi.code,'J',decode(dd.cor,1,'I','J')) Диагноз,
 */
 stat.parep.GetBedDays(hc.id)  Койкодней,
 stat.parep.GetDepname(dep.id) Отделение,
 decode(dd.cor,0,mkbfi.code,
    case when mkbfi.code='G93.4' then 'C00' --Зуев прячем
         when mkbfi.code='L99.8' then 'D23' --Черкашина И.А. 1981, L99 не считается в форме 14
         when mkbfi.code='I11.0' then 'I25.8' --умерший Климов, в стр 10.3 умерших не должно
         else mkbfi.code end) Диагноз,  

 dd.cor Коррекция
-- mkbdi.code Диагноз1

from
 dd, dep, table(stat.parep.GetListBedDischargedPeriod(dd.dtf,dd.dtt,dep.id)) l, hospital.hospital_card hc
 join hospital.project p on p.id=hc.project_id
 join hospital.client cl on cl.id=p.client_id

 --диагнозы
 left join hospital.diagnosis di on di.id=p.main_diagnosis_id
 left join hospital.mkb mkbfi on mkbfi.id=di.mkb10_id
-- left join hospital.disease dis on dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)  --заключительные диагнозы по случаю
--                                   and not exists (select 1 from hospital.disease disx where
--                                                   disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)  --только последний заболевание по случаю
-- left join hospital.mkb mkbdi on mkbdi.id=dis.mkb_id



where
 hc.id=l.hospital_card_id
 --проверка на всякслучай
-- and mkbdi.id<>mkbfi.id
) z
group by
 z.Диагноз


) x on substr(x.Диагноз,1,length(gr.mkbfrom)) between gr.mkbfrom and gr.mkbto

where
 gr.fform='FORM14'

group by
 gr.fgroup, gr.fgroupcode

order by
 stat.parep.GetFormGroupOrder(gr.fgroupcode)

