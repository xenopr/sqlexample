create or replace package body PAREP is

--получить ФИО пациента как строку
  function GetFIOClient(CLIENTID INTEGER) return VARCHAR2
  is
    FIO VARCHAR2(200);
  begin
    FIO:='';
    for ii in (select cl.sur_name||' '||cl.first_name||' '||cl.patr_name ffio from hospital.client cl where cl.id=CLIENTID
    ) loop
       FIO:=initcap(ii.ffio);
    end loop;
    return(FIO);
  end;

--получить ФИО пациента кратко с датой рожденья как строку 
  function GetShortFIOClient(CLIENTID INTEGER) return VARCHAR2
  is
    FIO VARCHAR2(200);
  begin
    FIO:='';
    for ii in (select cl.sur_name||' '||substr(cl.first_name,1,1)||'.'||substr(cl.patr_name,1,1)||'.' ffio from hospital.client cl where cl.id=CLIENTID
    ) loop
       FIO:=initcap(ii.ffio);
    end loop;
    return(FIO);
  end;
  
--получить дату рождения пациента
  function GetBirthDayClient(CLIENTID INTEGER) return DATE
  is
    D DATE default null;
  begin
    for ii in (select cl.birthday dd from hospital.client cl where cl.id=CLIENTID
    ) loop
       D:=ii.dd;
    end loop;
    return(D);
  end;

--получить ФИО врача как строку
  function GetFIOWorker(WORKERID INTEGER) return VARCHAR2
  is
    FIO VARCHAR2(200);
  begin
    FIO:='';
    for ii in (select w.sur_name||' '||w.first_name||' '||w.patr_name ffio from hospital.worker w where w.id=WORKERID
    ) loop
       FIO:=ii.ffio;
       if ltrim(FIO) is null then FIO:=' безымянный '; end if;
    end loop;
    return(FIO);
  end;
  
--получить ФИО с инициалами врача как строку
  function GetShortFIOWorker(WORKERID INTEGER) return VARCHAR2
  is
    FIO VARCHAR2(200);
  begin
    FIO:='';
    for ii in (select w.sur_name||' '||substr(w.first_name,1,1)||'.'||substr(w.patr_name,1,1)||'.' ffio from hospital.worker w where w.id=WORKERID
    ) loop
       FIO:=ii.ffio;
       if ltrim(FIO) is null then FIO:=' безымянный '; end if;
    end loop;
    return(FIO);
  end;  
  
--получить логин врача
  function GetLoginWorker(WORKERID INTEGER) return VARCHAR2
  is
    L VARCHAR2(200) default '';
  begin
    for ii in (select 
                   s.slogin
                 from 
                   hospital.worker w
                   join hospital.suser s on s.id=w.suser_id
                where
                    w.id=WORKERID) loop
       L:=ii.slogin;
    end loop;
    if L is null then
      L:=GetShortFIOWorker(WORKERID)||' без логина';
    end if;
    return(L);
  end;   

--получить ID отделения врача 
  function GetWorkerDepID(WORKERID INTEGER) return NUMBER
  is
    r NUMBER default null;
  begin
    for ii in (select stf.department_id
               from hospital.worker w, hospital.staff stf
               where w.id=WORKERID and stf.id=w.staff_id
    ) loop
       r:=ii.department_id;
    end loop;
    return(r);
  end;
  
--получить специальность врача 
  function GetWorkerSpeciality(WORKERID INTEGER) return VARCHAR2
  is
    r varchar2(2000) default null;
  begin
    for ii in (select spc.name
               from hospital.worker w, hospital.staff stf, hospital.speciality spc
               where w.id=WORKERID and stf.id=w.staff_id and spc.id=stf.speciality_id
    ) loop
       r:=ii.name;
    end loop;
    return(r);
  end;  

--получить последний основной диагноз по пациенту на указанную дату
  function GetLastDiagnose(CLIENTID IN NUMBER, DD IN DATE) return VARCHAR2
  is
   DIAGNOSENAME VARCHAR2(450);
  begin
   DIAGNOSENAME:='';
   for ii in (
     select mkb.code, mkb.name
     from hospital.diagnosis di2, hospital.mkb mkb
     where mkb.id=di2.mkb10_id and
           di2.id=(select max(di.id) from hospital.project p,  hospital.diagnosis di 
                   where p.client_id=CLIENTID
                   and di.project_id=p.id 
                   and di.diagnosis_type_id in (11,12,13,14)
                   and trunc(di.create_date)<=trunc(DD)   --дата_на_которую_смотрим
                ) 
   ) loop
    DIAGNOSENAME:=ii.code||' '||ii.name;
   end loop;
   return(DIAGNOSENAME);
  end;

--получить код последнего основного диагноза по пациенту на указанную дату
  function GetLastDiagnoseCode(CLIENTID IN NUMBER, DD IN DATE) return VARCHAR2
  is
   DIAGNOSECODE VARCHAR2(250);
  begin
   DIAGNOSECODE:='';
   
   for ii in (

     select mkb.code, mkb.name
     from hospital.diagnosis di2, hospital.mkb mkb
     where mkb.id=di2.mkb10_id and
           di2.id=(select max(di.id) from hospital.project p,  hospital.diagnosis di 
                   where p.client_id=CLIENTID
                   and di.project_id=p.id 
                   and di.diagnosis_type_id in (11,12,13,14)
                   and trunc(di.create_date)<=trunc(DD)   --дата_на_которую_смотрим
                ) 
   ) loop
    DIAGNOSECODE:=ii.code;
   end loop;
   return(DIAGNOSECODE);
  end;  
  
--получить последний заключительный диагноз по пациенту на указанную дату
  function GetLastDisease(CLIENTID IN NUMBER, DD IN DATE) return VARCHAR2
  is
   DIAGNOSENAME VARCHAR2(450);
  begin
   DIAGNOSENAME:='';
   for ii in (
     select
        mkbdi.code,
        mkbdi.name
     from
        hospital.project p
        join hospital.disease dis on dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)  --заключительные диагнозы до даты
                                     and trunc(nvl(dis.start_date,to_date('0001','yyyy')))<=trunc(DD)
                                     and not exists (select 1 from hospital.disease disx where 
                                                     trunc(nvl(disx.start_date,to_date('0001','yyyy')))<=trunc(DD) and
                                                     disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)  --только один последний заключительный
        join hospital.mkb mkbdi on mkbdi.id=dis.mkb_id                                                
     where
        p.client_id=CLIENTID 

   ) loop
    DIAGNOSENAME:=ii.code||' '||ii.name;
   end loop;
   return(DIAGNOSENAME);
  end;

--получить код последнего заключительного диагноза по пациенту на указанную дату
  function GetLastDiseaseCode(CLIENTID IN NUMBER, DD IN DATE) return VARCHAR2
  is
   DIAGNOSECODE VARCHAR2(250);
  begin
   DIAGNOSECODE:='';
   
   for ii in (
     select
        mkbdi.code,
        mkbdi.name
     from
        hospital.project p
        join hospital.disease dis on dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)  --заключительные диагнозы до даты
                                     and trunc(nvl(dis.start_date,to_date('0001','yyyy')))<=trunc(DD)
                                     and not exists (select 1 from hospital.disease disx where 
                                                     trunc(nvl(disx.start_date,to_date('0001','yyyy')))<=trunc(DD) and
                                                     disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) 
        join hospital.mkb mkbdi on mkbdi.id=dis.mkb_id                                                
     where
        p.client_id=CLIENTID 

   ) loop
    DIAGNOSECODE:=ii.code;
   end loop;
   return(DIAGNOSECODE);
  end;  
  
--получить код диагноза по случаю указанного типа
-- 1 - заключительный
-- 2 - сопутсвующие
-- 3 - осложнения
-- 4 - предварительные
  function GetProjectMKBCode(DisType IN NUMBER, ProjectID IN NUMBER) return VARCHAR2
  is
   DIAGNOSECODE VARCHAR2(250) default null;
  begin
   DIAGNOSECODE:='';
   if DisType=1 then 
   for ii in (
     select
        mkbdi.code,
        mkbdi.name
     from
        hospital.project p
        join hospital.disease dis on dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)  --заключительный диагноз случая
                                     and not exists (select 1 from hospital.disease disx where 
                                                     disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) 
        join hospital.mkb mkbdi on mkbdi.id=dis.mkb_id                                                
     where
        p.id=ProjectID

   ) loop
    DIAGNOSECODE:=ii.code;
   end loop;
   end if;
   if DisType=2 then 
      for ii in (
     select
        mkbdi.code,
        mkbdi.name
     from
        hospital.project p
        join hospital.disease dis on dis.project_id=p.id and dis.diagnosis_type_id in (-2)  --сопутсвующий диагноз случая
--                                     and not exists (select 1 from hospital.disease disx where 
--                                                     disx.project_id=dis.project_id and disx.diagnosis_type_id in (-2) and disx.id>dis.id) 
        join hospital.mkb mkbdi on mkbdi.id=dis.mkb_id                                                
     where
        p.id=ProjectID

   ) loop
    if DIAGNOSECODE is null then DIAGNOSECODE:=ii.code; else 
      if instr(DIAGNOSECODE,ii.code)=0 then  DIAGNOSECODE:=DIAGNOSECODE||','||ii.code; end if;
     end if;
   end loop;
   end if;
   if DisType=3 then 
      for ii in (
     select
        mkbdi.code,
        mkbdi.name
     from
        hospital.project p
        join hospital.disease dis on dis.project_id=p.id and dis.diagnosis_type_id in (-3)  --осложнения диагноз случая
--                                     and not exists (select 1 from hospital.disease disx where 
--                                                     disx.project_id=dis.project_id and disx.diagnosis_type_id in (-3) and disx.id>dis.id) 
        join hospital.mkb mkbdi on mkbdi.id=dis.mkb_id                                                
     where
        p.id=ProjectID

   ) loop
    if DIAGNOSECODE is null then DIAGNOSECODE:=ii.code; else 
      if instr(DIAGNOSECODE,ii.code)=0 then  DIAGNOSECODE:=DIAGNOSECODE||','||ii.code; end if;
    end if;
   end loop;
   end if;   
   if DisType=4 then 
      for ii in (
     select
        mkbdi.code,
        mkbdi.name
     from
        hospital.project p
        join hospital.disease dis on dis.project_id=p.id and dis.diagnosis_type_id in (-1,-5)  --предварительный диагноз случая и клинический
--                                     and not exists (select 1 from hospital.disease disx where 
--                                                     disx.project_id=dis.project_id and disx.diagnosis_type_id in (-1) and disx.id>dis.id) 
        join hospital.mkb mkbdi on mkbdi.id=dis.mkb_id                                                
     where
        p.id=ProjectID

   ) loop
    if DIAGNOSECODE is null then DIAGNOSECODE:=ii.code; else 
      if instr(DIAGNOSECODE,ii.code)=0 then  DIAGNOSECODE:=DIAGNOSECODE||','||ii.code; end if;
    end if;
   end loop;
   end if;      
   return(DIAGNOSECODE);
  end;   
  
--получить строкой коды всех уникальных основных и сопутсвующих диагнозов пациента после указанной даты
--18 12 2018 под скриннинги, 09092019 param=0 - все диагнозы =1 -только зно
  function GetClientMKBCodes(CLIENTID IN NUMBER, DD IN DATE default to_date('01.01.0001','dd.mm.yyyy'), param in number default 1) return VARCHAR2
  is
   DIAGNOSECODE VARCHAR2(2500);
   DIAGNOSECODEC VARCHAR2(2500);
  begin
   DIAGNOSECODE:='';
   DIAGNOSECODEC:='';
   for ii in (
         select max(di.create_date), mkb.code 
           from hospital.project p,  hospital.diagnosis di, hospital.mkb mkb
          where p.client_id=CLIENTID
                and di.project_id=p.id 
                and mkb.id=di.mkb10_id
                and di.diagnosis_type_id in (11,12,13,14,15,16,17,18)
                and di.create_date>=trunc(DD) 
          group by  mkb.code      
          order by max(di.create_date), mkb.code       
   ) loop 
    if DIAGNOSECODEC is null and substr(ii.code,1,1) in ('D','C') and param=1 then DIAGNOSECODEC:=ii.code; else 
      if substr(ii.code,1,1) in ('D','C') and instr(DIAGNOSECODEC,ii.code)=0 and length(DIAGNOSECODEC)<2450 then DIAGNOSECODEC:=DIAGNOSECODEC||','||ii.code; end if;
    end if;
    if DIAGNOSECODE is null and DIAGNOSECODEC is null then DIAGNOSECODE:=ii.code; else 
      if instr(DIAGNOSECODE,ii.code)=0 and length(DIAGNOSECODE)<2450 then  DIAGNOSECODE:=DIAGNOSECODE||','||ii.code; end if;
    end if;     
   end loop;
   if DIAGNOSECODEC is not null then DIAGNOSECODE:=DIAGNOSECODEC; end if;
   return(DIAGNOSECODE);
  end;    
  
--получить дату первого установления основного либо сопутсвующего диагноза пациента после указанной даты
--20 12 2018 под скриннинги
  function GetClientMKBDate(CLIENTID IN NUMBER, DD IN DATE default to_date('01.01.0001','dd.mm.yyyy')) return DATE
  is
   D DATE default null;
  begin
   for ii in (
         select min(di.create_date) d 
           from hospital.project p,  hospital.diagnosis di, hospital.mkb mkb
          where p.client_id=CLIENTID
                and di.project_id=p.id 
                and mkb.id=di.mkb10_id
                and di.diagnosis_type_id in (11,12,13,14,15,16,17,18)
                and di.create_date>=trunc(DD) 
          order by di.create_date       
   ) loop 
     D:=ii.d;
   end loop;
   return(D);
  end;      
  
--получить самый первый основной диагноз пациента после указанной даты
--диагнозы C,D - в приоритете
--05 06 2019
  function GetClientFinalMKB(CLIENTID IN NUMBER, DD IN DATE default to_date('01.01.0001','dd.mm.yyyy')) return VARCHAR2
  is
   r varchar2(100) default null;
  begin
   for ii in (
         select mkb.code
           from hospital.project p,  hospital.diagnosis di, hospital.mkb mkb
          where p.client_id=CLIENTID
                and di.project_id=p.id 
                and mkb.id=di.mkb10_id
                and di.diagnosis_type_id in (11,12,13,14)
                and di.create_date>=trunc(DD) 
          order by decode(substr(mkb.code,1,1),'C',0,'D',1,'N',2,'E',3,4) asc, di.create_date asc    
   ) loop 
     r:=ii.code;
     exit;
   end loop;
   return(r);
  end;   

--получить название самого первого основного диагноза пациента после указанной даты
--диагнозы C,D - в приоритете
--15 02 2021
  function GetClientFinalMKBName(CLIENTID IN NUMBER, DD IN DATE default to_date('01.01.0001','dd.mm.yyyy')) return VARCHAR2
  is
   r varchar2(3000) default null;
  begin
   for ii in (
         select mkb.code, mkb.name
           from hospital.project p,  hospital.diagnosis di, hospital.mkb mkb
          where p.client_id=CLIENTID
                and di.project_id=p.id 
                and mkb.id=di.mkb10_id
                and di.diagnosis_type_id in (11,12,13,14)
                and di.create_date>=trunc(DD) 
          order by decode(substr(mkb.code,1,1),'C',0,'D',1,'N',2,'E',3,4) asc, di.create_date asc    
   ) loop 
     r:=ii.name;
     exit;
   end loop;
   return(r);
  end;  

--получить дату первого установления основного диагноза пациента после указанной даты
--диагнозы C,D - в приоритете
--05 06 2019
  function GetClientFinalMKBDate(CLIENTID IN NUMBER, DD IN DATE default to_date('01.01.0001','dd.mm.yyyy')) return DATE
  is
   D DATE default null;
  begin
   for ii in (
         select di.create_date d 
           from hospital.project p,  hospital.diagnosis di, hospital.mkb mkb
          where p.client_id=CLIENTID
                and di.project_id=p.id 
                and mkb.id=di.mkb10_id
                and di.diagnosis_type_id in (11,12,13,14)
                and di.create_date>=trunc(DD) 
          order by decode(substr(mkb.code,1,1),'C',0,'D',1,'N',2,'E',3,4) asc, di.create_date asc
   ) loop 
     D:=ii.d;
     exit;
   end loop;
   return(D);
  end; 

--получить список кодов сопутсвующих заболеваний канцер-выписки
  function GetCancerAccompanyCode(CancerSummaryID IN NUMBER) return VARCHAR2
  is
   DIAGNOSECODE VARCHAR2(250);
  begin
   DIAGNOSECODE:='';
   for ii in (
     select
        mkbc.code,
        mkbc.name
     from
        hospital.cancer_sum_diagnosis csd
        join hospital.mkb mkbc on mkbc.id=csd.mkb_id
        left join hospital.disease di on di.id=csd.diagnosis_id
     where  
         csd.cancer_summary_id=CancerSummaryID
         and nvl(di.diagnosis_type_id,-2) in (-2)  --сопутсвующее заболевание

   ) loop
    DIAGNOSECODE:=DIAGNOSECODE||' '||ii.code;
   end loop;
   return(ltrim(DIAGNOSECODE));
  end;    
  
  

--получить дату последней выполненной услуги совпадающей с датой в расписании по клиенту ранее указанной даты в пределах указанного количества дней
  function GetLastExecutedServiceDate(CLIENTID IN NUMBER, DD IN DATE, NN INTEGER) return DATE
  is
   returndate DATE;
   returndate_s DATE;
   returndate_p DATE;
  begin
    returndate:=null;
    for ii in (select so.operation_date maxdate
             from hospital.service s, hospital.project p, hospital.service_operation so, hospital.event ev1
             where p.client_id=CLIENTID --смотреть через случаи
                   and s.project_id=p.id 
                   and so.service_id=s.id
                   and ev1.client_id=CLIENTID 
                   and trunc(so.operation_date)=trunc(ev1.start_date)
                   and so.operation_date>(DD-NN)
                   and so.operation_date<trunc(DD)
                   and so.operation_type_id=4
             order by so.id desc     
              ) loop
       returndate_s:=ii.maxdate;          
       exit;
    end loop;         
    for ii in (select so.operation_date maxdate
             from hospital.service s, hospital.service_operation so, hospital.event ev1
             where s.client_id=CLIENTID --смотреть через сервисы
                   and so.service_id=s.id
                   and ev1.client_id=CLIENTID 
                   and trunc(so.operation_date)=trunc(ev1.start_date)
                   and so.operation_date>(DD-NN)
                   and so.operation_date<trunc(DD)
                   and so.operation_type_id=4
             order by so.id desc      
               ) loop
       returndate_p:=ii.maxdate;          
       exit;
    end loop;         
    if returndate_s>returndate_p then
     returndate:=returndate_s;
    else                
     returndate:=returndate_p;
    end if; 
/*    for ii in (select max(so.operation_date) maxdate
             from hospital.service s, hospital.service_operation so, hospital.event ev1
             where CLIENTID=nvl(s.client_id,(select p.client_id from hospital.project p where p.id=s.project_id)) --смотреть и случаи
                   and so.service_id=s.id
                   and ev1.client_id=CLIENTID 
                   and trunc(so.operation_date)=trunc(ev1.start_date)
                   and so.operation_date>(DD-NN)
                   and so.operation_date<trunc(DD)
                   and so.operation_type_id=4    ) loop
     returndate:=ii.maxdate              ;
    end loop;               */

    return(returndate);
  end; 
  
--получить все телефоны пациента
  function GetClientTlf(CLIENTID IN NUMBER) return VARCHAR2
  is
    tlfs varchar2(1000);
  begin
   tlfs:='';
   for ii in (select tlf.contact_value 
              from hospital.client_contact tlf 
              where tlf.client_id=CLIENTID and tlf.contact_info_type_id in(16,80,81,82,83,84) ) loop
    tlfs:=tlfs||replace(replace(replace(replace(ii.contact_value,' ',''),')',''),'(',''),'-','')||' ';          
   end loop;           
   tlfs:=trim(tlfs);
   return(tlfs);
  end;
  
--определить городской или сельский житель
  function GetClientIsCity(CLIENTID IN NUMBER) return VARCHAR2
  is
    vret VARCHAR2(100);
  begin
    vret:='Unknown';
    for ii in( 
      select 
       substr(a.kladr_code,6,3) city
      from
       hospital.client_address ca  left join hospital.address a on ca.address_id=a.id 
      where
       ca.client_id=CLIENTID and ca.contact_info_type_id=77    --в медгороде в поле адрес проживания живет адрес прописки
       and not exists (select 1 from hospital.client_address cax
                       where cax.client_id=CLIENTID and cax.contact_info_type_id=77 and cax.id>ca.id) --только последний адрес прописки
    ) loop
      if ii.city<>'000' then vret:='City'; end if; --прописка городская
      if ii.city='000' then vret:='Village'; end if;  --прописка сельская
    end loop;                   
    return(vret);
  end;
  
--Вернуть возраст пациента на дату, по умолчанию - на сегодня
  function GetClientAge(CLIENTID IN NUMBER, DD IN DATE default SYSDATE) return NUMBER
  is
    n NUMBER default null;
  begin
    for ii in (
      select trunc(months_between(trunc(DD),cl.birthday)/12) a 
        from hospital.client cl 
       where cl.id=CLIENTID
    ) loop
      n:=ii.a;
    end loop;  
    return(n);    
  end;
  
--Вернуть признак, пациент старше трудоспособного возраста, на указанную дату по умолчанию - на сегодня
--1 - пенсионер, 0 - не пенсионер, null - не найден
--0712202 согласно приказу росстата 409 от 17.07.2019 возраст нетрудоспособных определяется с коэффициентом на указанный год
--год отчетный канцеров с 26 по 25 число
--18 12 2020 по трудоспособному возрасту оставляем все как раньше, в МИАЦ так сказали, приказов никаких не было (Подгальняя)
--25 12 2020 МИАЦ, да, по приказу теперь
  function GetClientIsPensioner(CLIENTID IN NUMBER, DD IN DATE default SYSDATE) return NUMBER
  is
    n NUMBER default null;
    p number;
    y number;
  begin
    y:=extract(year from DD+6); 
    p:=case when y in (2020,2021) then 1
            when y in (2022,2023) then 2
            when y in (2024,2025) then 3
            when y in (2026,2027) then 4    
            when y>2027 then 5
       else 0 end;
    for ii in (
      select (case when (cl.sex='М' and trunc(months_between(DD,cl.birthday)/12)>=(60+p))or
                        (cl.sex='Ж' and trunc(months_between(DD,cl.birthday)/12)>=(55+p)) then 1 else 0 end) a 
        from hospital.client cl 
       where cl.id=CLIENTID
    ) loop
      n:=ii.a;
    end loop;  
    return(n);    
  end;
  
--определить относится ли человек к югу тюменской области - т.е. тюменской области, к г.тюмень, иной, неизвестно
  function GetClientIsTyumen(CLIENTID IN NUMBER) return VARCHAR2
  is
    vret VARCHAR2(100);
  begin
    vret:='Unknown';
    for ii in( 
      select 
       substr(a.kladr_code,6,3) city,
       substr(a.kladr_code,3,3) place,
       substr(a.kladr_code,1,2) region
      from
       hospital.client_address ca  left join hospital.address a on ca.address_id=a.id 
      where
       ca.client_id=CLIENTID and ca.contact_info_type_id=77   --в медгороде в поле адрес проживания живет адрес прописки
       and not exists (select 1 from hospital.client_address cax
                       where cax.client_id=CLIENTID and cax.contact_info_type_id=77 and cax.id>ca.id) --только последний адрес прописки
    ) loop
      if ii.region='72' then vret:='South'; end if;  --прописка юг тюменской области, т.е. область
      if ii.region='72' and ii.place='000' and ii.city='001' then vret:='Tyumen'; end if; --прописка в тюмени
      if ii.region<>'72' then vret:='Outline'; end if;  --прописка вне области
    end loop;                   
    return(vret);
  end;  
  
--определить относится ли человек к югу тюменской области на русском
  function GetClientIsTyumenRus(CLIENTID IN NUMBER) return VARCHAR2       
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=GetClientIsTyumen(CLIENTID);
    SSOUT:=replace(SSOUT,'Unknown','Неопределимо');
    SSOUT:=replace(SSOUT,'South','ТюмОбласть');
    SSOUT:=replace(SSOUT,'Tyumen','Тюмень'); 
    SSOUT:=replace(SSOUT,'Outline','Внешние');           
    return(SSOUT);
  end;   

--паспорт пациента
  function GetClientPassport(CLIENTID IN NUMBER) return VARCHAR2       
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:='';
    for ii in (select cd.* from 
               hospital.client_document cdd 
               left join hospital.document cd on cd.id=cdd.document_id and cd.document_type_id=23     --паспорт
               where cdd.client_id=CLIENTID
--               order by cdd.id
               )
    loop
      SSOUT:=ii.ser||' '||ii.num||' выдан '||to_char(ii.give_out_date,'dd.mm.yyyy')||' '||ii.organisation_text||' код подр.'||ii.subdivision_code; 
    end loop;           
    return(SSOUT);
  end;
     
--получить адрес пациента (адрес регистрации)
  function GetClientAddress(CLIENTID IN NUMBER) return VARCHAR2
  is    
    addrs varchar2(4000);
  begin
    addrs:='';
    for ii in (select a.full_name,' д.'||ca.house||decode(ca.building,null,'',' корп.'||ca.building)||decode(ca.flat,null,'',' кв.'||ca.flat) faddrs 
      from
       hospital.client_address ca  left join hospital.address a on ca.address_id=a.id 
      where
       ca.client_id=CLIENTID and ca.contact_info_type_id=78
       and not exists (select 1 from hospital.client_address cax
                       where cax.client_id=CLIENTID and cax.contact_info_type_id=78 and cax.id>ca.id) --только последний адрес прописки 
    ) loop
      addrs:=ii.full_name||' '||ii.faddrs;
    end loop;
    return(addrs);
  end; 
  
--получить адрес пациента адрес проживания (в медгороде это адрес прописки)
  function GetClientLiveAddress(CLIENTID IN NUMBER) return VARCHAR2
  is    
    addrs varchar2(4000);
  begin
    addrs:='';
    for ii in (select a.full_name,' д.'||ca.house||decode(ca.building,null,'',' корп.'||ca.building)||decode(ca.flat,null,'',' кв.'||ca.flat) faddrs 
      from
       hospital.client_address ca  left join hospital.address a on ca.address_id=a.id 
      where
       ca.client_id=CLIENTID and ca.contact_info_type_id=77 
       and not exists (select 1 from hospital.client_address cax
                       where cax.client_id=CLIENTID and cax.contact_info_type_id=77 and cax.id>ca.id) --только последний адрес прописки
    ) loop
      addrs:=ii.full_name||' '||ii.faddrs;
    end loop;
    return(addrs);
  end; 
  
--получить гражданство
  function GetClientCitizenship(CLIENTID IN NUMBER) return VARCHAR2
  is    
    v varchar2(4000);
  begin
    v:='';
    for ii in (select c.name n
      from
        hospital.client cl 
        join hospital.citizenship c on c.id=cl.citizenship_id
      where
       cl.id=CLIENTID
    ) loop
      v:=ii.n;
    end loop;
    return(v);
  end;  
  
--получить адрес кодом КЛАДР (в медгороде это адрес прописки)
  function GetClientLiveKLADR(CLIENTID IN NUMBER) return VARCHAR2
  is    
    addrs varchar2(4000);
  begin
    addrs:='';
    for ii in (select a.kladr_code  faddrs 
      from
       hospital.client_address ca  left join hospital.address a on ca.address_id=a.id 
      where
       ca.client_id=CLIENTID and ca.contact_info_type_id=77 
       and not exists (select 1 from hospital.client_address cax
                       where cax.client_id=CLIENTID and cax.contact_info_type_id=77 and cax.id>ca.id) --только последний адрес прописки
    ) loop
      addrs:=ii.faddrs;
    end loop;
    return(addrs);
  end;  
  
--получить дату последней выполненной услуги у пациента на дату
  function GetLastServiceDate(CLIENTID IN NUMBER, DD IN DATE) return DATE   
  is
   D DATE;
  begin
    for ii  in (select so.operation_date execdate
                from hospital.service_operation so
                     join hospital.service s on s.id=so.service_id 
                     join hospital.project p on p.id=s.project_id and p.client_id=CLIENTID
                where
                   so.operation_date<=DD
                   and so.operation_type_id=4  -- смотрим только выполненные услуги без операции отмена выполнения
                   and not exists (select 1 from hospital.service_operation so1 where so1.service_id=s.id and so1.operation_type_id=10 and so1.id>so.id)
                ) loop
      if nvl(D,to_date('1','yyyy'))<ii.execdate then D:=ii.execdate; end if;               
    end loop;                
    return(D); 
  end; 
  
--получить текстом всю команду оперерирующих для операции в выписке ЗНО
  function GetCancerSurgeryCommand(CSST_ID IN NUMBER) return VARCHAR2
  is
   SS VARCHAR2(4000);
  begin
    SS:='';
    for ii  in (
      select 
       swr.name rolename, swo.sur_name||' '||swo.first_name||' '||swo.patr_name fio
      from 
       hospital.cancer_sum_surgery_worker sw 
       left join hospital.surgery_worker_role swr on swr.id=sw.role_id
       left join hospital.worker swo on swo.id=sw.worker_id 
      where
       sw.cancer_summary_surgery_id=CSST_ID 
      order by
       sw.role_id, sw.id ) loop
     SS:=SS||' '||ii.rolename||' '||ii.fio;
    end loop;                
    SS:=ltrim(SS);
    return(SS); 
  end; 
  
--получить текстом всю команду оперерирующих для операции в выписке ЗНО, кратко
  function GetShortCancerSurgeryCommand(CSST_ID IN NUMBER) return VARCHAR2
  is
   SS VARCHAR2(4000);
  begin
    SS:='';
    for ii  in (
      select 
       decode(swr.id,1,'хир',2,'асс') rolename, swo.sur_name||' '||substr(swo.first_name,1,1)||'.'||substr(swo.patr_name,1,1)||'.' fio
      from 
       hospital.cancer_sum_surgery_worker sw 
       left join hospital.surgery_worker_role swr on swr.id=sw.role_id
       left join hospital.worker swo on swo.id=sw.worker_id 
      where
       sw.cancer_summary_surgery_id=CSST_ID  and swr.id in (1,2)
      order by
       sw.role_id, sw.id ) loop
     if instr(SS,chr(13)||'асс ')=0 and ii.rolename='асс' then
       SS:=SS||chr(13)||ii.rolename||' '||ii.fio;
     else
       SS:=SS||' '||ii.rolename||' '||ii.fio;
     end if; 
    end loop;                
    SS:=ltrim(SS);
    return(SS); 
  end;   
  
--получить текстом всю команду оперерирующих для операции 
  function GetSurgeryCommand(SurgeryID IN NUMBER) return VARCHAR2
  is
   SS VARCHAR2(4000);
  begin
    SS:='';
    for ii  in (
      select 
       swr.name rolename, swo.sur_name||' '||swo.first_name||' '||swo.patr_name fio
      from 
       hospital.surgery_worker sw 
       left join hospital.surgery_worker_role swr on swr.id=sw.surgery_worker_role_id
       left join hospital.worker swo on swo.id=sw.worker_id 
      where
       sw.surgery_id=SurgeryID 
      order by
       sw.surgery_worker_role_id, sw.id ) loop
     SS:=SS||' '||ii.rolename||' '||ii.fio;
    end loop;                
    SS:=ltrim(SS);
    return(SS); 
  end;   
  
--получить текстом всю команду оперерирующих для операции, кратко
  function GetShortSurgeryCommand(SurgeryID IN NUMBER) return VARCHAR2
  is
   SS VARCHAR2(4000);
  begin
    SS:='';
    for ii  in (
      select 
       decode(swr.id,1,'хир',2,'асс') rolename, swo.sur_name||' '||substr(swo.first_name,1,1)||'.'||substr(swo.patr_name,1,1)||'.' fio
      from 
       hospital.surgery_worker sw 
       left join hospital.surgery_worker_role swr on swr.id=sw.surgery_worker_role_id
       left join hospital.worker swo on swo.id=sw.worker_id 
      where
       sw.surgery_id=SurgeryID and swr.id in (1,2) 
      order by
       sw.surgery_worker_role_id, sw.id ) loop
     if instr(SS,chr(13)||'асс ')=0 and ii.rolename='асс' then
       SS:=SS||chr(13)||ii.rolename||' '||ii.fio;
     else
       SS:=SS||' '||ii.rolename||' '||ii.fio;
     end if;  
    end loop;                
    SS:=ltrim(SS);
    return(SS); 
  end;     
  
--Получить расшифровки  
--Житель города,села
  function GetCancerLocalityType(SSIN IN VARCHAR2) return VARCHAR2
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'City','Города');
    SSOUT:=replace(SSOUT,'0','Города');
    SSOUT:=replace(SSOUT,'Village','Села');
    SSOUT:=replace(SSOUT,'1','Села');
    SSOUT:=replace(SSOUT,'Unknown','Неизвестно');    
    SSOUT:=replace(SSOUT,'2','Неизвестно');          
    return(SSOUT);
  end;  

--Стадии опухолевого процесса
  function GetCancerStage(SSIN IN VARCHAR2) return VARCHAR2
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'Stage1a','I а');
    SSOUT:=replace(SSOUT,'Stage1b','I б');
    SSOUT:=replace(SSOUT,'Stage1c','I с');
    SSOUT:=replace(SSOUT,'Stage2a','II а');    
    SSOUT:=replace(SSOUT,'Stage2b','II б');
    SSOUT:=replace(SSOUT,'Stage2c','II с');    
    SSOUT:=replace(SSOUT,'Stage3a','III а');    
    SSOUT:=replace(SSOUT,'Stage3b','III б');
    SSOUT:=replace(SSOUT,'Stage3c','III с');    
    SSOUT:=replace(SSOUT,'Stage4a','IV а');    
    SSOUT:=replace(SSOUT,'Stage4b','IV б');
    SSOUT:=replace(SSOUT,'Stage4c','IV с');    
    SSOUT:=replace(SSOUT,'Stage1','I стадия');    
    SSOUT:=replace(SSOUT,'Stage2','II стадия');    
    SSOUT:=replace(SSOUT,'Stage3','III стадия');                
    SSOUT:=replace(SSOUT,'Stage4','IV стадия');    
    SSOUT:=replace(SSOUT,'InSitu','In situ');    
    SSOUT:=replace(SSOUT,'Inapplicable','Неприменимо');        
    SSOUT:=replace(SSOUT,'Unknown','Неизвестно');            
    return(SSOUT);
  end;  

--Локализации отдаленных метастазов
  function GetCancerMetastasisAreas(SSIN IN VARCHAR2) return VARCHAR2
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'RemoteLymphNodes','Отдаленные лимфатические узлы');
    SSOUT:=replace(SSOUT,'Liver','Печень');
    SSOUT:=replace(SSOUT,'Bones','Кости');
    SSOUT:=replace(SSOUT,'Lungs','Легкие и/или плевра');    
    SSOUT:=replace(SSOUT,'Brain','Головной мозг');
    SSOUT:=replace(SSOUT,'Skin','Кожа');    
    SSOUT:=replace(SSOUT,'Kidneys','Почки');    
    SSOUT:=replace(SSOUT,'Ovaries','Яичники');
    SSOUT:=replace(SSOUT,'Peritoneum','Брюшина');    
    SSOUT:=replace(SSOUT,'BoneMarrow','Костный мозг');    
    SSOUT:=replace(SSOUT,'OtherBodyParts','Другие органы');
    SSOUT:=replace(SSOUT,'Multiple','Множественные');    
    SSOUT:=replace(SSOUT,'Unknown','Неизвестно');    
    return(SSOUT);
  end;  
  
--Методы подтверждения диагноза
  function GetCancerConfirmMethods(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'Morphological','Морфологический');
    SSOUT:=replace(SSOUT,'Citology','Цитологический');
    SSOUT:=replace(SSOUT,'ExploratoryOperation','Эсплоративная операция');
    SSOUT:=replace(SSOUT,'LaboratoryTool','Лабораторно-инструментальный');    
    SSOUT:=replace(SSOUT,'OnlyClinic','Только клинический');
    SSOUT:=replace(SSOUT,'Unknown','Неизвестен');    
    return(SSOUT);
  end;  
  
--Причины поздней диагностики
  function GetCancerCauseOfLateDiagnosis(SSIN IN VARCHAR2) return VARCHAR2
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'LatentCourse','Скрытое течение болезни');
    SSOUT:=replace(SSOUT,'LateAppeal','Несвоевременное обращение');
    SSOUT:=replace(SSOUT,'RefusalOfExamination','Отказ от обследования');
    SSOUT:=replace(SSOUT,'IncompleteOfExamination','Неполное обследование');    
    SSOUT:=replace(SSOUT,'InsufficiencyOfMedicalExamination','Несовершенство диспансеризации');
    SSOUT:=replace(SSOUT,'ClinicalError','Ошибка клиническая');    
    SSOUT:=replace(SSOUT,'XrayError','Ошибка рентгенологическая');    
    SSOUT:=replace(SSOUT,'MorphologicalError','Ошибка морфологическая');
    SSOUT:=replace(SSOUT,'ErrorOfOtherSpecialists','Ошибка других специалистов');    
    SSOUT:=replace(SSOUT,'OtherReasons','Другие причины');    
    SSOUT:=replace(SSOUT,'Unknown','Неизвестны');            
    return(SSOUT);
  end;  

--Обстоятельства выявления опухоли
  function GetCancerDetectionCircum(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'ByYourself','Обратился сам');
    SSOUT:=replace(SSOUT,'0','Обратился сам');
    SSOUT:=replace(SSOUT,'ActiveInMedicalExamination','Активно, при профосмотре');
    SSOUT:=replace(SSOUT,'1','Активно, при профосмотре');
    SSOUT:=replace(SSOUT,'ActiveInWatchRoom','Активно, в смотровом кабинете');
    SSOUT:=replace(SSOUT,'2','Активно, в смотровом кабинете');
    SSOUT:=replace(SSOUT,'AnotherCircumstances','При других обстоятельствах');  
    SSOUT:=replace(SSOUT,'3','При других обстоятельствах');   
    SSOUT:=replace(SSOUT,'Unknown','Неизвестно');    
    SSOUT:=replace(SSOUT,'4','Неизвестно');          
    return(SSOUT);
  end; 
  
--Цель госпитализации
  function GetCancerHospitalizationGoal(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Лечение первичной опухоли');
    SSOUT:=replace(SSOUT,'1','Продолжение лечения первичной опухоли');
    SSOUT:=replace(SSOUT,'2','Лечение рецидива заболевания');
    SSOUT:=replace(SSOUT,'3','Продолжение лечения рецидива заболевания');
    SSOUT:=replace(SSOUT,'4','Дообследование');
    SSOUT:=replace(SSOUT,'5','Реабилитация');
    SSOUT:=replace(SSOUT,'6','Лечение поздних осложнений');  
    SSOUT:=replace(SSOUT,'7','Симптоматическое лечение');   
    SSOUT:=replace(SSOUT,'8','Лечение сопутствующих заболеваний');    
    SSOUT:=replace(SSOUT,'9','Другая');          
    return(SSOUT);
  end;   

--Результат госпитализации
  function GetCancerHospitalizationResult(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'22','Не проводилось. Отказ от лечения');
    SSOUT:=replace(SSOUT,'23','Не проводилось. Болезнь слишком запущена');  
    SSOUT:=replace(SSOUT,'24','Не проводилось. Плохое общее состояние больного');   
    SSOUT:=replace(SSOUT,'26','Не проводилось. Смерть');    
    SSOUT:=replace(SSOUT,'29','Не проводилось. Другие');     
    SSOUT:=replace(SSOUT,'11','Не закончено. Ухудшение состояния');
    SSOUT:=replace(SSOUT,'12','Не закончено. Прогрессирование процесса');  
    SSOUT:=replace(SSOUT,'13','Не закончено. Осложнения');   
    SSOUT:=replace(SSOUT,'14','Не закончено. Перерыв в лечении');    
    SSOUT:=replace(SSOUT,'15','Не закончено. Смерть');     
    SSOUT:=replace(SSOUT,'1','Лечение закончено радикально');
    SSOUT:=replace(SSOUT,'2','Лечение закончено паллиативно');
    SSOUT:=replace(SSOUT,'3','Лечение закончено симптоматически');
    SSOUT:=replace(SSOUT,'4','Лечение закончено. Реабилитация и лечение поздних осложнений');
    SSOUT:=replace(SSOUT,'5','Лечение закончено. Дообследование');
    return(SSOUT);
  end;   
  
--Характер лечения
  function GetCancerNeoplTreaCharacter(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Радикальное, полное');
    SSOUT:=replace(SSOUT,'1','Радикальное, неполное');
    SSOUT:=replace(SSOUT,'2','Паллиативное');
    SSOUT:=replace(SSOUT,'3','Симптоматическое лечение специальными методами');
    SSOUT:=replace(SSOUT,'4','Симптоматическое');
    SSOUT:=replace(SSOUT,'5','Соматические противопоказания');
    SSOUT:=replace(SSOUT,'6','Отказ больного от лечения');  
    return(SSOUT);
  end;     
  
--Причина незавершенности лечения
  function GetCancerNeoplIncomplCause(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Отказ больного от продолжения лечения');
    SSOUT:=replace(SSOUT,'1','Осложнения лечения');
    SSOUT:=replace(SSOUT,'2','Отрицательная динамика заболевания на фоне лечения');
    SSOUT:=replace(SSOUT,'3','Запланированный перерыв');
    SSOUT:=replace(SSOUT,'4','Другая');
    return(SSOUT);
  end;      

--Результат лечения
  function GetCancerTreatmentResult(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Выздоровление');
    SSOUT:=replace(SSOUT,'1','Улучшение');
    SSOUT:=replace(SSOUT,'2','Без перемен');
    SSOUT:=replace(SSOUT,'3','Ухудшение');
    SSOUT:=replace(SSOUT,'4','Обследование');
    SSOUT:=replace(SSOUT,'5','Умер от злокачественного новообразования');
    SSOUT:=replace(SSOUT,'6','Умер от другого заболевания');
    SSOUT:=replace(SSOUT,'7','Отказ больного от лечения');
    SSOUT:=replace(SSOUT,'8','Отказ в специальном лечении сопут.патологии');
    return(SSOUT);
  end;  
  
--Модифицирующие средства лучевого лечения
  function GetCancerRadModifyingTools(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'10','сочетание радиомодификаторов');
    SSOUT:=replace(SSOUT,'11','АОК - антиоксидантный комплекс');
    SSOUT:=replace(SSOUT,'12','не использовались');
    SSOUT:=replace(SSOUT,'13','неизвестно');
    SSOUT:=replace(SSOUT,'Non','Нет');
    SSOUT:=replace(SSOUT,'0','Нет');
    SSOUT:=replace(SSOUT,'1','ГБО');
    SSOUT:=replace(SSOUT,'2','электронакцентные соединения');
    SSOUT:=replace(SSOUT,'3','гипертермия');
    SSOUT:=replace(SSOUT,'4','гипергликемия');
    SSOUT:=replace(SSOUT,'5','гипоксия');
    SSOUT:=replace(SSOUT,'6','гипотермия');
    SSOUT:=replace(SSOUT,'7','лекарственные препараты');
    SSOUT:=replace(SSOUT,'8','иммуномодуляторы');
    SSOUT:=replace(SSOUT,'9','радиофармпрепараты');
    return(SSOUT);
  end;  
  
--Канцер-выписка, пункт 26_1 хир.лечение
  function GetCancerItem26_1(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Первичное');
    SSOUT:=replace(SSOUT,'1','Повторное');
    return(SSOUT);
  end;    

--Канцер-выписка, пункт 26_2 хир.лечение
  function GetCancerItem26_2(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Радикальное');
    SSOUT:=replace(SSOUT,'1','Паллиативное');
    SSOUT:=replace(SSOUT,'2','Симптоматическое');
    SSOUT:=replace(SSOUT,'3','Удаление mts');
    SSOUT:=replace(SSOUT,'4','Хирургическая гормонотерапия'); 
    SSOUT:=replace(SSOUT,'5','Диагностическая');
    SSOUT:=replace(SSOUT,'6','Реконструктивная');
    return(SSOUT);
  end;      
  
--Канцер-выписка, применение лучевой терапии  rad_treat_using 
  function GetCancerRadTreatUsing(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Неизвестно');
    SSOUT:=replace(SSOUT,'1','При лечении первичной опухоли');
    SSOUT:=replace(SSOUT,'2','При лечении рецедива опухоли');
    SSOUT:=replace(SSOUT,'3','При лечении метастазов');
    SSOUT:=replace(SSOUT,'4','При лечении системных заболеваний');    
    return(SSOUT);
  end;     

--Канцер-выписка, условия применения лучевой терапии  rad_treat_using_conditions
  function GetCancerRadTreatUsingCond(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Неизвестно');
    SSOUT:=replace(SSOUT,'1','Амбулаторно');
    SSOUT:=replace(SSOUT,'2','Стационарно');
    return(SSOUT);
  end;    
  
--Канцер-выписка, пункт 27_1 рад.лечение  rad_treat_number
  function GetCancerItem27_1(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Первичное');
    SSOUT:=replace(SSOUT,'1','Повторное');
    return(SSOUT);
  end;       

--Канцер-выписка, пункт 27_2 рад.лечение rad_treat_mode
  function GetCancerItem27_2(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Непрерывное');
    SSOUT:=replace(SSOUT,'1','Расщепленное');
    return(SSOUT);
  end;   
  
--Канцер-выписка, пункт 27_3 рад.лечение rad_treat_power
  function GetCancerItem27_3(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Радикальное');
    SSOUT:=replace(SSOUT,'1','Паллиативное');
    SSOUT:=replace(SSOUT,'2','Симптоматическое');
    return(SSOUT);
  end;     
    
--Канцер-выписка, пункт 27_4 рад.лечение  rad_treat_type
  function GetCancerItem27_4(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Самостоятельное');
    SSOUT:=replace(SSOUT,'1','Предоперационное');
    SSOUT:=replace(SSOUT,'2','Послеоперационное');
    SSOUT:=replace(SSOUT,'3','С химиотерапией');
    SSOUT:=replace(SSOUT,'4','Пред и послеоперационное'); 
    return(SSOUT);
  end;   
  
--Канцер-выписка, пункт 28_1 хим.лечение
  function GetCancerItem28_1(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Первичное');
    SSOUT:=replace(SSOUT,'1','Повторное');
    return(SSOUT);
  end;       

--Канцер-выписка, пункт 28_2 хим.лечение
  function GetCancerItem28_2(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'0','Самостоятельная');
    SSOUT:=replace(SSOUT,'1','Неоадъювантная');
    SSOUT:=replace(SSOUT,'2','Адъювантная');
    SSOUT:=replace(SSOUT,'3','Неизвестно');
    return(SSOUT);
  end;   
  
--Анестезия, сопутсвующие заболевания  
  function GetCancerAnesthesiaRelated(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'10','Печеночная недостаточность');
    SSOUT:=replace(SSOUT,'11','Сахарный диабет');
    SSOUT:=replace(SSOUT,'12','Тиреотоксикоз');
    SSOUT:=replace(SSOUT,'13','Тромбофлебит вен н/конечностей');
    SSOUT:=replace(SSOUT,'14','Гипертоническая болезнь');
    SSOUT:=replace(SSOUT,'15','Другие');
    SSOUT:=replace(SSOUT,'16','Кровотечение');
    SSOUT:=replace(SSOUT,'17','Перетонит');
    SSOUT:=replace(SSOUT,'18','Непроходимость кишечника');
    SSOUT:=replace(SSOUT,'19','Стеноз выхода желудка');
    SSOUT:=replace(SSOUT,'20','Сахарный диабет + ССЗ');
    SSOUT:=replace(SSOUT,'21','Сахарный диабет + дыхательная недостаточность');
    SSOUT:=replace(SSOUT,'22','Блокада проводящей системы сердца');
    SSOUT:=replace(SSOUT,'23','Кровотечение + дыхательная недостаточность');
    SSOUT:=replace(SSOUT,'24','Кровотечение + сердечно-сосудистая недостаточность');
    SSOUT:=replace(SSOUT,'25','Кровотечение + сахарный диабет');
    SSOUT:=replace(SSOUT,'26','Кровотечение + другие заболевания');
    SSOUT:=replace(SSOUT,'27','Непроходимость кишечника + сердечно-сосудистая недостаточность');
    SSOUT:=replace(SSOUT,'28','Непроходимость кишечника + дыхательная недостаточность');
    SSOUT:=replace(SSOUT,'29','Непроходимость кишечника + сахарный диабет'); 
    SSOUT:=replace(SSOUT,'30','Перитонит + сердечно-сосудистая недостаточность');
    SSOUT:=replace(SSOUT,'31','Перитонит + дыхательная недостаточность');
    SSOUT:=replace(SSOUT,'32','Перетонит + другие паталогические состояния');
    SSOUT:=replace(SSOUT,'33','Стеноз выхода желудка + другие патологические состояния');
    SSOUT:=replace(SSOUT,'34','Инсульт без остаточных явлений');
    SSOUT:=replace(SSOUT,'35','Инсульт с остаточными явлениями');
    SSOUT:=replace(SSOUT,'36','Энцефалопатия');           
    SSOUT:=replace(SSOUT,'0','0');
    SSOUT:=replace(SSOUT,'1','ИБС');
    SSOUT:=replace(SSOUT,'2','Инфаркт миокарда');
    SSOUT:=replace(SSOUT,'3','Мерцательная аритмия');
    SSOUT:=replace(SSOUT,'4','Пароксизмальная тахикардия');
    SSOUT:=replace(SSOUT,'5','Атрио-вентрикулярная блокада');
    SSOUT:=replace(SSOUT,'6','Хроническая недостаточность кровообращения');
    SSOUT:=replace(SSOUT,'7','Бронх.астма (обструктивная болезнь легких)');
    SSOUT:=replace(SSOUT,'8','Хрон.дыхательная недостаточность');
    SSOUT:=replace(SSOUT,'9','Почечная недостаточность');
    return(SSOUT);
  end;  
  
--Анестезия, осложнения
  function GetCancerAnesthesiaComplic(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'10','ФЛЕБИТ ЦЕНТРАЛЬНЫХ ВЕН');
    SSOUT:=replace(SSOUT,'11','НАДПОЧЕЧНИКОВАЯ НЕДОСТАТОЧНОСТЬ');
    SSOUT:=replace(SSOUT,'12','ОСЛОЖНЕНИЯ РЕГИОНАРГОЙ АНЕСТИЗИИ');
    SSOUT:=replace(SSOUT,'13','ИШЕМИЯ МИОКАРДА');
    SSOUT:=replace(SSOUT,'14','АРИТМИЯ');
    SSOUT:=replace(SSOUT,'15','ДРУГИЕ');
    SSOUT:=replace(SSOUT,'21','БЕЗ ОСЛОЖНЕНИЙ');
    SSOUT:=replace(SSOUT,'1','ОСТАНОВКА КРОВООБРАЩЕНИЯ');
    SSOUT:=replace(SSOUT,'2','ДЛИТЕЛЬНОЕ АПНОЭ');
    SSOUT:=replace(SSOUT,'3','ОСТРАЯ СЕРДЕЧНАЯ НЕДОСТАТОЧНОСТЬ');
    SSOUT:=replace(SSOUT,'4','ОСТРАЯ СОСУДИСТАЯ НЕДОСТАТОЧНОСТЬ');
    SSOUT:=replace(SSOUT,'5','ГИПЕРТЕНЗИОННЫЙ СИНДРОМ');
    SSOUT:=replace(SSOUT,'6','ОСТРАЯ ДЫХАТЕЛЬНАЯ НЕДОСТАТОЧНОСТЬ');
    SSOUT:=replace(SSOUT,'7','ОСТРАЯ ПОЧЕЧНАЯ НЕДОСТАТОЧНОСТЬ');
    SSOUT:=replace(SSOUT,'8','ОСТРАЯ ПЕЧЕНОЧНАЯ НЕДОСТАТОЧНОСТЬ');
    SSOUT:=replace(SSOUT,'9','ЛАРИНГИТ');
    return(SSOUT);
  end;    
  
--Канцер-выписка, дешифровка вида лекарственной терапии  hospital.cancer_sum_drug_treat.drug_treatment_type
  function GetCancerDrugTreatType(SSIN IN VARCHAR2) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'ChemoTherapeutic','Химио');
    SSOUT:=replace(SSOUT,'HormoneImmuneTherapeutic','Гормоно');
    SSOUT:=replace(SSOUT,'Targeted','Таргет');
    SSOUT:=replace(SSOUT,'Accompanying','Сопровождающий');
    return(SSOUT);
  end;  

/*  
--Количество занятых коек в ночь на указанную дату в указанном отделении
--неправильн, не исп
  function GetCntBedBusy(DD IN DATE, DepID IN NUMBER) return NUMBER
  is
    RetN NUMBER;
  begin
    RetN:=0;
    for ii in (select  count(*) cnt from
 hospital.hospital_card_movement hcm   --смотрим стационарные перемещения
 join hospital.hospital_card hc on hc.id=hcm.hospital_card_id --стацкарта
 join hospital.client cl on hc.client_id=cl.id  --пациент
 join hospital.project p on p.id=hc.project_id  --случай
 join hospital.department d on d.id=hcm.department_id  --отделение в котором производится перемещение
 left join hospital.project_result pr on pr.id=p.project_result_id  
 left join hospital.project_result_type1 pr1 on pr1.id=p.project_result_type1_id
 left join hospital.project_result_type2 pr2 on pr2.id=p.project_result_type2_id
 join hospital.hospital_direction hd on hd.id=hc.hospital_direction_id  --направление на госпитализацию
 left join hospital.mkb mkb on mkb.id=hc.mkb_id                         --диагноз в стацкарте           
 left join hospital.diagnosis di on di.id=p.main_diagnosis_id           --диагноз окончательный в случае
 left join hospital.mkb mkbfi on mkbfi.id=di.mkb10_id        
 left join hospital.medical_profile mp on mp.id=hcm.medical_profile_id  --профиль койки 
where
 d.id=DepID
 --только нахождения в отделении до даты интересуют 
 and hcm.state in ('InDepartment')                       
 and trunc(hcm.create_date) < DD
 -- только последнее событие нахождения в стационаре до даты смотрим
 and not exists (select 1 from hospital.hospital_card_movement hcm2
                 where hcm2.hospital_card_id=hcm.hospital_card_id 
                       and hcm2.id>hcm.id --нет событий нахождения до в дату после рассматриваемого
                       and hcm2.state in ('InDepartment')  --только нахождения в стационаре смотрим
                       and trunc(hcm2.create_date) < DD)
 --только  открытые на дату стацкарты
 and trunc(hc.receive_date)<= DD 
 and ( (hc.outtake_date is null and hc.state not in ('Closed','Deleted','Refused')) or hc.outtake_date >= DD)
-- and d.department_type_id = -2 and d.parent_id not in (208,331) and d.id not in (123)
 -- и нет события выписки до даты по этой стацкарте после события нахождения InDepartment
 --(не будет если нет выписки в перемещениях не совпадающей с датой выписки в стацкарте)
 and not exists (select 1 from hospital.hospital_card_movement hcm3
                 where hcm3.hospital_card_id=hcm.hospital_card_id 
                       and hcm3.id>hcm.id  
                       and hcm3.state in ('Discharged')
                       and hcm3.create_date < DD)
)                       
  loop
    RetN:=ii.cnt; 
  end loop;                       
    return(RetN);
  end;
*/

/* 
--Количество проведенных операций в указанную дату в указанном отделении
--неправильн, не исп
  function GetCntBedSurgery(DD IN DATE, DepID IN NUMBER) return NUMBER  
  is
    RetN NUMBER;
  begin
    RetN:=0;
    for ii in (select  count(*) cnt from    
 hospital.hospital_card hc                      --стацкарта
 join hospital.hospital_card_movement hcm on hcm.hospital_card_id=hc.id   --смотрим стационарные перемещения
 join hospital.client cl on hc.client_id=cl.id  --пациент
 join hospital.project p on p.id=hc.project_id  --случай
 join hospital.surgery s on s.project_id=p.id   --операции
 join hospital.service_type st on st.id=s.service_type_id
 join hospital.service_category sc on sc.id=st.service_category_id --and sc.name like ('Опер%')
 join hospital.hospital_direction hd on hd.id=hc.hospital_direction_id  --направление на госпитализацию
 join hospital.department d on d.id=hcm.department_id   --отделение в котором производится операция
 left join hospital.project_result pr on pr.id=p.project_result_id  
 left join hospital.project_result_type1 pr1 on pr1.id=p.project_result_type1_id
 left join hospital.project_result_type2 pr2 on pr2.id=p.project_result_type2_id
 left join hospital.mkb mkb on mkb.id=hc.mkb_id                         --диагноз в стацкарте           
 left join hospital.diagnosis di on di.id=p.main_diagnosis_id           --диагноз окончательный в случае
 left join hospital.mkb mkbfi on mkbfi.id=di.mkb10_id        
where
 d.id=DepID
 --только нахождения в отделении до и в дату интересуют 
 and hcm.state in ('InDepartment')                       
 and trunc(hcm.create_date)<=DD
 -- только последнее событие нахождения в стационаре до даты смотрим
 and not exists (select 1 from hospital.hospital_card_movement hcm2
                 where hcm2.hospital_card_id=hcm.hospital_card_id 
                       and hcm2.id>hcm.id --нет событий нахождения до в дату после рассматриваемого
                       and hcm2.state in ('InDepartment')  --только нахождения в стационаре смотрим
                       and trunc(hcm2.create_date)<=DD)
 --только  открытые на дату стацкарты
 and trunc(hc.receive_date) <= DD 
 and ( (hc.outtake_date is null and hc.state not in ('Closed','Deleted','Refused')) or hc.outtake_date >= DD)
 --только отделения с койками и не тестовые
 -- and d.code<>0
-- and d.department_type_id = -2 and d.parent_id not in (208,331) and d.id not in (123)
 --только операции в дату 
 and trunc(s.start_date) = DD 
 --только выполненные операции
-- and s.state='Done'
 and s.execute_state='Done'      
    )                       
    loop
     RetN:=ii.cnt; 
    end loop;                       
     return(RetN);
  end;
*/
  
--Вернуть строкой палату и койку по стацкарте в указанную дату  
  function GetPatientRoomBed(DD IN DATE, HC_ID IN NUMBER) return VARCHAR2
  is    
    RetSt VARCHAR2(4000);
  begin
    RetSt:='';
    for ii in ( select prm.name room, to_char(prp.bed_number) bed, to_char(prp.appointment_date,'dd.mm.yy HH24:MI') d  
       from
        hospital.patient_room_patient prp   --занятие койки
        left join hospital.patient_room prm on prm.id=prp.patient_room_id           --палата      
       where 
         prp.hospital_card_id=HC_ID
        --ищем последнюю койку на которой лежал в дату
         and (trunc(prp.appointment_date)<=DD)
         and not exists (select 1 from hospital.patient_room_patient prp2
                         where (prp2.hospital_card_id=prp.hospital_card_id)
                                and trunc(prp2.appointment_date)<=DD 
--                                and prp2.appointment_date>prp.appointment_date
                                and prp2.id>prp.id)
    )                       
    loop
      RetSt:='палата '||ii.room||' койка '||ii.bed||' с '||ii.d; 
    end loop;                       
      return(RetSt); 
  end;
  
--Список стацкарт лежащих в отделении с учетом лежащих в Анестизиологии в указанную дату  по InDepartment определяем
--в ночь на указанную дату без учета переводов могущих быть невыполненными в дату
  function GetListBedBusy95(DD IN DATE, DepID IN NUMBER) return tblID  
  pipelined  
  is
  begin 
    --по логике. сколько числилось в отделении в ночь на указанную дату.
    --игнорим отправленых из и в отделение но не принятых.
    for curr in
    (  
      select hc.id hospital_card_id, hcm.id hospital_card_movement_id
      from hospital.hospital_card hc join hospital.hospital_card_movement hcm on hcm.hospital_card_id=hc.id
      where 
            --только  открытые на дату стацкарты
            trunc(hc.receive_date)<=DD and ( (hc.outtake_date is null and hc.state not in ('Closed','Deleted','Refused')) or hc.outtake_date>=DD)
            --только нахождения в отделении до даты интересуют 
            and hcm.state in ('InDepartment')                       
            and trunc(hcm.create_date)<DD
            --только в указанном отделении
            and hcm.department_id=DepID
---
--            and hcm.department_id<>95    --игнорим Анестизиологию 13.11.2017
            --отбираем только последнее событие нахождения в стационаре до даты 
            and not exists (select 1 from hospital.hospital_card_movement hcm2
                            where hcm2.hospital_card_id=hcm.hospital_card_id 
                                  and hcm2.id>hcm.id 
                                  and hcm2.state in ('InDepartment')  --только нахождения в стационаре смотрим
---
--                                  and hcm2.department_id<>95    --игнорим Анестизиологию 13.11.2017
                                  and trunc(hcm2.create_date)<DD)
            -- и нет события выписки до даты по этой стацкарте после события нахождения InDepartment
            --(не будет если нет выписки в перемещениях не совпадающей с датой выписки в стацкарте, т.к. в hc уже отфильтровали)
            and not exists (select 1 from hospital.hospital_card_movement hcm3
                            where hcm3.hospital_card_id=hcm.hospital_card_id 
                                  and hcm3.id>hcm.id  
                                  and hcm3.state in ('Discharged')
                                  and hcm3.create_date<DD)                                  


    ) loop
    pipe row (curr);
    end loop;  
  end;  
  
--Список стацкарт лежащих в указанном отделении в указанную дату  по InDepartment определяем
--в ночь на указанную дату без учета переводов могущих быть невыполненными в дату
  function GetListBedBusy(DD IN DATE, DepID IN NUMBER) return tblID  
  pipelined  
  is
  begin 
    --по логике. сколько числилось в отделении в ночь на указанную дату.
    --игнорим отправленых из и в отделение но не принятых.
    for curr in
    (  
      select hc.id hospital_card_id, hcm.id hospital_card_movement_id
      from hospital.hospital_card hc join hospital.hospital_card_movement hcm on hcm.hospital_card_id=hc.id
      where 
            --только  открытые на дату стацкарты
            trunc(hc.receive_date)<=DD and ( (hc.outtake_date is null and hc.state not in ('Closed','Deleted','Refused')) or hc.outtake_date>=DD)
            --только нахождения в отделении до даты интересуют 
            and hcm.state in ('InDepartment')                       
            and trunc(hcm.create_date)<DD
            --только в указанном отделении
            and hcm.department_id=DepID
---
            and hcm.department_id<>95    --игнорим Анестизиологию 13.11.2017
            --отбираем только последнее событие нахождения в стационаре до даты 
            and not exists (select 1 from hospital.hospital_card_movement hcm2
                            where hcm2.hospital_card_id=hcm.hospital_card_id 
                                  and hcm2.id>hcm.id 
                                  and hcm2.state in ('InDepartment')  --только нахождения в стационаре смотрим
---
                                  and hcm2.department_id<>95    --игнорим Анестизиологию 13.11.2017
                                  and trunc(hcm2.create_date)<DD)
            -- и нет события выписки до даты по этой стацкарте после события нахождения InDepartment
            --(не будет если нет выписки в перемещениях не совпадающей с датой выписки в стацкарте, т.к. в hc уже отфильтровали)
            and not exists (select 1 from hospital.hospital_card_movement hcm3
                            where hcm3.hospital_card_id=hcm.hospital_card_id 
                                  and hcm3.id>hcm.id  
                                  and hcm3.state in ('Discharged')
                                  and hcm3.create_date<DD)                                  


    ) loop
    pipe row (curr);
    end loop;  
  end;
  
--Список стацкарт лежащих в указанном отделении в указанный период
--суммируем стацкарты лежащие в ночь в даты указанного периода
  function GetListBedBusyPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin
    for curr in
    ( 
     select hcm.hospital_card_id hospital_card_id, hcm.id hospital_card_movement_id
      from
        (SELECT (beg_date + LEVEL - 1) d, depid FROM (SELECT DTF beg_date, DTT end_date   FROM  dual) CONNECT BY LEVEL <= end_date - beg_date + 1) dd, 
        hospital.hospital_card hc 
        join hospital.hospital_card_movement hcm on hcm.hospital_card_id=hc.id
      where 
            --только  открытые на дату стацкарты
            trunc(hc.receive_date)<=DD.d and ( (hc.outtake_date is null and hc.state not in ('Closed','Deleted','Refused')) or hc.outtake_date>=DD.d)
            --только нахождения в отделении до даты интересуют 
            and hcm.state in ('InDepartment')                       
            and trunc(hcm.create_date)<DD.d
            --только в указанном отделении
            and hcm.department_id=DepID
---
            and hcm.department_id<>95    --игнорим Анестизиологию 13.11.2017
            --отбираем только последнее событие нахождения в стационаре до даты 
            and not exists (select 1 from hospital.hospital_card_movement hcm2
                            where hcm2.hospital_card_id=hcm.hospital_card_id 
                                  and hcm2.id>hcm.id 
                                  and hcm2.state in ('InDepartment')  --только нахождения в стационаре смотрим
---
                                  and hcm2.department_id<>95    --игнорим Анестизиологию 13.11.2017
                                  and trunc(hcm2.create_date)<DD.d)
            -- и нет события выписки до даты по этой стацкарте после события нахождения InDepartment
            --(не будет если нет выписки в перемещениях не совпадающей с датой выписки в стацкарте, т.к. в hc уже отфильтровали)
            and not exists (select 1 from hospital.hospital_card_movement hcm3
                            where hcm3.hospital_card_id=hcm.hospital_card_id 
                                  and hcm3.id>hcm.id  
                                  and hcm3.state in ('Discharged')
                                  and hcm3.create_date<DD.d)             
    ) loop
    pipe row (curr);
    end loop;  
  end;  
  
/*  
--медленный ранний вариант, до 26 06 2018  
  function GetListBedBusyPeriodOld(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin
    for curr in
    ( 
     select x.hospital_card_id hospital_card_id, x.hospital_card_movement_id hospital_card_movement_id
     from
     (SELECT (beg_date + LEVEL - 1) d FROM (SELECT DTF beg_date, DTT end_date   FROM   dual) CONNECT BY LEVEL <= end_date - beg_date + 1) dd, 
      table(GetListBedBusy(dd.d,DepID)) x           
    ) loop
    pipe row (curr);
    end loop;  
  end;    
*/
  
--Список стацкарт лежащих в указанном отделении с учетом Анестизиологии в указанный период
--суммируем стацкарты лежащие в ночь в даты указанного периода
  function GetListBedBusyPeriod95(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin
    for curr in
    ( 
     select x.hospital_card_id hospital_card_id, x.hospital_card_movement_id hospital_card_movement_id
     from
     (SELECT (beg_date + LEVEL - 1) d FROM (SELECT DTF beg_date, DTT end_date   FROM   dual) CONNECT BY LEVEL <= end_date - beg_date + 1) dd, 
      table(GetListBedBusy95(dd.d,DepID)) x           
    ) loop
    pipe row (curr);
    end loop;  
  end;   
/*  
--Список стацкарт лежащих в указанном отделении в указанную дату с учетом переводов в указанную дату c учетом SentTo
  function GetListBedBusy2(DD IN DATE, DepID IN NUMBER) return tblID  
  pipelined  
  is
  begin 
    --учитываем отправленых из и в отделение.
    for curr in
    (  
      select hc.id hospital_card_id, hcm.id hospital_card_movement_id
      from hospital.hospital_card hc join hospital.hospital_card_movement hcm on hcm.hospital_card_id=hc.id
      where 
            --только  открытые на дату стацкарты
            trunc(hc.receive_date)<=DD and ( (hc.outtake_date is null and hc.state not in ('Closed','Deleted','Refused')) or hc.outtake_date>=DD)
            --только самое последнее событие перемещения по стацкарте до и в дату интересуют 
            and trunc(hcm.create_date)<=dd 
            -- только последнее событие отбираем
            and not exists (select 1 from hospital.hospital_card_movement hcm2
                            where hcm2.hospital_card_id=hcm.hospital_card_id 
                                  and hcm2.id>hcm.id --нет событий нахождения после рассматриваемого до и в дату
                                  and trunc(hcm2.create_date)<=dd)
            --отбираем нужные для получиния списка - кто сейчас лежит в стационаре
            and ( 
                --находится в отделении до и на дату
                (hcm.state='InDepartment' and hcm.department_id=depid  )
                or (
                --добавляем отправленых в это отделение в дату
                trunc(hcm.create_date)=dd and hcm.state='SentToDepartment' and hcm.target_department_id=depid    
                   )                
                )                   
            and not( 
                trunc(hcm.create_date)=dd and hcm.department_id=depid and 
                (
                --выкидываем выписанных из отделения в дату
                hcm.state='Discharged'
                  or 
                --выкидываем отправленых из отделения в дату
                hcm.state='SentToDepartment'
                 )
                )
    ) loop
    pipe row (curr);
    end loop;  
  end;  
*/  
--Список стацкарт поступивших в указанное отделение в указанную дату (принятых в стационар) по InDepartment
  function GetListBedRecieved(DD IN DATE, DepID IN NUMBER) return tblID 
  pipelined
 is
  begin 
    for curr in
    (  
      select hcm.hospital_card_id, hcm.id hospital_card_movement_id
            from hospital.hospital_card_movement hcm
            where hcm.state='InDepartment' 
                  and hcm.department_id=DepID
                  and trunc(hcm.create_date)=DD            
                  and not exists( --вернется, только если это самое первое событие InDepartment по стацкарте
                                  select 1 from hospital.hospital_card_movement hcmx 
                                  where hcmx.hospital_card_id=hcm.hospital_card_id 
                                        and hcmx.state='InDepartment' and hcmx.id<hcm.id 
                                ) 
                  and not exists (select 1 from hospital.hospital_card hcr  --если стацкарта недействительна и даты выписки нет - эти перемещения не интересуют
                                 where hcr.id=hcm.hospital_card_id and
                                       (hcr.outtake_date is null and hcr.state in ('Closed','Deleted','Refused')) )
                                   
                                
    ) loop
    pipe row (curr);
    end loop;  
  end;  

--Список стацкарт поступивших в указанное отделение в указанный период (поступивших в стационар)
  function GetListBedRecievedPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin
    for curr in
    (  
      select hcm.hospital_card_id, hcm.id hospital_card_movement_id
            from hospital.hospital_card_movement hcm
            where hcm.state='InDepartment' 
                  and hcm.department_id=DepID
                  and trunc(hcm.create_date) between DTF and DTT            
                  and not exists( --вернется, только если это самое первое событие InDepartment по стацкарте
                                  select 1 from hospital.hospital_card_movement hcmx 
                                  where hcmx.hospital_card_id=hcm.hospital_card_id 
                                        and hcmx.state='InDepartment' and hcmx.id<hcm.id 
                                ) 
                  and not exists (select 1 from hospital.hospital_card hcr  --если стацкарта недействительна и даты выписки нет - эти перемещения не интересуют
                                 where hcr.id=hcm.hospital_card_id and
                                       (hcr.outtake_date is null and hcr.state in ('Closed','Deleted','Refused')) )
                                   
                                
    ) loop
    pipe row (curr);
    end loop;   
  end;  

/*  
--Список стацкарт поступивших в указанное отделение в указанный период (поступивших в стационар)
--медленное, до 300718
  function GetListBedRecievedPeriodOld(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin
    for curr in
    ( 
     select x.hospital_card_id hospital_card_id, x.hospital_card_movement_id hospital_card_movement_id
     from
     (SELECT (beg_date + LEVEL - 1) d FROM (SELECT DTF beg_date, DTT end_date   FROM   dual) CONNECT BY LEVEL <= end_date - beg_date + 1) dd, 
      table(GetListBedRecieved(dd.d,DepID)) x           
    ) loop
    pipe row (curr);
    end loop;  
  end;    
*/

--Список стацкарт поступивших в указанное отделение в указанную дату по InDepartment
--без учета первичного поступления, т.е. только переведенные внутри
--через определение изменения нахождения InDepartment (игнорим SentTo...)
  function GetListBedIn(DD IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin 
    for curr in
    (  
    select hcm.hospital_card_id hospital_card_id, hcm.id hospital_card_movement_id
      from hospital.hospital_card_movement hcmp, hospital.hospital_card_movement hcm, hospital.hospital_card hc
      where trunc(hcm.create_date)=DD and hcm.department_id=DepID
            and hc.id=hcm.hospital_card_id 
            and hcm.state in ('InDepartment','Discharged')
            and hcmp.id in (select hcmx.id from hospital.hospital_card_movement hcmx --находим предудущее событие нахождения в отделении
                            where hcmx.hospital_card_id=hcm.hospital_card_id and 
                                  hcmx.state in ('InDepartment','Discharged') and 
---
                                  hcmx.department_id<>95 and   --игнорим перемещения в Анестизиологию  13.11.17
                                  (trunc(hcmx.create_date)<=trunc(hc.outtake_date) or hc.outtake_date is null) and   --перемещения после даты выписки отбрасываем
                                  hcmx.id<hcm.id and
                                  not exists (select 1 from hospital.hospital_card_movement hcmz
                                       where hcmz.hospital_card_id=hcm.hospital_card_id and
                                             hcmz.state in ('InDepartment','Discharged') and
---
                                             hcmz.department_id<>95 and   --игнорим перемещения в Анестизиологию  13.11.17
                                             (trunc(hcmz.create_date)<=trunc(hc.outtake_date) or hc.outtake_date is null) and   --перемещения после даты выписки отбрасываем
                                             hcmz.id<hcm.id and
                                             hcmz.id>hcmx.id 
                                             )
                             )
            and hcm.department_id<>hcmp.department_id --только смена отделения предыдущего события и текущего
---
            and hcm.department_id<>95   --игнорим перемещения в Анестизиологию  13.11.17
---
            and hcmp.department_id<>95   --игнорим перемещения в Анестизиологию  13.11.17
            and not exists (select 1 from hospital.hospital_card_movement hcmr  --если выписан раньше чем были перемещения - эти перемещения нас не интересуют
                            where hcmr.hospital_card_id=hcm.hospital_card_id and
                                  hcmr.state in ('Discharged') and
                                  hcmr.create_date<hcm.create_date)  
            and not exists (select 1 from hospital.hospital_card hcr  --если в стацкарте дата выписки стоит ранее рассматриваемой даты в случае отсутствия Discharged - эти перемещения не интересуют
                            where hcr.id=hcm.hospital_card_id and
                                  trunc(hcr.outtake_date)<trunc(DD))        
            and not exists (select 1 from hospital.hospital_card hcr  --если стацкарта недействительна и даты выписки нет - эти перемещения не интересуют
                            where hcr.id=hcm.hospital_card_id and
                                  hcr.outtake_date is null and hcr.state in ('Closed','Deleted','Refused'))                                                               
    ) loop
    pipe row (curr);
    end loop;  
  end;  
  
--Список стацкарт отправленых в указанное отделение в период
--оптимизировал, ускорено с 10 08 2018
  function GetListBedInPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin
    for curr in
    ( 
     select hcm.hospital_card_id hospital_card_id, hcm.id hospital_card_movement_id
      from (SELECT (beg_date + LEVEL - 1) d FROM (SELECT DTF beg_date, DTT end_date   FROM   dual) CONNECT BY LEVEL <= end_date - beg_date + 1) dd, 
           hospital.hospital_card_movement hcmp, hospital.hospital_card_movement hcm, hospital.hospital_card hc
      where trunc(hcm.create_date)=dd.d and hcm.department_id=DepID
            and hc.id=hcm.hospital_card_id 
            and hcm.state in ('InDepartment','Discharged')
            and hcmp.id in (select hcmx.id from hospital.hospital_card_movement hcmx --находим предудущее событие нахождения в отделении
                            where hcmx.hospital_card_id=hcm.hospital_card_id and 
                                  hcmx.state in ('InDepartment','Discharged') and 
---
                                  hcmx.department_id<>95 and   --игнорим перемещения в Анестизиологию  13.11.17
                                  (trunc(hcmx.create_date)<=trunc(hc.outtake_date) or hc.outtake_date is null) and   --перемещения после даты выписки отбрасываем
                                  hcmx.id<hcm.id and
                                  not exists (select 1 from hospital.hospital_card_movement hcmz
                                       where hcmz.hospital_card_id=hcm.hospital_card_id and
                                             hcmz.state in ('InDepartment','Discharged') and
---
                                             hcmz.department_id<>95 and   --игнорим перемещения в Анестизиологию  13.11.17
                                             (trunc(hcmz.create_date)<=trunc(hc.outtake_date) or hc.outtake_date is null) and   --перемещения после даты выписки отбрасываем
                                             hcmz.id<hcm.id and
                                             hcmz.id>hcmx.id 
                                             )
                             )
            and hcm.department_id<>hcmp.department_id --только смена отделения предыдущего события и текущего
---
            and hcm.department_id<>95   --игнорим перемещения в Анестизиологию  13.11.17
---
            and hcmp.department_id<>95   --игнорим перемещения в Анестизиологию  13.11.17
            and not exists (select 1 from hospital.hospital_card_movement hcmr  --если выписан раньше чем были перемещения - эти перемещения нас не интересуют
                            where hcmr.hospital_card_id=hcm.hospital_card_id and
                                  hcmr.state in ('Discharged') and
                                  hcmr.create_date<hcm.create_date)  
            and not exists (select 1 from hospital.hospital_card hcr  --если в стацкарте дата выписки стоит ранее рассматриваемой даты в случае отсутствия Discharged - эти перемещения не интересуют
                            where hcr.id=hcm.hospital_card_id and
                                  trunc(hcr.outtake_date)<trunc(dd.d))        
            and not exists (select 1 from hospital.hospital_card hcr  --если стацкарта недействительна и даты выписки нет - эти перемещения не интересуют
                            where hcr.id=hcm.hospital_card_id and
                                  hcr.outtake_date is null and hcr.state in ('Closed','Deleted','Refused'))                      
    ) loop
    pipe row (curr);
    end loop;  
  end;  

/*  
--Список стацкарт отправленых в указанное отделение в период
--медленный, до 10 08 2018
  function GetListBedInPeriodOld(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin
    for curr in
    ( 
     select x.hospital_card_id hospital_card_id, x.hospital_card_movement_id hospital_card_movement_id
     from
     (SELECT (beg_date + LEVEL - 1) d FROM (SELECT DTF beg_date, DTT end_date   FROM   dual) CONNECT BY LEVEL <= end_date - beg_date + 1) dd, 
      table(GetListBedIn(dd.d,DepID)) x           
    ) loop
    pipe row (curr);
    end loop;  
  end;    
*/
  
/*  
--Список стацкарт поступивших в указанное отделение в указанную дату по SentToDepartment
--без учета первичного поступления, т.е. только переведенные внутри
--первое поступление в - это прием в стационар.
--не исп.
  function GetListBedIn2(DD IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin 
    for curr in
    (  
    select hc.id hospital_card_id, hcm.id hospital_card_movement_id
           from hospital.hospital_card_movement hcm 
                join hospital.hospital_card hc on hc.id=hcm.hospital_card_id
           where hcm.state='SentToDepartment'
                 and hcm.target_department_id=DepID
                 and trunc(hcm.create_date)=DD 
                 and hcm.department_id<>hcm.target_department_id --игнорим переводы внутри отделения
                 and exists( --вернется, только если это не самое первое событие SentToDepartment по стацкарте
                                  select 1 from hospital.hospital_card_movement hcmx 
                                  where hcmx.hospital_card_id=hcm.hospital_card_id 
                                        and hcmx.state='SentToDepartment' and hcmx.id<hcm.id 
                           )        

/*                 and not exists( --вернется, только если это самое последнее событие SentToDepartment по стацкарте в этот день
                                  select 1 from hospital.hospital_card_movement hcmx 
                                  where hcmx.hospital_card_id=hcm.hospital_card_id 
                                        and hcmx.state='SentToDepartment'
                                        and trunc(hcmx.create_date)=DD
                                        and hcmx.id>hcm.id 
                                )        
                           
*/                 
/*    ) loop
    pipe row (curr);
    end loop;  
  end;  
*/  
--Список стацкарт отправленых из указанного отделения в указанную дату 
--без учета первичного поступления, т.е. только переведенные внутри
--через определение изменения нахождения InDepartment (игнорим SentTo...)
  function GetListBedOut(DD IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin 
    for curr in
    (  
    select hcm.hospital_card_id hospital_card_id, hcm.id hospital_card_movement_id
      from hospital.hospital_card_movement hcmp, hospital.hospital_card_movement hcm, hospital.hospital_card hc
      where trunc(hcm.create_date)=DD and hcmp.department_id=DepID
            and hc.id=hcm.hospital_card_id 
            and hcm.state in ('InDepartment','Discharged')
            and hcmp.id in (select hcmx.id from hospital.hospital_card_movement hcmx --находим предыдущее событие нахождения
                            where hcmx.hospital_card_id=hcm.hospital_card_id and 
                                  hcmx.state in ('InDepartment','Discharged') and 
---
                                  hcmx.department_id<>95 and  --игнорим перемещения из Анестизиологии  13.11.2017
                                  (trunc(hcmx.create_date)<=trunc(hc.outtake_date) or hc.outtake_date is null) and   --перемещения после даты выписки отбрасываем
                                  hcmx.id<hcm.id and
                                  not exists (select 1 from hospital.hospital_card_movement hcmz
                                       where hcmz.hospital_card_id=hcm.hospital_card_id and
                                             hcmz.state in ('InDepartment','Discharged') and
---
                                             hcmz.department_id<>95 and  --игнорим перемещения из Анестизиологии  13.11.2017
                                             (trunc(hcmz.create_date)<=trunc(hc.outtake_date) or hc.outtake_date is null) and   --перемещения после даты выписки отбрасываем
                                             hcmz.id<hcm.id and
                                             hcmz.id>hcmx.id 
                                             )
                             )
            and hcm.department_id<>hcmp.department_id --только изменения отделения интересуют между предыдущим и текущим
---
            and hcmp.department_id<>95  --игнорим перемещения из Анестизиологии  13.11.2017
---
            and hcm.department_id<>95  --игнорим перемещения из Анестизиологии  13.11.2017
            and not exists (select 1 from hospital.hospital_card_movement hcmr  --если выписан раньше чем были перемещения - эти перемещения нас не интересуют
                            where hcmr.hospital_card_id=hcm.hospital_card_id and
                                  hcmr.state in ('Discharged') and
                                  hcmr.create_date<hcm.create_date)
            and not exists (select 1 from hospital.hospital_card hcr  --если в стацкарте дата выписки стоит ранее рассматриваемой даты в случае отсутствия Discharged - эти перемещения не интересуют
                            where hcr.id=hcm.hospital_card_id and
                                  trunc(hcr.outtake_date)<trunc(DD))   
            and not exists (select 1 from hospital.hospital_card hcr  --если стацкарта недействительна и даты выписки нет - эти перемещения не интересуют
                            where hcr.id=hcm.hospital_card_id and
                                  hcr.outtake_date is null and hcr.state in ('Closed','Deleted','Refused'))                                                                      
    ) loop
    pipe row (curr);
    end loop;  
  end; 
  
--Список стацкарт отправленых из указанного отделения в период
--оптимизировано, ускорено с 10 08 2018
  function GetListBedOutPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin
    for curr in
    ( 
     select hcm.hospital_card_id hospital_card_id, hcm.id hospital_card_movement_id
      from
      (SELECT (beg_date + LEVEL - 1) d FROM (SELECT DTF beg_date, DTT end_date   FROM   dual) CONNECT BY LEVEL <= end_date - beg_date + 1) dd,  
      hospital.hospital_card_movement hcmp, hospital.hospital_card_movement hcm, hospital.hospital_card hc
      where trunc(hcm.create_date)=dd.d and hcmp.department_id=DepID
            and hc.id=hcm.hospital_card_id 
            and hcm.state in ('InDepartment','Discharged')
            and hcmp.id in (select hcmx.id from hospital.hospital_card_movement hcmx --находим предыдущее событие нахождения
                            where hcmx.hospital_card_id=hcm.hospital_card_id and 
                                  hcmx.state in ('InDepartment','Discharged') and 
---
                                  hcmx.department_id<>95 and  --игнорим перемещения из Анестизиологии  13.11.2017
                                  (trunc(hcmx.create_date)<=trunc(hc.outtake_date) or hc.outtake_date is null) and   --перемещения после даты выписки отбрасываем
                                  hcmx.id<hcm.id and
                                  not exists (select 1 from hospital.hospital_card_movement hcmz
                                       where hcmz.hospital_card_id=hcm.hospital_card_id and
                                             hcmz.state in ('InDepartment','Discharged') and
---
                                             hcmz.department_id<>95 and  --игнорим перемещения из Анестизиологии  13.11.2017
                                             (trunc(hcmz.create_date)<=trunc(hc.outtake_date) or hc.outtake_date is null) and   --перемещения после даты выписки отбрасываем
                                             hcmz.id<hcm.id and
                                             hcmz.id>hcmx.id 
                                             )
                             )
            and hcm.department_id<>hcmp.department_id --только изменения отделения интересуют между предыдущим и текущим
---
            and hcmp.department_id<>95  --игнорим перемещения из Анестизиологии  13.11.2017
---
            and hcm.department_id<>95  --игнорим перемещения из Анестизиологии  13.11.2017
            and not exists (select 1 from hospital.hospital_card_movement hcmr  --если выписан раньше чем были перемещения - эти перемещения нас не интересуют
                            where hcmr.hospital_card_id=hcm.hospital_card_id and
                                  hcmr.state in ('Discharged') and
                                  hcmr.create_date<hcm.create_date)
            and not exists (select 1 from hospital.hospital_card hcr  --если в стацкарте дата выписки стоит ранее рассматриваемой даты в случае отсутствия Discharged - эти перемещения не интересуют
                            where hcr.id=hcm.hospital_card_id and
                                  trunc(hcr.outtake_date)<trunc(dd.d))   
            and not exists (select 1 from hospital.hospital_card hcr  --если стацкарта недействительна и даты выписки нет - эти перемещения не интересуют
                            where hcr.id=hcm.hospital_card_id and
                                  hcr.outtake_date is null and hcr.state in ('Closed','Deleted','Refused'))  
     
    ) loop
    pipe row (curr);
    end loop;  
  end;   

/*  
--Список стацкарт отправленых из указанного отделения в период
--медленный, до 10 08 2018, не исп
  function GetListBedOutPeriodOld(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin
    for curr in
    ( 
     select x.hospital_card_id hospital_card_id, x.hospital_card_movement_id hospital_card_movement_id
     from
     (SELECT (beg_date + LEVEL - 1) d FROM (SELECT DTF beg_date, DTT end_date   FROM   dual) CONNECT BY LEVEL <= end_date - beg_date + 1) dd, 
      table(GetListBedOut(dd.d,DepID)) x           
    ) loop
    pipe row (curr);
    end loop;  
  end;      
*/

/*  
--Список стацкарт отправленых из указанного отделения в указанную дату по SentToDepartment
--не исп
  function GetListBedOut2(DD IN DATE, DepID IN NUMBER) return tblID 
  pipelined
  is
  begin 
    for curr in
    (  
    select hc.id hospital_card_id, hcm.id hospital_card_movement_id
           from hospital.hospital_card_movement hcm 
                join hospital.hospital_card hc on hc.id=hcm.hospital_card_id
           where hcm.state='SentToDepartment'
                 and hcm.department_id=DepID
                 and trunc(hcm.create_date)=DD 
                 and hcm.department_id<>hcm.target_department_id --игнорим внутри отделения, не будет сходится с аналитом
/*                 and not exists( --вернется, только если это самое последнее событие SentToDepartment по стацкарте в этот день
                                  select 1 from hospital.hospital_card_movement hcmx 
                                  where hcmx.hospital_card_id=hcm.hospital_card_id 
                                        and hcmx.state='SentToDepartment'
                                        and trunc(hcmx.create_date)=DD
                                        and hcmx.id>hcm.id 
                                )                     
*/                                
/*    ) loop
    pipe row (curr);
    end loop;  
  end; 
*/
  
--Список стацкарт выписанных из указанного отделения в указанную дату
  function GetListBedDischarged(DD IN DATE, DepID IN NUMBER) return tblID 
  pipelined
  is
  begin 
    for curr in
    (  
    select hc.id hospital_card_id, hcm.id hospital_card_movement_id
           from hospital.hospital_card_movement hcm 
                join hospital.hospital_card hc on hc.id=hcm.hospital_card_id
           where hcm.state='Discharged'
                 and hcm.department_id=DepID
                 and trunc(hcm.create_date)=DD 
    ) loop
    pipe row (curr);
    end loop;  
  end; 
  
--Список стацкарт выписанных из указанного отделения в указанный период
  function GetListBedDischargedPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID 
  pipelined  
  is
  begin
    for curr in
    ( 
/*     select x.hospital_card_id hospital_card_id, x.hospital_card_movement_id hospital_card_movement_id
     from
     (SELECT (beg_date + LEVEL - 1) d FROM (SELECT DTF beg_date, DTT end_date   FROM   dual) CONNECT BY LEVEL <= end_date - beg_date + 1) dd, 
      table(GetListBedDischarged(dd.d,DepID)) x          
*/
    select hc.id hospital_card_id, hcm.id hospital_card_movement_id
           from hospital.hospital_card_movement hcm 
                join hospital.hospital_card hc on hc.id=hcm.hospital_card_id
           where hcm.state='Discharged'
                 and hcm.department_id=DepID
                 and trunc(hcm.create_date)>=DTF 
                 and trunc(hcm.create_date)<=DTT         
    ) loop
    pipe row (curr);
    end loop;  
  end;    
  
  
--Список стацкарт с операциями у выписанных в указанную дату относящихся к указанному отделению  
  function GetListSurgery(DD IN DATE, DepID IN NUMBER) return tblSurgeryID  
  pipelined
  is
  begin 
    for curr in
    (     
      select hc.id hospital_card_id, p.id project_id, s.id surgery_id
                                   from   hospital.hospital_card hc                                                              --стацкарта
                                          join hospital.project p on p.id=hc.project_id                                          --случай
                                          join hospital.surgery s on s.project_id=p.id                                           --операции
                                          join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id
                                                from hospital.hospital_card_movement hcmr
                                                where hcmr.state='Discharged'  --получаем дату и отделение выписки в момент выписки
                                                      and not exists( select 1 from hospital.hospital_card_movement hcmx
                                                                      where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='Discharged' and hcmx.id>hcmr.id )
                                                ) hcmout on hcmout.hospital_card_id=hc.id      
                                          left join hospital.surgery_worker sw on sw.surgery_id=s.id and sw.surgery_worker_role_id=1  --оперерирующий хирург
                                          left join hospital.worker sww on sww.id=sw.worker_id 
                                          left join hospital.staff stww on stww.id=sww.staff_id            --отделение оперерующего хирурга
                                     where
                                          --только операции относящиеся к данному отделению
                                          --если отделение выписки из отображаемых но не оперирующее - относим к отделению хирурга
                                          --если отделение хирурга оперирующее относим к отделению выписки
                                          --если отделение хирурга из неотображаемых - относим к отделению выписки
                                          nvl(decode(
                                              decode(hcmout.department_id,
                                                      97,stww.department_id, 
                                                      139,stww.department_id,
                                                      140,stww.department_id,
                                                      77,stww.department_id,
                                                      145,stww.department_id,
                                                      146,stww.department_id,   
                                                      decode(stww.department_id, 
                                                          138, hcmout.department_id,
                                                          142, hcmout.department_id, 
                                                          143, hcmout.department_id,
                                                          122, hcmout.department_id
                                                       )),
                                               97,97,
                                               139,139,
                                               140,140,
                                               77,77,
                                               145,145,
                                               146,146,
                                               138,138,
                                               142,142,
                                               143,143,
                                               122,122,
                                               hcmout.department_id) ,hcmout.department_id        
                                                     )=DepID
                                          and trunc(hcmout.create_date)=DD      --считаем только первые операции по стацкарте выполненные именно в этот день
                                          and s.execute_state='Done'      --только выполненные считаем
                                          --только первая операция интересует
                                          and not exists (select 1 from hospital.surgery sx 
                                                          where sx.project_id=p.id and sx.execute_state='Done' and sx.id<s.id)
                                          --только первый хирург интересует
                                          and not exists (select 1 from hospital.surgery_worker swx
                                                          where swx.surgery_id=s.id and swx.surgery_worker_role_id=1 and swx.id<sw.id) 
    ) loop
    pipe row (curr);
    end loop;  
  end; 

--Список стацкарт с операциями у выписанных в указанный период относящихся к указанному отделению  
  function GetListSurgeryPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblSurgeryID 
  pipelined  
  is
  begin
    for curr in
    ( 
      select hc.id hospital_card_id, p.id project_id, s.id surgery_id
                                   from   hospital.hospital_card hc                                                              --стацкарта
                                          join hospital.project p on p.id=hc.project_id                                          --случай
                                          join hospital.surgery s on s.project_id=p.id                                           --операции
                                          join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id
                                                from hospital.hospital_card_movement hcmr
                                                where hcmr.state='Discharged'  --получаем дату и отделение выписки в момент выписки
                                                      and not exists( select 1 from hospital.hospital_card_movement hcmx
                                                                      where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='Discharged' and hcmx.id>hcmr.id )
                                                ) hcmout on hcmout.hospital_card_id=hc.id      
                                          left join hospital.surgery_worker sw on sw.surgery_id=s.id and sw.surgery_worker_role_id=1  --оперерирующий хирург
                                          left join hospital.worker sww on sww.id=sw.worker_id 
                                          left join hospital.staff stww on stww.id=sww.staff_id            --отделение оперерующего хирурга
                                     where
                                          --только операции относящиеся к данному отделению
                                          --если отделение выписки из отображаемых но не оперирующее - относим к отделению хирурга
                                          --если отделение хирурга оперирующее относим к отделению выписки
                                          --если отделение хирурга из неотображаемых - относим к отделению выписки
                                          nvl(decode(
                                              decode(hcmout.department_id,
                                                      97,stww.department_id, 
                                                      139,stww.department_id,
                                                      140,stww.department_id,
                                                      77,stww.department_id,
                                                      145,stww.department_id,
                                                      146,stww.department_id,   
                                                      decode(stww.department_id, 
                                                          138, hcmout.department_id,
                                                          142, hcmout.department_id, 
                                                          143, hcmout.department_id,
                                                          122, hcmout.department_id
                                                       )),
                                               97,97,
                                               139,139,
                                               140,140,
                                               77,77,
                                               145,145,
                                               146,146,
                                               138,138,
                                               142,142,
                                               143,143,
                                               122,122,
                                               hcmout.department_id) ,hcmout.department_id        
                                                     )=DepID
                                          and trunc(hcmout.create_date) between DTF and DTT      --по выписанным (освободившим койки) в указанный период
                                          and s.execute_state='Done'      --только выполненные считаем
                                          --только первая операция интересует
                                          and not exists (select 1 from hospital.surgery sx 
                                                          where sx.project_id=p.id and sx.execute_state='Done' and sx.id<s.id)
                                          --только первый хирург интересует
                                          and not exists (select 1 from hospital.surgery_worker swx
                                                          where swx.surgery_id=s.id and swx.surgery_worker_role_id=1 and swx.id<sw.id)          
    ) loop
    pipe row (curr);
    end loop;  
  end;     

/*  
--Список стацкарт с операциями у выписанных в указанный период относящихся к указанному отделению  
--медленный, до 04 07 2018
  function GetListSurgeryPeriodOld(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblSurgeryID 
  pipelined  
  is
  begin
    for curr in
    ( 
     select x.hospital_card_id, x.project_id, x.surgery_id
     from
     (SELECT (beg_date + LEVEL - 1) d FROM (SELECT DTF beg_date, DTT end_date   FROM   dual) CONNECT BY LEVEL <= end_date - beg_date + 1) dd, 
      table(GetListSurgery(dd.d,DepID)) x           
    ) loop
    pipe row (curr);
    end loop;  
  end;   
*/    
  
--Вернуть краткое имя отделения стационара для отчетов
  function GetShortDepname(DepID IN NUMBER) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:='';
    for ii in (select d.name from hospital.department d where d.id=DepID)
    loop
      SSOUT:=ii.name;
    end loop;    
    if DepID=138 then SSOUT:='Гинекология'; end if;
    if DepID=141 then SSOUT:='Дневной'; end if;
    if DepID=334 then SSOUT:='Дневной радио'; end if;
    if DepID=339 then SSOUT:='Дневной РО3'; end if;
    if DepID=142 then SSOUT:='Онкология 1'; end if;
    if DepID=143 then SSOUT:='Онкология 2'; end if; 
    if DepID=95  then SSOUT:='Анестизиология'; end if;
    if DepID=97  then SSOUT:='ОПП и РБ'; end if;
    if DepID=145 then SSOUT:='Радиология 1'; end if;
    if DepID=146 then SSOUT:='Радиология 2'; end if;
    if DepID=77  then SSOUT:='Радиология 3'; end if;
    if DepID=139 then SSOUT:='Химиотерапия 1'; end if;
    if DepID=140 then SSOUT:='Химиотерапия 2'; end if;
    if DepID=122 then SSOUT:='Хирургия 1'; end if;
    if DepID=0 or DepID is null then SSOUT:='ВСЕГО'; end if;
    return(SSOUT);
  end;   

--Вернуть полное имя отделения стационара по ид
  function GetDepname(DepID IN NUMBER) return VARCHAR2  
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:='';
    for ii in (select d.name from hospital.department d where d.id=DepID)
    loop
      SSOUT:=ii.name;
    end loop;    
--    if DepID=0 or DepID is null then SSOUT:='ВСЕГО'; end if;
    if DepID=0 then SSOUT:='ВСЕГО'; end if;
    if DepID is null then SSOUT:=''; end if;
    return(SSOUT);
  end;   
  
--поиск пациента в федеральном списке, по ФИО и дате рождения
  function FindFederalPatient(surname IN VARCHAR2, firstname IN VARCHAR2, patrname IN VARCHAR2, bday IN DATE, diag IN VARCHAR2 default '') return NUMBER
  is
    r NUMBER default null;
  begin
    for ii in (select cop.id, cop.sur_name,cop.first_name,cop.patr_name, cop.diagnosis_code mkbcode, cop.diagnosis_date d from hospital.cancer_outher_patient cop 
               where
                 cop.birthday=trunc(bday)
               order by 
                 cop.diagnosis_number desc  
              ) loop
        --в канцер-регистрах есть информация о таком пациенте
        if   replace(ii.sur_name,'Ё','Е')=replace(UPPER(surname),'Ё','Е') and 
             replace(ii.first_name,'Ё','Е')=replace(UPPER(firstname),'Ё','Е') and 
             (replace(replace(ii.patr_name,' ','-'),'Ё','Е')=replace(replace(UPPER(patrname),' ','-'),'Ё','Е') or
              ((nvl(ii.patr_name,'НЕТ')='НЕТ' or ii.patr_name='-') and (nvl(UPPER(patrname),'НЕТ')='НЕТ' or patrname='-'))
             ) then
         if substr(ii.mkbcode,1,length(diag))=diag or diag is null then
          r:=ii.id;
          exit;  --только с первой локализацией интересует
         end if;
        end if;
       end loop;   
    return(r);    
  end;  
  
--поиск пациента в федеральном списке, по строке в формате фамилия имя отчество dd.mm.yyyy 
  function FindFederalPatient(findst IN VARCHAR2) return NUMBER
  is
    r NUMBER default null;
    s varchar2(4000) default null;
    p varchar2(4000);
    d date;
  begin
    s:=trim(findst);
    s:=replace(s,'-',' ');
    s:=replace(s,'  ',' ');  
    s:=replace(s,'  ',' ');
    s:=upper(s);
    s:=replace(s,'Ё','Е');
    d:=to_date(substr(s,-10),'dd.mm.yyyy');
    s:=substr(s,1,length(s)-11);
    if substr(s,-4)=' НЕТ' then s:=substr(s,1,length(s)-4); end if;
    for ii in (select cop.id, cop.sur_name, cop.first_name, cop.patr_name 
                 from hospital.cancer_outher_patient cop where cop.birthday=d) loop
        if ii.patr_name='НЕТ' or ii.patr_name='-' or ii.patr_name is null then p:=''; else p:=' '||replace(replace(ii.patr_name,'-',' '),'Ё','Е'); end if;
        if replace(upper(ii.sur_name||' '||ii.first_name||p),'Ё','Е')=s then
          r:=ii.id;
          exit; 
        end if;
       end loop;   
    return(r);    
  end;    
  
--поиск пациента по строке поиска в ЭМК, возвращает client_id
--строка фамилия имя отчество dd.mm.yyyy  либо фамилия и.о. dd.mm.yyyy, поиск без даты рождения будет с 00.01.1900 (excel ТЕКСТ)
--со случаями стационарными возвращаем в первую очередь
--project_date - если указано - только если в указаную дату был случай
  function FindClient(findst in varchar2, project_date in date default null) return number
  is
    s varchar2(4000) default null;
    sd varchar2(10) default null;
    r number default null;  
    d date;
  begin
    s:=trim(findst);
    s:=replace(s,'  ',' ');  
    s:=replace(s,'  ',' ');
    sd:=substr(s,-10);
    s:=substr(s,1,length(s)-11);
    s:=upper(s);
    s:=replace(s,'Ё','Е');
    s:=replace(s,'-',' ');
    if substr(sd,1,2)<>'00' and substr(sd,3,1)='.' and substr(sd,6,1)='.' then  --есть дата рождения
      d:=to_date(sd,'dd.mm.yyyy');   
      for ii in (select cl.id,cl.sur_name,cl.first_name,cl.patr_name,cl.birthday
                   from hospital.client cl left join hospital.project p on p.client_id=cl.id
                  where cl.birthday=d
                        and (project_date between nvl(trunc(p.start_date),project_date) and nvl(trunc(p.end_date),project_date) or project_date is null)
                  order by decode(p.project_type_id,2,0,1), p.start_date, nvl(p.id,0) desc   
                ) loop
        if (substr(s,-1,1)='.')and(substr(s,-3,1)='.') then
          if replace(replace(replace(trim(upper(ii.sur_name||' '||substr(ii.first_name||' ',1,1)||'.'||substr(ii.patr_name||' ',1,1)||'.')),'Ё','Е'),'-',' '),'  ',' ')=s then
            r:=ii.id;
            exit;
          end if;  
        else
          if replace(replace(replace(trim(upper(ii.sur_name||' '||ii.first_name||' '||ii.patr_name)),'Ё','Е'),'-',' '),'  ',' ')=s then
            r:=ii.id;
            exit;
          end if;  
        end if;  
      end loop;     
    else --без даты рождения искать       
      for ii in (select cl.id,cl.sur_name,cl.first_name,cl.patr_name,cl.birthday
                   from hospital.client cl left join hospital.project p on p.client_id=cl.id
                  where     
                    case when (substr(s,-1,1)='.')and(substr(s,-3,1)='.') then
                      replace(replace(replace(trim(upper(cl.sur_name||' '||substr(cl.first_name||' ',1,1)||'.'||substr(cl.patr_name||' ',1,1)||'.')),'Ё','Е'),'-',' '),'  ',' ')
                    else 
                      replace(replace(replace(trim(upper(cl.sur_name||' '||cl.first_name||' '||cl.patr_name)),'Ё','Е'),'-',' '),'  ',' ') 
                    end = s    
                    and (project_date between nvl(trunc(p.start_date),project_date) and nvl(trunc(p.end_date),project_date) or project_date is null)
                  order by decode(p.project_type_id,2,0,1), p.start_date, nvl(p.id,0) desc
                ) loop
        r:=ii.id;
        exit;
      end loop;
    end if;
    return(r);
  end;  
  
  
--удовлетворяет ли данный случай условию необходимости создания Извещения о ЗНО
  function CheckProjectFirstNotice(pID IN NUMBER) return VARCHAR2
  is
   clID NUMBER;
   rst varchar2(4000);
  begin
   rst:='';
   for ii in (select p.client_id i from hospital.project p where p.id=pID)
   loop  
     clID:=ii.i;
   end loop;
   
   for ii in (select crd.id, mkbc.code mkbcode, crd.create_date d from hospital.cancer_register_document crd left join hospital.mkb mkbc on mkbc.id=crd.mkb_id
              where crd.client_id=clID and crd.document_type='FirstCancerNotice') --нет извещений по пациенту
   loop  
    --было хоть одно извещение
    rst:=rst||' Извещение есть '||ii.mkbcode||' с '||to_char(ii.d,'dd.mm.yyyy');
--    exit;
   end loop;
   
    for ii in (select cop.id, cop.diagnosis_code mkbcode, cop.diagnosis_date d from hospital.client cl, hospital.cancer_outher_patient cop 
               where cl.id=clID and 
                 replace(cop.sur_name,'Ё','Е')=replace(UPPER(cl.sur_name),'Ё','Е') and 
                 cop.first_name=UPPER(cl.first_name) and 
                 (replace(cop.patr_name,'Ё','Е')=replace(replace(UPPER(cl.patr_name),' ','-'),'Ё','Е') or
                  (nvl(cop.patr_name,'-')='-') and (nvl(UPPER(cl.patr_name),'НЕТ')='НЕТ' or UPPER(cl.patr_name)='-')
                 ) and
                 trunc(cop.birthday)=trunc(cl.birthday))
       loop
        --в канцер-регистрах есть информация о таком пациенте
        rst:=rst||' В федеральном регистре '||ii.mkbcode||' с '||to_char(ii.d,'dd.mm.yyyy');  
--        exit;
       end loop;             

    for ii in (select dis.id, mkbdi.code mkbcode from  
                            hospital.project p, hospital.disease dis
                            left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                            join hospital.mkb mkbdi on mkbdi.id=dis.mkb_id
              where
                p.id=pID and dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6)  --заключительные диагнозы по случаю
                and not exists (select 1 from hospital.disease disx where 
                                disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)  --только последний заключительный заболевание по случаю   
                and (substr(mkbdi.code,1,1)='C' or substr(mkbdi.code,1,2)='D0') and nvl(od.cancer_clinic_group_id,0) not in (1,2)--диагноз по случаю онко и группа не Ia или Ib
                and not exists (select 1 from 
                                  hospital.project p1 
                                  join hospital.disease dis1 on dis1.project_id=p1.id and dis1.diagnosis_type_id in (-4,-6)  --заключительные диагнозы по случаю
                                  join hospital.mkb mkbdi1 on mkbdi1.id=dis1.mkb_id 
                                  left join hospital.oncologic_disease od1 on od1.id=dis1.oncologic_disease_id   
                    where p1.client_id=clID        --по этому пациенту
                          and p1.id<>pID           --в других случаях смотрим  
                          and nvl(od1.cancer_clinic_group_id,0) not in (1,2)  --не указана клиническая группа 1а или 1б
                          and nvl(dis1.start_date,to_date('0001','yyyy'))<nvl(dis.start_date,p.end_date)            --смотрим предыдущие заключительные диагнозы, если дата текущего диагноза null - смотрим дату закрытия случая
                          and (substr(mkbdi1.code,1,1)='C' or substr(mkbdi1.code,1,2)='D0')
                                )                  --небыло в более ранних случаях диагноза онко 
               )
       loop
        --этот случай с диагнозом онко и других случаев c диагнозом онко поставленным ранее - небыло
        rst:=rst||' Диагноз первичен '||ii.mkbcode;  
--        exit;
       end loop;   
    
    for ii in (select dis.id, mkbdi.code mkbcode from  hospital.disease dis
                            left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                            join hospital.mkb mkbdi on mkbdi.id=dis.mkb_id
              where
                dis.project_id=pID and dis.diagnosis_type_id in (-4,-6)  --заключительные диагнозы по случаю
                and not exists (select 1 from hospital.disease disx where 
                                disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)  --только последний заключительный заболевание по случаю   
                and (substr(mkbdi.code,1,1)='C' or substr(mkbdi.code,1,2)='D0') --and nvl(od.cancer_clinic_group_id,0) not in (1,2)--диагноз по случаю онко и группа не Ia или Ib
                and exists (select 1 from 
                                  hospital.project p1 
                                  join hospital.disease dis1 on dis1.project_id=p1.id and dis1.diagnosis_type_id in (-4,-6)  --заключительные диагнозы по случаю
                                  join hospital.mkb mkbdi1 on mkbdi1.id=dis1.mkb_id 
                                  left join hospital.oncologic_disease od1 on od1.id=dis1.oncologic_disease_id   
                    where p1.client_id=clID        --по этому пациенту
                          and p1.id<pID           --смотрим только в предыдущем случае  
                          and not exists (select 1 from hospital.project px where px.client_id=clID and px.id<pID and px.id>p1.id)
                         -- and nvl(od1.cancer_clinic_group_id,0) not in (1,2)  --не указана клиническая группа 1а или 1б
                          and nvl(dis1.start_date,to_date('0001','yyyy'))<dis.start_date            --смотрим предыдущие заключительные диагнозы
                          and mkbdi1.code<>mkbdi.code      --в предыдущих заключительных диагнозах иной диагноз
                                )                 
               )
       loop
         --этот случай с диагнозом онко и других случаев c диагнозом онко поставленным ранее - небыло
         rst:=rst||' Диагноз изменился на '||ii.mkbcode;  
--         exit;
       end loop;   

    if rst is null then   -- извещения небыло, в федеральном небыл, диагноз не первичен, диагноз не изменялся
       for ii in (select dis1.id, mkbdi1.code mkbcode, p1.end_date enddate from 
                                  hospital.project p1 
                                  join hospital.disease dis1 on dis1.project_id=p1.id and dis1.diagnosis_type_id in (-4,-6)  --заключительные диагнозы по случаю
                                  join hospital.mkb mkbdi1 on mkbdi1.id=dis1.mkb_id 
                                  join hospital.oncologic_disease od1 on od1.id=dis1.oncologic_disease_id   
                    where p1.client_id=clID        --по этому пациенту
                          and p1.id<>pID           --в других случаях смотрим  
                          and nvl(od1.cancer_clinic_group_id,0) not in (1,2)  --не указана клиническая группа 1а или 1б
--                          and nvl(dis1.start_date,to_date('0001','yyyy'))<dis.start_date            --смотрим предыдущие заключительные диагнозы
                          and (substr(mkbdi1.code,1,1)='C' or substr(mkbdi1.code,1,2)='D0')
                          and not exists (select 1 from hospital.disease disx where 
                                          disx.project_id=dis1.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis1.id)  --только последний заключительный заболевание по другим случаям пациента

                 )
       loop
         rst:=rst||' Извещение нужно было ранее '||ii.mkbcode||' '||to_char(ii.enddate,'dd.mm.yyyy');  
--         exit;
       end loop;         
    end if;  

  return(rst);  
  end;     
  
--удовлетворяет ли данный случай условию необходимости создания Извещения о ЗНО, проверка вхождения текста
  function CheckProjectFirstNoticeText(pID IN NUMBER, st IN VARCHAR2) return BOOLEAN
  is
  begin
     return(instr(CheckProjectFirstNotice(pID),st)>0);
  end;    
  
--удовлетворяет ли данный случай условию необходимости создания Протокола IV 
  function CheckProjectNeglectedProtocol(pID IN NUMBER) return VARCHAR2
  is
   clID NUMBER;
   rst varchar2(100);
  begin
   rst:='';
   for ii in (select p.client_id i from hospital.project p where p.id=pID)
   loop  
     clID:=ii.i;
   end loop;
   
   for ii in (select crd.id, mkbc.code mkbcode from hospital.cancer_register_document crd left join hospital.mkb mkbc on mkbc.id=crd.mkb_id
              where crd.client_id=clID and crd.document_type='NeglectedCancerProtocol') --нет протокола по пациенту
   loop  
    rst:=rst||' Протокол есть '||ii.mkbcode;
    exit;
   end loop;

   for ii in (select dis.id, mkbdi.code mkbcode from  hospital.disease dis
                            left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                            join hospital.mkb mkbdi on mkbdi.id=dis.mkb_id
              where
                dis.project_id=pID and dis.diagnosis_type_id in (-4,-6)  --заключительные диагнозы по случаю
--                and not exists (select 1 from hospital.disease disx where 
--                                disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)  --только последний заболевание по случаю   
                and ( 
                       ( 
                        substr(mkbdi.code,1,1)='C' 
                        and substr(mkbdi.code,1,3) not in ('C71','C72','C80','C81','C82','C83','C84','C85','C86','C87','C88','C90','C91','C92','C93','C94','C95','C96','C97')
                        and substr(od.cancer_stage_value,1,6) in ('Stage4')   --диагноз C и стадия IV
                       )or(   
                        (substr(mkbdi.code,1,3) in ('C00','C01','C02','C03','C04','C06','C07','C08','C09','C10','C20','C21','C43','C44','C50','C51','C52','C53','C60','C62','C69','C73') 
                         or substr(mkbdi.code,1,5) in ('C63.2') )  
                        and substr(od.cancer_stage_value,1,6) in ('Stage3','Stage4')    --диагнозы C и стадии III или IV
                       )  
                    ) 
               )
   loop
        rst:=rst||' Протокол возможен '||ii.mkbcode;   
        exit;
   end loop;   
  return(rst);  
  end;      
  
--КЛАДР
--получить имя региона из кода КЛАДР
  function GetKLADRRegion(kladr IN VARCHAR2) return VARCHAR2 
  is
   n varchar2(1000);
  begin
    n:='';
    for ii in (select a.name_with_type nam from hospital.address a where substr(a.kladr_code,1,2)=substr(kladr,1,2) 
               and a.adress_item_level=200 and substr(a.kladr_code||'0000',3,13)='0000000000000') loop
      n:=ii.nam;
    end loop;  
    return(n);
  end;    
--получить имя района из кода КЛАДР
  function GetKLADRArea(kladr IN VARCHAR2) return VARCHAR2 
  is
   n varchar2(1000);
  begin
    n:='';
    for ii in (select a.name_with_type nam from hospital.address a where substr(a.kladr_code,1,2)=substr(kladr,1,2) 
               and substr(a.kladr_code,3,3)=substr(kladr,3,3) 
               and a.adress_item_level=300 and substr(a.kladr_code||'0000',6,10)='0000000000') loop
      n:=ii.nam;
    end loop;  
    return(n);
  end;
--получить имя города из кода КЛАДР
  function GetKLADRCity(kladr IN VARCHAR2) return VARCHAR2 
  is
   n varchar2(1000);
  begin
    n:='';
    for ii in (select a.name_with_type nam from hospital.address a where substr(a.kladr_code,1,2)=substr(kladr,1,2) 
               and substr(a.kladr_code,3,3)=substr(kladr,3,3) and substr(a.kladr_code,6,3)=substr(kladr,6,3) 
               and a.adress_item_level=400 and substr(a.kladr_code||'0000',9,7)='0000000') loop
      n:=ii.nam;
    end loop;  
    return(n);
  end;  
--получить имя населенного пункта из кода КЛАДР
  function GetKLADRVillage(kladr IN VARCHAR2) return VARCHAR2 
  is
   n varchar2(1000);
  begin
    n:='';
    for ii in (select a.name_with_type nam from hospital.address a where substr(a.kladr_code,1,11)=substr(kladr,1,11) 
--               and substr(a.kladr_code,3,3)=substr(kladr,3,3) and substr(a.kladr_code,6,3)=substr(kladr,6,3) and substr(a.kladr_code,9,3)=substr(kladr,9,3) 
               and a.adress_item_level=500 and substr(a.kladr_code||'0000',12,4)='0000') loop
      n:=ii.nam;
    end loop;  
    return(n);
  end;        
  
--получить имя территории из строки адреса
  function GetTerritory(address IN VARCHAR2) return VARCHAR2 
  is
   v varchar2(2000);
  begin
    --правка Протасов, 10 09 2019
    v:=replace(address,'Россия, ','');
    v:=replace(v,'РОССИЯ; ','');
    v:=replace(v,'  ',' ');
    v:=replace(v,';',',');

    if lower(substr(v,1,6))='москва' then v:='Москва,,'; end if;
    if lower(substr(v,1,11))='севастополь' then v:='Севастополь,,'; end if;
    if lower(substr(v,1,18))='г. санкт-петербург' then v:='Санкт-Петербург,,'; end if;  
    if lower(substr(v,1,15))='санкт-петербург' then v:='Санкт-Петербург,,'; end if;    

    if lower(substr(v,1,11))='тюмень обл.' then v:='Тюменская, '||v; end if;
    if lower(substr(v,1,9))='тюменский' then v:='Тюменская, '||v; end if;
    if lower(substr(v,1,9))='г. тюмень' then v:='Тюменская, '||v; end if;
    if lower(substr(v,1,8))='г.тюмень' then v:='Тюменская, '||v; end if;
    if lower(substr(v,1,8))='г тюмень' then v:='Тюменская, '||v; end if;
    if lower(substr(v,1,14))='пос. боровской' then v:='Тюменская, Тюменский р-н., '||v; end if;
    if lower(substr(v,1,8))='г. пермь' then v:='Пермский Край., '||v; end if;
    if lower(substr(v,1,14))='г. голышманово' then v:='Тюменская, Голышмановский р-н., рп. Голышманово,'||v; end if;
    if lower(substr(v,1,15))='тюмень. гилево.' then v:='Тюменская, Тюмень,'; end if;
    if lower(substr(v,1,10))='бердюжский' then v:='Тюменская, '||v; end if;
    if lower(substr(v,1,8))='ишимский' then v:='Тюменская, '||v; end if;
    if lower(substr(v,1,5))='ишим,' then v:='Тюменская, '||v; end if;
    if lower(v)='тюмень' then v:='Тюменская, Тюмень,'; end if;
    v:=replace(v,'г. тюмень п.винзили,','Тюменский р-н., Винзили п.,');
    v:=replace(v,'Тюменская область обл., г. П.новоторманский','Тюменская обл., Тюменский р-н., Новотарманский п.');
    v:=replace(v,'Тюменская обл., Г. воронино,','Тюменская обл., Тюмень г., Воронино д.');
    v:=replace(v,'Тюменская обл., с. Шишкина,','Тюменская обл., Вагайский р-н., Шишкина с.,');
    v:=replace(v,'Тюменская обл., МКР. Молодежный, Д. Ушакова','Тюменская обл., Тюменский р-н., Ушакова д.'); 
    v:=replace(v,'Тюменская обл., Ханты- мансийский ао р-н., п. Г.нефтеюганска','Ханты-Мансийский Автономный Округ - Югра АО., Нефтеюганск г.');
    v:=replace(v,'Тюменская обл., ХМАО Р-Н., П. НЕФТЕЮГАНСК','Ханты-Мансийский Автономный Округ - Югра АО., Нефтеюганск г.');
    v:=replace(v,' тюменская обл., Хмао р-н., п. Югорск','Ханты-Мансийский Автономный Округ - Югра АО., Югорск г.'); 
    v:=replace(v,'Тюменская обл., Хмао р-н., п. Радужный','Ханты-Мансийский Автономный Округ - Югра АО., Радужный г.');     
    v:=replace(v,'Тюменская область ОБЛ., ЯМАЛО-НЕНЕЦКИЙ АВТОНОМНЫЙ ОКРУГ Р-Н., П. НОВЫЙ УРЕНГОЙ','Ямало-Ненецкий АО., Новый Уренгой г.');
    v:=replace(v,'Тюменская обл., Янао р-н.','Ямало-Ненецкий АО.');
    v:=replace(v,'Тюменская обл., ЯНАО Р-Н.','Ямало-Ненецкий АО.');
    v:=replace(v,' п. Тарко-сале',' Тарко-сале');
    v:=replace(v,' п. Яр-сале',' Яр-сале');
    v:=replace(v,'П. Ноябрьск','Ноябрьск');
    v:=replace(v,'пермская ОБЛ., Г. пос.Сарс','Пермский Край., Октябрьский р-н.');
    v:=replace(v,'Мотовилихинском р-не р-н., п. Пермь','Пермский Край., Пермь г.');
    v:=replace(v,'Г. Десятово с. (Тюменская обл., Ишимский р-н., С. Десятово)','Тюменская обл., Ишимский р-н.');
    v:=replace(v,'г. Тобольск мкр.','г. Тобольск, мкр.');
    v:=replace(v,'Тюменская обл., ПУРОВСКИЙ Р-Н.,','Ямало-Ненецкий АО., Пуровский р-н.,');
    v:=replace(v,'СВЕРДЛОВСКАЯ обл., СЛОБОДО-ТУРИНСКИЙ р-н.,','Свердловская обл., Туринский р-н.,');
    v:=replace(v,' Сорокинского р-на',' Сорокинский');
    v:=replace(v,'Тюменской обл.','Тюменская обл.');
    v:=replace(v,'тюменской ОБЛ.','Тюменская обл.');
    v:=replace(v,'Тюменская область обл.','Тюменская обл.');
    v:=replace(v,' Тмень р-н., п. Тюмень',' Тюмень г.');
    v:=replace(v,' г. Тюмень ул',' Тюмень г., ул');   
    v:=replace(v,' Г.тюмень р-н.',' Тюмень г.');  
    v:=replace(v,' г. Тюмень 7 км',' Тюмень г., ул 7 км');  
    v:=replace(v,' г.Тюмень',' Тюмень г.');
    v:=replace(v,' Г ТЮМЕНЬ',' Тюмень г.');
    v:=replace(v,' Г.ТЮМЕНЬ',' Тюмень г.');
    v:=replace(v,' Надымскимй р-н.',' Надымский р-н.');
    v:=replace(v,' Ишимский район ',' Ишимский р-н.,');
    v:=replace(v,' Тюменский район,',' Тюменский р-н.,');
    v:=replace(v,' Тюменский район р-н',' Тюменский р-н.,');
    v:=replace(v,' ТЮМЕНСКИЙ РАЙОН Р-Н',' Тюменский р-н.,');
    v:=replace(v,' Тюменский р-он р-н',' Тюменский р-н.,');
    v:=replace(v,' Тюменском р-н',' Тюменский р-н.,');
    v:=replace(v,' Тюменского р-н.,',' Тюменский р-н.,');
    v:=replace(v,' Сорокинского р-н.,',' Сорокинский р-н.,'); 
    v:=replace(v,' Ишимского р-н.,',' Ишимский р-н.,'); 
    v:=replace(v,' упоровского р-на Р-Н.,',' Упоровский р-н.,'); 


    v:=lower(v);
    v:=replace(v,'респ. дагестан','Дагестан Респ.');
    v:=replace(v,'дагестан,','Дагестан Респ.,');
    v:=replace(v,'респ. бурятия','Бурятия Респ.');
    v:=replace(v,'республика башкортостан','Башкортостан Респ.');
    v:=replace(v,' область обл.');
    v:=replace(v,'г. днт наука,','г. тюмень,');

    v:=substr(v,1,instr(v,',',1,2)-1);
    v:=replace(v,' обл.');
    v:=replace(v,'обл. ');
    v:=replace(v,'г. ');
    v:=replace(v,' г.');
    v:=replace(v,' р-н.');
    v:=replace(v,'р-н. ');
    v:=replace(v,' р-он');
    v:=replace(v,' р-на');

    v:=initcap(v);
    v:=replace(v,' Ао.',' АО.');
    v:=replace(v,' Ао,',' АО.,');
    v:=replace(v,'Хмао','Ханты-Мансийский Автономный Округ - Югра АО.');
    v:=replace(v,'Ханты-Мансийский Автономный Округ - Югра АО.','ХМАО - Югра АО.');
    v:=replace(v,'Янао','Ямало-Ненецкий АО.');

    if substr(v,1,14)='Кугаева, Ул. -' then v:=''; end if;
    if ltrim(v) is null then v:=' неопределенно'; end if;
    return(v);
  end;  
  
--получить имя региона территории из строки адреса 
  function GetTerritoryRegion(address IN VARCHAR2) return VARCHAR2    
  is
   v varchar2(2000);
  begin  
    v:=GetTerritory(address);
    if v='Тюменская, Тюмень' then 
      v:='   Тюмень';
    else
    v:=substr(v,1,6);
    case 
      when v='Ханты-' then v:=' Ханты-Мансийский округ';
      when v='ХМАО -' then v:=' Ханты-Мансийский округ';
      when v='Ямало-' then v:=' Ямало-Ненецкий округ';
      when v='Тюменс' then v:='  Юг Тюменской области';
      else v:='Вне районов Тюменской области';
    end case;
    end if;         
    return(v);
  end;     
  
--получить имя области из территории из строки адреса
  function GetTerritoryState(address IN VARCHAR2) return VARCHAR2    
  is
   v varchar2(2000);
  begin  
    v:=GetTerritory(address);
    if v=' неопределенно' then 
      v:='';
    else  
      v:=substr(v||',',1,instr(v||',',',')-1);
      v:=substr(v||'.',1,instr(v||'.','.')-1);
    end if;
    return(v);
  end;   

--получить имя населенного пункта из строки адреса
  function GetTerritoryCity(address IN VARCHAR2) return VARCHAR2    
  is
   v varchar2(2000);
   k integer default 2;
  begin  
    v:=GetTerritory(address);
    if v=' неопределенно' then 
      v:='';
    else  
      v:=replace(address,';',',');
      v:=replace(v,'Россия,');
      if instr(v,',',1,3)=0 then k:=1; end if;
      v:=substr(v,instr(v,',',1,k)+1,instr(v,',',1,k+1)-instr(v,',',1,k)-1);
      v:=trim(initcap(v));
      if instr(v,' ')>5 then
        v:=substr(v,instr(v,' ')+1)||' '||substr(v,1,instr(v,' ')-1);
      end if;
      v:=lower(substr(v,1,1))||substr(v,2);
    end if;
    return(v);
  end;   
  
--получить федеральный код территории из строки адреса 
  function GetTerritoryFedCode(address IN VARCHAR2) return INTEGER    
  is
   v varchar2(2000);
   r integer;
  begin  
    v:=GetTerritory(address);
    case v
      when 'Тюменская, Тюмень' then r:=1;   --Г.ТЮМЕНЬ
      when 'Тюменская, Тобольск' then r:=10;  --Г.ТОБОЛЬСК
      when 'Тюменская, Ишим'     then r:=11;  --Г.ИШИМ
      when 'Тюменская, Абатский' then r:=18;  --АБАТСКИЙ
      when 'Тюменская, Армизонский' then r:=19;  --АРМИЗОНСКИЙ
      when 'Тюменская, Аромашевский' then r:=20;  --АРОМАШЕВСКИЙ
      when 'Тюменская, Бердюжский' then r:=21;  --БЕРДЮЖСКИЙ
      when 'Тюменская, Вагайский' then r:=22;  --ВАГАЙСКИЙ
      when 'Тюменская, Викуловский' then r:=23;  --ВИКУЛОВСКИЙ
      when 'Тюменская, Голышмановский' then r:=24;  --ГОЛЫШМАНОВСКИЙ
      when 'Тюменская, Заводоуковск' then r:=25;  --ЗАВОДОУКОВСКИЙ
      when 'Тюменская, Заводоуковский' then r:=25;  --ЗАВОДОУКОВСКИЙ
      when 'Тюменская, Исетский' then r:=26;  --ИСЕТСКИЙ
--      when 'Тюменская, Ишим' then r:=27;  --ИШИМСКИЙ
      when 'Тюменская, Ишимский' then r:=27;  --ИШИМСКИЙ
      when 'Тюменская, Казанский' then r:=28;  --КАЗАНСКИЙ
      when 'Тюменская, Нижнетавдинский' then r:=29;  --Н-ТАВДИНСКИЙ
      when 'Тюменская, Омутинский' then r:=30;  --ОМУТИНСКИЙ
      when 'Тюменская, Сладковский' then r:=31;  --СЛАДКОВСКИЙ
      when 'Тюменская, Сорокинский' then r:=32;  --СОРОКИНСКИЙ
--      when 'Тюменская, Тобольск' then r:=33;  --ТОБОЛЬСКИЙ
      when 'Тюменская, Тобольский' then r:=33;  --ТОБОЛЬСКИЙ
      when 'Тюменская, Тюменский' then r:=34;  --ТЮМЕНСКИЙ
      when 'Тюменская, Уватский' then r:=35;  --УВАТСКИЙ
      when 'Тюменская, Упоровский' then r:=36;  --УПОРОВСКИЙ
      when 'Тюменская, Юргинский' then r:=37;  --ЮРГИНСКИЙ
      when 'Тюменская, Ялуторовск' then r:=38;  --ЯЛУТОРОВСКИЙ
      when 'Тюменская, Ялуторовский' then r:=38;  --ЯЛУТОРОВСКИЙ
      when 'Тюменская, Ярковский' then r:=39;  --ЯРКОВСКИЙ
      when 'ХМАО - Югра АО., Покачи' then r:=40;  --Г.ПОКАЧИ
      when 'ХМАО - Югра АО., Когалым' then r:=41;  --Г.КОГАЛЫМ
      when 'ХМАО - Югра АО., Лангепас' then r:=42;  --Г.ЛАНГЕПАС
      when 'ХМАО - Югра АО., Мегион' then r:=43;  --Г.МЕГИОН
      when 'ХМАО - Югра АО., Нижневартовск' then r:=44;  --Г.Н-ВАРТОВСК
      when 'ХМАО - Югра АО., Нефтеюганск' then r:=45;  --Г.НЕФТЕЮГАНСК
      when 'ХМАО - Югра АО., Нягань' then r:=46;  --Г.НЯГАНЬ
      when 'ХМАО - Югра АО., Пыть-Ях' then r:=47;  --Г.ПЫТЬ-ЯХ
      when 'ХМАО - Югра АО., Радужный' then r:=48;  --Г.РАДУЖНЫЙ
      when 'ХМАО - Югра АО., Сургут' then r:=49;  --Г.СУРГУТ
      when 'ХМАО - Югра АО., Урай' then r:=50;  --Г.УРАЙ
      when 'ХМАО - Югра АО., Ханты-Мансийск' then r:=51;  --г.Ханты-Мансийск
      when 'ХМАО - Югра АО., Югорск' then r:=52;  --Г.ЮГОРСК
      when 'ХМАО - Югра АО., Белоярский' then r:=60;  --БЕЛОЯРСКИЙ
      when 'ХМАО - Югра АО., Березовский' then r:=61;  --БЕРЕЗОВСКИЙ
      when 'ХМАО - Югра АО., Кондинский' then r:=62;  --КОНДИНСКИЙ
      when 'ХМАО - Югра АО., Нижневартовский' then r:=63;  --Н-ВАРТОВСКИЙ
      when 'ХМАО - Югра АО., Нефтеюганский' then r:=64;  --Н-ЮГАНСКИЙ
      when 'ХМАО - Югра АО., Октябрьский' then r:=65;  --ОКТЯБРЬСКИЙ
      when 'ХМАО - Югра АО., Советский' then r:=66;  --СОВЕТСКИЙ
      when 'ХМАО - Югра АО., Сургутский' then r:=67;  --СУРГУТСКИЙ
      when 'ХМАО - Югра АО., Лянтор' then r:=67;  --СУРГУТСКИЙ
      when 'ХМАО - Югра АО., Ханты-Мансийский' then r:=68;  --Х-МАНСИЙСКИЙ
      when 'Ямало-Ненецкий АО., Новый Уренгой' then r:=70;  --Г.НОВЫЙ УРЕНГОЙ
      when 'Ямало-Ненецкий АО., Ноябрьск' then r:=71;  --Г.НОЯБРЬСК
      when 'Ямало-Ненецкий АО., Губкинский' then r:=72;  --Г.ГУБКИНСКИЙ
      when 'Ямало-Ненецкий АО., Лабытнанги' then r:=73;  --Г.ЛАБЫТНАНГИ
      when 'Ямало-Ненецкий АО., Муравленко' then r:=74;  --Г.МУРАВЛЕНКОВСКИЙ
      when 'Ямало-Ненецкий АО., Салехард' then r:=75;  --Г.САЛЕХАРД
      when 'Ямало-Ненецкий АО., Красноселькупский' then r:=80;  --КРАСНОСЕЛЬКУПСКИЙ7
      when 'Ямало-Ненецкий АО., Надымский' then r:=81;  --НАДЫМСКИЙ
      when 'Ямало-Ненецкий АО., Надым' then r:=81;  --НАДЫМСКИЙ  
      when 'Ямало-Ненецкий АО., Приуральский' then r:=82;  --ПРИУРАЛЬСКИЙ
      when 'Ямало-Ненецкий АО., Пуровский' then r:=83;  --ПУРОВСКИЙ
      when 'Ямало-Ненецкий АО., Тарко-Сале' then r:=83;  --ПУРОВСКИЙ
      when 'Ямало-Ненецкий АО., Тазовский' then r:=84;  --ТАЗОВСКИЙ
      when 'Ямало-Ненецкий АО., Шурышкарский' then r:=85;  --ШУРЫШКАРСКИЙ
      when 'Ямало-Ненецкий АО., Ямальский' then r:=86;  --ЯМАЛЬСКИЙ
    else r:=0;
    end case;
    return(r);
  end;   
  
--получить имя куста из территории (группа районов) 
--18 12 2018 голышмановски отдельно
  function GetTerritoryBush(address IN VARCHAR2) return varchar2    
  is
   r varchar2(2000);
   t varchar2(2000);
  begin  
    t:=GetTerritory(address);
    case t
      when 'Тюменская, Тюмень' then r:='Тюмень';   --Г.ТЮМЕНЬ
      when 'Тюменская, Тобольск' then r:='Тобольский';  --Г.ТОБОЛЬСК
      when 'Тюменская, Ишим'     then r:='Ишимский';  --Г.ИШИМ
      when 'Тюменская, Абатский' then r:='Ишимский';  --АБАТСКИЙ
      when 'Тюменская, Армизонский' then r:='Ишимский';  --АРМИЗОНСКИЙ
      when 'Тюменская, Аромашевский' then r:='Голышмановский';  --АРОМАШЕВСКИЙ
      when 'Тюменская, Бердюжский' then r:='Ишимский';  --БЕРДЮЖСКИЙ
      when 'Тюменская, Вагайский' then r:='Тобольский';  --ВАГАЙСКИЙ
      when 'Тюменская, Викуловский' then r:='Ишимский';  --ВИКУЛОВСКИЙ
      when 'Тюменская, Голышмановский' then r:='Голышмановский';  --ГОЛЫШМАНОВСКИЙ
      when 'Тюменская, Заводоуковск' then r:='Заводоуковский';  --ЗАВОДОУКОВСКИЙ
      when 'Тюменская, Заводоуковский' then r:='Заводоуковский';  --ЗАВОДОУКОВСКИЙ
      when 'Тюменская, Исетский' then r:='Тюменский';  --ИСЕТСКИЙ
--      when 'Тюменская, Ишим' then r:=27;  --ИШИМСКИЙ
      when 'Тюменская, Ишимский' then r:='Ишимский';  --ИШИМСКИЙ
      when 'Тюменская, Казанский' then r:='Ишимский';  --КАЗАНСКИЙ
      when 'Тюменская, Нижнетавдинский' then r:='Тюменский';  --Н-ТАВДИНСКИЙ
      when 'Тюменская, Омутинский' then r:='Голышмановский';  --ОМУТИНСКИЙ
      when 'Тюменская, Сладковский' then r:='Ишимский';  --СЛАДКОВСКИЙ
      when 'Тюменская, Сорокинский' then r:='Ишимский';  --СОРОКИНСКИЙ
--      when 'Тюменская, Тобольск' then r:='Тобольский';  --ТОБОЛЬСКИЙ
      when 'Тюменская, Тобольский' then r:='Тобольский';  --ТОБОЛЬСКИЙ
      when 'Тюменская, Тюменский' then r:='Тюменский';  --ТЮМЕНСКИЙ
      when 'Тюменская, Уватский' then r:='Тобольский';  --УВАТСКИЙ
      when 'Тюменская, Упоровский' then r:='Заводоуковский';  --УПОРОВСКИЙ
      when 'Тюменская, Юргинский' then r:='Голышмановский';  --ЮРГИНСКИЙ
      when 'Тюменская, Ялуторовск' then r:='Заводоуковский';  --ЯЛУТОРОВСКИЙ
      when 'Тюменская, Ялуторовский' then r:='Заводоуковский';  --ЯЛУТОРОВСКИЙ
      when 'Тюменская, Ярковский' then r:='Тюменский';  --ЯРКОВСКИЙ
    else r:='';
    end case;
    return(r);
  end;     
  
--проверка канцер-выписки. выявление кривых данных.
  function CheckCancerSummary(Cancer_Summary_ID IN NUMBER) return VARCHAR2
  is
    r VARCHAR2(4000);
    hc_id NUMBER;
    ex boolean;
    ntemp varchar2(1000);
  begin
    r:='';
    for cas in (select * from hospital.cancer_summary where id=Cancer_Summary_ID) loop
      hc_id:=cas.hospital_card_id;
      if hc_id is null then 
        r:=' Нет стационарной карты';
        for cdo in (select * from hospital.cancer_document_operation cdo where cdo.document_id=cas.document_id and cdo.operation='CreateFromOtherOrganization') loop
          r:='';
        end loop;  
        exit;
      end if;
      for hc in (select * from hospital.hospital_card where id=hc_id) loop
        if trunc(cas.hospital_receive_date)<>trunc(hc.receive_date) then
          r:=r||chr(10)||'Дата поступления в стацкарте '||to_char(hc.receive_date,'dd.mm.yyyy')||' не равна дате поступления в канцервыписке '||to_char(cas.hospital_receive_date,'dd.mm.yyyy');
        end if;
        if trunc(cas.hospital_discharge_death_date)<>trunc(hc.outtake_date) then
          r:=r||chr(10)||'Дата выписки в стацкарте '||to_char(hc.outtake_date,'dd.mm.yyyy')||' не равна дате выписки в канцервыписке '||to_char(cas.hospital_discharge_death_date,'dd.mm.yyyy');
        end if;
--        if trunc(hc.close_date)<>trunc(hc.outtake_date) then
--          r:=r||chr(10)||'Дата выписки в стацкарте '||to_char(hc.outtake_date,'dd.mm.yyyy')||' не равна дате закрытия стацкарты '||to_char(hc.close_date,'dd.mm.yyyy');
--        end if;
        for crd in (select * from hospital.cancer_register_document where id=cas.document_id) loop
          for cl in (select * from hospital.client where id=crd.client_id) loop
            if initcap(crd.client_sur_name)<>initcap(cl.sur_name) or initcap(crd.client_first_name)<>initcap(cl.first_name) or initcap(crd.client_patr_name)<>initcap(cl.patr_name) then
              r:=r||chr(10)||'ФИО в канцервыписке '||initcap(crd.client_sur_name)||' '||initcap(crd.client_first_name)||' '||initcap(crd.client_patr_name)||' не равно ФИО '||initcap(cl.sur_name)||' '||initcap(cl.first_name)||' '||initcap(cl.patr_name)||' в карте';
            end if;
            if trunc(crd.client_birthday)<>trunc(cl.birthday) then
              r:=r||chr(10)||'Дата рождения в канцервыписке не равна дате рождения в стацкарте';
            end if;
            if crd.client_sex<>cl.sex then
              r:=r||chr(10)||'Пол в канцервыписке не равен полу в стацкарте';
            end if;  
          end loop;
          for dis in (select di.*, m.code mkbcode from hospital.disease di, hospital.mkb m
                      where di.project_id=hc.project_id and di.diagnosis_type_id in (-4,-6) and m.id=di.mkb_id) loop
            for mkb in (select * from hospital.mkb where id=crd.mkb_id) loop          
--              if dis.mkbcode<>substr(mkb.code,1,length(dis.mkbcode)) then   --с 17 04 только 3 символа кода сверям
              if substr(dis.mkbcode,1,3)<>substr(mkb.code,1,3) then
                r:=r||chr(10)||'Диагноз в выписке '||mkb.code||' не равен заключительному диагнозу '||dis.mkbcode||' случая';
              end if;
            end loop;
          end loop;
        end loop;
      
     ex:=false;
     for csrt in (select * from hospital.cancer_sum_rad_treat_meth where cancer_summary_id=cas.id) loop
        if csrt.type_id is null then
          r:=r||chr(10)||'Не указан вид лучевой терапии';
        end if;
        if csrt.frac_mode_id is null then
          r:=r||chr(10)||'Не указан метод облучения';
        end if;    
        if csrt.method_id is null then
          r:=r||chr(10)||'Не указан способ облучения';
        end if;     
        if csrt.area_id is null then
          r:=r||chr(10)||'Не указан орган облучения';
        end if;                 
        if trunc(csrt.date_plan) not between trunc(hc.receive_date) and trunc(hc.outtake_date) then
          r:=r||chr(10)||'Дата '||to_char(csrt.date_plan,'dd.mm.yyyy')||' лучевой терапии вне госпитализации';
        end if;        
        ex:=true;
      end loop;  
      if ex and cas.rad_treat_worker_id is null then
          r:=r||chr(10)||'Не указан врач лучевой терапевт';--||', id случая '||hc.project_id;
          ntemp:='';
          for ch in (select distinct w.sur_name||' '||substr(w.first_name,1,1)||'.'||substr(w.patr_name,1,1)||'.' chname from
                            hospital.medical_record mr
                            join hospital.appointment a on a.medical_record_id=mr.id
                            join hospital.rad_treat_meth_appointment rt on rt.appointment_id=a.id
                            join hospital.appointment_task atas on atas.appointment_id=a.id and atas.execute_worker_id is not null
                            join hospital.worker w on w.id=mr.worker_id
                     where mr.project_id=hc.project_id ) loop
            if ntemp is not null then         
              ntemp:=ntemp||', '||ch.chname;
            else 
              ntemp:=ch.chname;  
            end if;         
          end loop;
          r:=r||', в случае лучевую терапию назначал '||ntemp;         
      end if;

      for csht in (select * from hospital.cancer_sum_drug_treat where cancer_summary_id=cas.id and drug_treatment_type<>'ChemoTherapeutic') loop
        if trunc(csht.start_date) not between trunc(hc.receive_date) and trunc(hc.outtake_date) then
          r:=r||chr(10)||'Дата '||to_char(csht.start_date,'dd.mm.yyyy')||' гормоно(таргет)терапии вне госпитализации';
        end if;        
      end loop;
      ex:=false;
      for csht in (select * from hospital.cancer_sum_drug_treat where cancer_summary_id=cas.id and drug_treatment_type='ChemoTherapeutic') loop
        if csht.federal_drug_id is null then
          r:=r||chr(10)||'В химиотерапии не указан федеральный препарат';
        end if;
        if trunc(csht.start_date) not between trunc(hc.receive_date) and trunc(hc.outtake_date) then
          r:=r||chr(10)||'Дата '||to_char(csht.start_date,'dd.mm.yyyy')||' химиотерапии вне госпитализации';
        end if;        
        ex:=true;
      end loop;
      if ex and cas.chemother_treat_worker_id is null then
          r:=r||chr(10)||'Не указан врач химиотерапевт';--||', id случая '||hc.project_id;
          ntemp:='';
          for ch in (select distinct w.sur_name||' '||substr(w.first_name,1,1)||'.'||substr(w.patr_name,1,1)||'.' chname from
                            hospital.medical_record mr
                            join hospital.appointment a on a.medical_record_id=mr.id
                            join hospital.drug_appointment da on da.appointment_id=a.id
                            join hospital.appointment_task atas on atas.appointment_id=a.id and atas.execute_worker_id is not null
                            join hospital.worker w on w.id=mr.worker_id
                     where mr.project_id=hc.project_id ) loop
            if ntemp is not null then         
              ntemp:=ntemp||', '||ch.chname;
            else 
              ntemp:=ch.chname;  
            end if;         
          end loop;
          r:=r||', в случае препараты назначал '||ntemp;           
      end if; 

      for cssu in (select * from hospital.cancer_sum_surgery_treat where cancer_summary_id=cas.id) loop
--        if cssu.surgery_id is null then
--           r:=r||chr(10)||'Нет связи хирургической операции с операцией в стацкарте';
--        end if;
        if cssu.surgery_type_id is null then
           r:=r||chr(10)||'Не указан федеральный код хирургической операции';
        end if;  
        if trunc(cssu.start_date) not between trunc(hc.receive_date) and trunc(hc.outtake_date) then
          r:=r||chr(10)||'Дата '||to_char(cssu.start_date,'dd.mm.yyyy')||' операции в выписке вне госпитализации.';
        end if;
        for si in (select trunc(s1.start_date) d from hospital.surgery s1 where s1.project_id=hc.project_id) loop
        if si.d not between trunc(hc.receive_date) and trunc(hc.outtake_date) then
          r:=r||chr(10)||'Дата '||to_char(si.d,'dd.mm.yyyy')||' операции в стацкарте вне госпитализации.';
        end if;             
        end loop;
        for cssuw in (select * from hospital.cancer_sum_surgery_worker w where w.cancer_summary_surgery_id=cssu.id and w.role_id=1) loop
          if cssuw.worker_id is null then
            r:=r||chr(10)||'Не указан врач-хирург';
          end if;
        end loop;
      end loop;  
      
      for s in (select st.name sname, st.code scode from hospital.surgery su, hospital.service_type st
                        where su.project_id=hc.project_id and su.execute_state='Done' and st.id=su.service_type_id
                              and not exists (select 1 from hospital.cancer_sum_surgery_treat csst where csst.surgery_id=su.id) ) loop
          r:=r||chr(10)||'В стацкарте имеется операция '||s.scode||' "'||s.sname||'" несвязанная с операцией в выписке';
      end loop;  
      
      for csra in (select * from hospital.cancer_sum_anes_resus_aid where cancer_summary_id=cas.id) loop
        if csra.worker_id is null then
          r:=r||chr(10)||'Не указан врач-анестезиолог';
          ntemp:='';
          for wa in (select distinct w.sur_name||' '||substr(w.first_name,1,1)||'.'||substr(w.patr_name,1,1)||'.' chname
                     from hospital.worker w, hospital.surgery_worker sw, hospital.surgery s 
                     where sw.worker_id=w.id and sw.surgery_worker_role_id=3 and sw.surgery_id=s.id and s.project_id=hc.project_id) loop
           if ntemp is not null then         
              ntemp:=ntemp||', '||wa.chname;
            else 
              ntemp:=wa.chname;  
            end if;         
          end loop;
          if ntemp is null then
            r:=r||', в случае отсутсвовал анестезиолог';
          else
            r:=r||', в случае присутсвовал анестезиолог '||ntemp;              
          end if;  
        end if;
        if csra.anesthesia_duration is null then
          r:=r||chr(10)||'В анестезиологическом пособии не указана длительность наркоза';
        end if;
        if csra.anesthesia_type_id is null then
          r:=r||chr(10)||'В анестезиологическом пособии не указан вид анестезии';
        end if;
      end loop;
      
      end loop; --hc
    end loop;  --cas
    r:=substr(r,2);
    return(r);
  end;    
  
--получить планируемое количество койко-дней для указанного отделения за указанный период (корректно для периода внутри одного года)  
--коррекция на кварталы с 26 по 25 с 2019 года, протасов 31 01 2019
  function GetPlanBedDays(Dep_ID IN NUMBER, DTF IN DATE, DTT IN DATE) return NUMBER
  is
    r NUMBER default 0;
  begin
    if to_number(to_char(dtt,'yyyy'))<2019 then
      for ii in (
        select
            sum(case bd.fquarter when 1 then bd.beddays*greatest(months_between(1+least(dtt,to_date('31.03.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('01.01.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')) ),0)/3
                                 when 2 then bd.beddays*greatest(months_between(1+least(dtt,to_date('30.06.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('01.04.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')) ),0)/3
                                 when 3 then bd.beddays*greatest(months_between(1+least(dtt,to_date('30.09.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('01.07.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')) ),0)/3
                                 when 4 then bd.beddays*greatest(months_between(1+least(dtt,to_date('31.12.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('01.10.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')) ),0)/3
            end)   beddays  --количество койко-дней в плане в указанный период   
        from
            stat.bedplan bd
        where
            bd.fyear=to_number(to_char(dtf,'yyyy')) and bd.department_id=Dep_ID
      ) loop
        r:=ii.beddays;
      end loop;  
    else  --с 2019 года кварталы считаем с 25 по 26 число, (1й квартал с 25.12.2018 по 26.03.2019)
      for ii in (
        select
            sum(case bd.fquarter when 1 then bd.beddays*greatest(months_between(1+least(dtt,to_date('25.03.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('01.01.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')-6) ),0)/3
                                 when 2 then bd.beddays*greatest(months_between(1+least(dtt,to_date('25.06.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('26.03.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')) ),0)/3
                                 when 3 then bd.beddays*greatest(months_between(1+least(dtt,to_date('25.09.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('26.06.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')) ),0)/3
                                 when 4 then bd.beddays*greatest(months_between(1+least(dtt,to_date('25.12.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('26.09.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')) ),0)/3
            end)   beddays  --количество койко-дней в плане в указанный период   
        from
            stat.bedplan bd
        where
            bd.fyear=to_number(to_char(dtt,'yyyy')) and bd.department_id=Dep_ID
      ) loop
        r:=ii.beddays;
      end loop;  
    end if;   
    return(r);
  end;  
  
--получить планируемое количество коек для указанного отделения за указанный период (корректно для периода внутри одного года)  
--коррекция на кварталы с 26 по 25 с 2019 года, протасов 31 01 2019
  function GetPlanBeds(Dep_ID IN NUMBER, DTF IN DATE, DTT IN DATE) return NUMBER
  is
    r NUMBER default 0;
  begin
    if to_number(to_char(dtt,'yyyy'))<2019 then
      for ii in (
        select
            sum(case bd.fquarter when 1 then bd.beds*greatest(months_between(1+least(dtt,to_date('31.03.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('01.01.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')) ),0)
                                 when 2 then bd.beds*greatest(months_between(1+least(dtt,to_date('30.06.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('01.04.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')) ),0)
                                 when 3 then bd.beds*greatest(months_between(1+least(dtt,to_date('30.09.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('01.07.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')) ),0)
                                 when 4 then bd.beds*greatest(months_between(1+least(dtt,to_date('31.12.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('01.10.'||to_char(dtf,'yyyy'),'dd.mm.yyyy')) ),0)
            end)/months_between(dtt+1,dtf)   beds     --среднее количество коек по плану в указанном отделении в году
        from
            stat.bedplan bd
        where
            bd.fyear=to_number(to_char(dtf,'yyyy')) and bd.department_id=Dep_ID
      ) loop
        r:=ii.beds;
      end loop;  
    else  --с 2019 года кварталы считаем с 25 по 26 число, (1й квартал с 25.12.2018 по 26.03.2019)
      for ii in (
        select
            sum(case bd.fquarter when 1 then bd.beds*greatest(months_between(1+least(dtt,to_date('25.03.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('01.01.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')-6) ),0)
                                 when 2 then bd.beds*greatest(months_between(1+least(dtt,to_date('25.06.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('26.03.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')) ),0)
                                 when 3 then bd.beds*greatest(months_between(1+least(dtt,to_date('25.09.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('26.06.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')) ),0)
                                 when 4 then bd.beds*greatest(months_between(1+least(dtt,to_date('25.12.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')), greatest(dtf,to_date('26.09.'||to_char(dtt,'yyyy'),'dd.mm.yyyy')) ),0)
            end)/months_between(dtt+1,dtf)   beds     --среднее количество коек по плану в указанном отделении в указанном периоде
        from
            stat.bedplan bd
        where
            bd.fyear=to_number(to_char(dtt,'yyyy')) and bd.department_id=Dep_ID
      ) loop
        r:=ii.beds;
      end loop;
    end if;  
    return(r);
  end;    
  
--получить количество койкодней для указанной стацкарты, с учетом расчета для дневного стационара, из дат занятия-освобождения койки
  function GetBedDays(HC_ID IN NUMBER) return NUMBER
  is
    r NUMBER default 0;
  begin
    for ii in (select
                 trunc(nvl(hcmout.create_date,sysdate))-trunc(hcmrec.create_date)+decode(hcmrec.department_id,141,1,334,1,339,1,0) BedDays  --ДС радио --ДС РО
               from  
                 hospital.hospital_card hc
                 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id
                             from hospital.hospital_card_movement hcmr
                             where hcmr.state='InDepartment'  --получаем дату занятия койки
                               and not exists( select 1 from hospital.hospital_card_movement hcmx
                                               where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='InDepartment' and hcmx.id<hcmr.id )
                 ) hcmrec on hcmrec.hospital_card_id=hc.id 
                 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id
                             from hospital.hospital_card_movement hcmr
                             where hcmr.state='Discharged'  --получаем дату освобождения койки
                               and not exists( select 1 from hospital.hospital_card_movement hcmx
                                               where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='Discharged' and hcmx.id>hcmr.id )
                 ) hcmout on hcmout.hospital_card_id=hc.id  
               where
                 hc.id=HC_ID ) loop
       r:=ii.BedDays;           
    end loop;  
    return(r);
  end;  
  
--получить количество койконочей в реанимации для указанной стацкарты
--param=0 койконочи целое, param=1 койкодни нецелое, 24 12 2019
  function GetBedDays95(HC_ID in number, param in number default 0) return NUMBER    
  is
    r NUMBER default 0;
  begin
    for ii in (select
                sum(trunc(nvl(hcmou.dout,sysdate))-trunc(hcm.create_date)) bnight,
                sum(nvl(hcmou.dout,sysdate)-hcm.create_date) bdays
              from 
                hospital.hospital_card_movement hcm
                outer apply (
                  select
                      min(hcmx.create_date) dout
                    from
                      hospital.hospital_card_movement hcmx
                   where
                      hcmx.hospital_card_id=hcm.hospital_card_id and hcmx.state in ('InDepartment','Discharged') and hcmx.create_date>hcm.create_date
                ) hcmou
             where 
                hcm.hospital_card_id=HC_ID and hcm.department_id=95 and hcm.state='InDepartment' ) loop
    if param=0 then
      r:=ii.bnight;
    else  
      r:=ii.bdays;
    end if;
    end loop;  
    return(r);
  end;  


--получить ID отделения выписки для указанной стацкарты по отделению освобождения койки  
  function GetOuttakeDepID(HC_ID IN NUMBER) return NUMBER
  is
    r NUMBER default null;
  begin
    for ii in (select
                 hcmout.department_id
               from  
                 hospital.hospital_card hc
/*                 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id
                             from hospital.hospital_card_movement hcmr
                             where hcmr.state='InDepartment'  --получаем дату занятия койки
                               and not exists( select 1 from hospital.hospital_card_movement hcmx
                                               where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='InDepartment' and hcmx.id<hcmr.id )
                 ) hcmrec on hcmrec.hospital_card_id=hc.id */
                 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id
                             from hospital.hospital_card_movement hcmr
                             where hcmr.state='Discharged'  --получаем дату освобождения койки
                               and not exists( select 1 from hospital.hospital_card_movement hcmx
                                               where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='Discharged' and hcmx.id>hcmr.id )
                 ) hcmout on hcmout.hospital_card_id=hc.id  
               where
                 hc.id=HC_ID ) loop
       r:=ii.department_id;           
    end loop;  
    return(r);
  end;
  
--получить ID отделения поступления для указанной стацкарты по отделению занятия койки  
  function GetReceiveDepID(HC_ID IN NUMBER) return NUMBER
  is
    r NUMBER default null;
  begin
    for ii in (select
                 hcmrec.department_id
               from  
                 hospital.hospital_card hc
                 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id
                             from hospital.hospital_card_movement hcmr
                             where hcmr.state='InDepartment'  --получаем дату занятия койки
                               and not exists( select 1 from hospital.hospital_card_movement hcmx
                                               where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='InDepartment' and hcmx.id<hcmr.id )
                 ) hcmrec on hcmrec.hospital_card_id=hc.id 
               where
                 hc.id=HC_ID ) loop
       r:=ii.department_id;           
    end loop;  
    return(r);
  end;  
  
--получить ID отделения в котором стацкарта находится на указанную дату время, anest=1 с учетом нахождения в анестезии
  function GetBusyDepID(HC_ID in number, DD in date default sysdate, Anest in number default 0) return number
  is
    r NUMBER default null;
  begin
    for ii in (select hcm.department_id
      from hospital.hospital_card hc 
           join hospital.hospital_card_movement hcm on hcm.hospital_card_id=hc.id
      where 
            hcm.hospital_card_id=HC_ID
            and trunc(hc.receive_date)<=DD and ( (hc.outtake_date is null and hc.state not in ('Closed','Deleted','Refused')) or hc.outtake_date>=DD)
            and hcm.state in ('InDepartment')                       
            and hcm.create_date<DD
            and hcm.department_id<>decode(anest,0,95,0)  
            --отбираем только последнее событие нахождения в стационаре до даты 
            and not exists (select 1 from hospital.hospital_card_movement hcm2
                            where hcm2.hospital_card_id=hcm.hospital_card_id 
                                  and hcm2.id>hcm.id 
                                  and hcm2.state in ('InDepartment')         
                                  and hcm2.department_id<>decode(anest,0,95,0)
                                  and hcm2.create_date<DD)
            and not exists (select 1 from hospital.hospital_card_movement hcm3
                            where hcm3.hospital_card_id=hcm.hospital_card_id 
                                  and hcm3.id>hcm.id  
                                  and hcm3.state in ('Discharged')
                                  and hcm3.create_date<DD)
     ) loop                              
       r:=ii.department_id;
     end loop;
     return(r);
  end;
  
--получить для указанной стацкарты по дату освобождения койки  
  function GetOuttakeDate(HC_ID IN NUMBER) return DATE
  is
    d DATE default null;
  begin
    for ii in (select
                 hcmout.create_date dd
               from  
                 hospital.hospital_card hc
/*                 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id
                             from hospital.hospital_card_movement hcmr
                             where hcmr.state='InDepartment'  --получаем дату занятия койки
                               and not exists( select 1 from hospital.hospital_card_movement hcmx
                                               where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='InDepartment' and hcmx.id<hcmr.id )
                 ) hcmrec on hcmrec.hospital_card_id=hc.id */
                 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id
                             from hospital.hospital_card_movement hcmr
                             where hcmr.state='Discharged'  --получаем дату освобождения койки
                               and not exists( select 1 from hospital.hospital_card_movement hcmx
                                               where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='Discharged' and hcmx.id>hcmr.id )
                 ) hcmout on hcmout.hospital_card_id=hc.id  
               where
                 hc.id=HC_ID ) loop
       d:=ii.dd;           
    end loop;  
    return(d);
  end;   
  
--получить для указанной стацкарты по дату занятия койки  
  function GetReceiveDate(HC_ID IN NUMBER) return DATE
  is
    d DATE default null;
  begin
    for ii in (select
                 hcmrec.create_date dd
               from  
                 hospital.hospital_card hc
                 left join (select hcmr.create_date, hcmr.hospital_card_id, hcmr.department_id
                             from hospital.hospital_card_movement hcmr
                             where hcmr.state='InDepartment'  --получаем дату занятия койки
                               and not exists( select 1 from hospital.hospital_card_movement hcmx
                                               where hcmx.hospital_card_id=hcmr.hospital_card_id and hcmx.state='InDepartment' and hcmx.id<hcmr.id )
                 ) hcmrec on hcmrec.hospital_card_id=hc.id 
               where
                 hc.id=HC_ID ) loop
       d:=ii.dd;           
    end loop;  
    return(d);
  end;      
  
--Вид оплаты указанного случая, текстом  , для отчетов канцеров
  function GetProjectPayType(P_ID IN NUMBER) return VARCHAR2
  is
    r VARCHAR2(20) default '';
  begin 
    for ii in (select
       (case when cc.certificate_type_id in (1,2) then 'ОМС'
             when cc.certificate_type_id in (3) then 'ДМС'
             when cc.certificate_type_id in (511,530) then 'ЯНАО'
             else 'Платные' end) t
       from hospital.project p, hospital.client_certificate cc 
       where p.id=P_ID and cc.id=p.client_certificate_id ) loop
       r:=ii.t;
    end loop;   
    return(r);  
  end;
  
--Вид оплаты указанной услуги, текстом, которым было назначено либо оплачено 
--so_id не указано или 1 - каким назначено, 2 - каким оплачено
  function GetServicePayType(S_ID IN NUMBER, SO_ID IN NUMBER DEFAULT 2) return VARCHAR2
  is
    r VARCHAR2(50) default '';
  begin 
    for ii in (
     select pt.short_name t
       from hospital.service_operation so
            join hospital.client_certificate cc on cc.id=so.client_certificate_id
            join hospital.client_certificate_type cct on cct.id=cc.certificate_type_id
            join hospital.pay_type pt on pt.id=cct.pay_type_id
      where so.operation_type_id=nvl(SO_ID,2) and so.service_id=S_ID ) loop
       r:=ii.t;
    end loop;   
    return(r);  
  end;  
  
--Получить дату выполнения услуги
  function GetServiceExecDate(S_ID in number) return date
  is
    r date default null;
  begin
    for ii in (
      select
       ro.operation_date d
      from
       hospital.service_operation ro
      where
        ro.service_id=S_ID
        and ro.operation_type_id=4  -- смотрим только события выполнения
        and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=10 and so1.id>ro.id) --нет отмены выполнения
        and not exists (select 1 from hospital.service_operation so2 where so2.service_id=ro.service_id and so2.operation_type_id=4 and so2.id>ro.id)  --только последнее событие выполнения смотрим
    ) loop
      r:=ii.d;
    end loop;    
    return(r);  
  end;       

--Получить дату оплаты услуги
  function GetServicePayDate(S_ID in number) return date
  is
    r date default null;
  begin
    for ii in (
      select
       ro.operation_date d
      from
       hospital.service_operation ro
      where
        ro.service_id=S_ID
        and ro.operation_type_id=2  -- смотрим только события оплаты
        and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=3 and so1.id>ro.id) --нет отмены оплаты
        and not exists (select 1 from hospital.service_operation so2 where so2.service_id=ro.service_id and so2.operation_type_id=2 and so2.id>ro.id)  --только последнее событие оплаты
    ) loop
      r:=ii.d;
    end loop;    
    return(r);  
  end;  
          

--Получить дату назначения услуги
  function GetServiceAppointDate(S_ID in number) return date
  is
    r date default null;
  begin
    for ii in (
      select
       ro.operation_date d
      from
       hospital.service_operation ro
      where
        ro.service_id=S_ID
        and ro.operation_type_id=1  -- смотрим только событие назначения
        and not exists (select 1 from hospital.service_operation so2 where so2.service_id=ro.service_id and so2.operation_type_id=1 and so2.id>ro.id)  --только последнее событие назначения
    ) loop
      r:=ii.d;
    end loop;    
    return(r);  
  end;       

--Получить сумму оплаты услуги
  function GetServicePaySum(S_ID in number) return number
  is
    r number default null;
  begin
    for ii in (
      select
       sum(case when pt.id in (801,802) then tst.price else ro.amount end ) s
      from
       hospital.service_operation ro
       join hospital.service se on se.id=ro.service_id
       join hospital.service_type st on st.id=se.service_type_id
       left join hospital.tfoms_serv_type tst on tst.id=st.tfoms_serv_type       
       left join hospital.client_certificate cc on cc.id=ro.client_certificate_id
       left join hospital.client_certificate_type cct on cct.id=cc.certificate_type_id
       left join hospital.pay_type pt on pt.id=cct.pay_type_id
      where
        ro.service_id=S_ID
        and ro.operation_type_id=2  -- смотрим только события оплаты
        and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=3 and so1.id>ro.id) --нет отмены оплаты
    ) loop
      r:=ii.s;
    end loop;    
    return(r);  
  end;  

--Получить id кем назначена услуга
  function GetServiceAppointWorker(S_ID in number) return number
  is
    r number default null;
  begin
    for ii in (
      select
       ro.worker_id w
      from
       hospital.service_operation ro
      where
        ro.service_id=S_ID
        and ro.operation_type_id=1  -- смотрим только событие назначения
        and not exists (select 1 from hospital.service_operation so2 where so2.service_id=ro.service_id and so2.operation_type_id=1 and so2.id>ro.id)  --только последнее событие назначения
    ) loop
      r:=ii.w;
    end loop;    
    return(r);  
  end;    
  
--Получить id кем оплачена услуга
  function GetServicePayWorker(S_ID in number) return number
  is
    r number default null;
  begin
    for ii in (
      select
       ro.worker_id w
      from
       hospital.service_operation ro
      where
        ro.service_id=S_ID
        and ro.operation_type_id=2  -- смотрим только события оплаты
        and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=3 and so1.id>ro.id) --нет отмены оплаты
        and not exists (select 1 from hospital.service_operation so2 where so2.service_id=ro.service_id and so2.operation_type_id=2 and so2.id>ro.id)  --только последнее событие оплаты
    ) loop
      r:=ii.w;
    end loop;    
    return(r);  
  end;    
  
--Получить id выполнившего услугу
  function GetServiceExecWorker(S_ID in number) return number
  is
    r number default null;
  begin
    for ii in (
      select
       ro.worker_id w
      from
       hospital.service_operation ro
      where
        ro.service_id=S_ID
        and ro.operation_type_id=4  -- смотрим только события выполнения
        and not exists (select 1 from hospital.service_operation so1 where so1.service_id=ro.service_id and so1.operation_type_id=10 and so1.id>ro.id) --нет отмены выполнения
        and not exists (select 1 from hospital.service_operation so2 where so2.service_id=ro.service_id and so2.operation_type_id=4 and so2.id>ro.id)  --только последнее событие выполнения смотрим
    ) loop
      r:=ii.w;
    end loop;    
    return(r);  
  end;    

--Получить список фио ассистентов в услуге
  function GetServiceAssistents(S_ID in number) return varchar2
  is
    r varchar2(4000);
  begin
    for ii in (
      select listagg(x.s,', ') within group(order by x.s) assists 
                     from (
                            select distinct so5.service_id, stat.parep.GetFIOWorker(w5.id) s  --ассистенты
                              from hospital.service_operation so5 join hospital.worker w5 on w5.id=so5.worker_id
                             where so5.service_id=S_ID and so5.operation_type_id=5
                          ) x
              ) loop
      r:=ii.assists;
    end loop;    
    return(r);  
  end;   

/*  
--получить текст из разделов медзаписи для указанной медзаписи и указанного раздела
--с 06 09 2019 не исп.
  function GetMedicalRecordPartTextOld(mr_id number, mrp_id number) return varchar2 
    is
      Result varchar2(32000);
      resultsize number;
      resultlen number;
      curString varchar2(32000);
    begin
      resultsize :=8000;
--  execute immediate 'alter session set cursor_sharing = exact';
      for cur in (WITH t AS
                 (SELECT XMLType(hospital.zlib.decompress(r.text)) xml_field, ms.name
                   FROM hospital.medical_record_part r
                   join hospital.medical_record_section ms on ms.id = r.section_id
                  where r.medical_record_id = mr_id and r.id=mrp_id)
                SELECT t.name, x.text as sec_text
                  FROM t,
                      XMLTable('/*' PASSING xml_field COLUMNS Text XMLType PATH '/*/ --*/*/text()') x) loop
--     curString := cur.name || ': ' || CHR(10) || case when cur.sec_text is null then '(null)' else cur.sec_text.getStringVal() end || CHR(10) || CHR(10);
/*     curString := case when cur.sec_text is null then '' else cur.sec_text.getStringVal() end || CHR(10) || CHR(10);
     curString := substr(curString,1,resultsize);
     resultlen := length(Result);
     if Result is null then
      Result := substr(curString,1,resultsize);
     else
      if(resultlen<resultsize-length(curString)) then
            Result := Result  || curString;
      elsif(resultlen<resultsize) then
        Result:= Result || substr(curString,1,resultsize-resultlen);
      else exit;
      end if;
     end if;
    end loop;
--  execute immediate 'alter session set cursor_sharing = FORCE';
  return(Result);
end;
*/

--получить текст из разделов медзаписи для указанной медзаписи и указанного раздела
--06 09 2019 протасов, упростил, возврат чистого текста без разметки xml, part - номер куска для очень длинных текстов
  function GetMedicalRecordPartText(mr_id number, mrp_id number, part number default 0) return varchar2 
    is
      r varchar2(4000);
    begin
      for cur in (select to_char(substr(x.text,4000*part+1,4000*part+4000)) as sec_text 
                   from hospital.medical_record_part mrp,
                        XMLTable('/*' PASSING XMLType(hospital.zlib.decompress(mrp.text)) COLUMNS Text clob PATH '/*') x
                  where mrp.medical_record_id=mr_id and mrp.id=mrp_id      
                  ) loop
        r:=cur.sec_text;
    end loop;
    return(r);
    exception
      when others then   
        return('Ошибки в структуре xml');
end;

/*
--получить текст протокола операции
--не исп. 26 02 2019
  function GetSurgeryProtocolTextOld(surgery_protocol_id number) return varchar2 
    is
      Result varchar2(4000);
      resultsize number;
      resultlen number;
      curString varchar2(32000);
    begin
      resultsize :=4000;
--  execute immediate 'alter session set cursor_sharing = exact';
      for cur in (WITH t AS
                 (SELECT XMLType(hospital.zlib.decompress(sp.surgery_course)) xml_field , sp.post_surgery_diagnosis name
                   FROM hospital.surgery_protocol sp
                  where sp.id=surgery_protocol_id)
                SELECT t.name, x.text as sec_text
                  FROM t,
                       XMLTable('/*' PASSING xml_field COLUMNS Text XMLType PATH
                                '/*/ --*/*/text()') x) loop
--     curString := cur.name || ': ' || CHR(10) || case when cur.sec_text is null then '(null)' else cur.sec_text.getStringVal() end || CHR(10) || CHR(10);
/*     curString := case when cur.sec_text is null then '' else cur.sec_text.getStringVal() end || CHR(10) || CHR(10);
     curString := substr(curString,1,resultsize);
     resultlen := length(Result);
     if Result is null then
      Result := substr(curString,1,resultsize);
     else
      if(resultlen<resultsize-length(curString)) then
            Result := Result  || curString;
      elsif(resultlen<resultsize) then
        Result:= Result || substr(curString,1,resultsize-resultlen);
      else exit;
      end if;
     end if;
    end loop;
--  execute immediate 'alter session set cursor_sharing = FORCE';
  return(Result);
end;
*/

--получить текст протокола операции, чисто текст 26 02 2019
--27 03 2019 параметр part - номер куска для очень длинных текстов 
  function GetSurgeryProtocolText(surgery_protocol_id number, part number default 0) return varchar2 
  is
      r varchar2(4000);
  begin
    for cur in (WITH t AS
               (SELECT XMLType(hospital.zlib.decompress(sp.surgery_course)) xml_field
                  FROM hospital.surgery_protocol sp
                 where sp.id=surgery_protocol_id)
                SELECT to_char(substr(x.text,4000*part+1,4000*part+4000)) as sec_text
                  FROM t, XMLTable('/*' PASSING xml_field COLUMNS Text clob PATH '/*') x) loop
        r:=cur.sec_text;
    end loop;
    return(r);
    exception
      when others then   
        return('Текст неверен');
  end;

--дешифровка ХБС
  function GetHBS(SSIN IN VARCHAR2) return VARCHAR2
  is
    SSOUT VARCHAR2(4000);
  begin
    SSOUT:=SSIN;
    SSOUT:=replace(SSOUT,'CPS0','ХБС0');
    SSOUT:=replace(SSOUT,'CPS1','ХБС1');
    SSOUT:=replace(SSOUT,'CPS2','ХБС2');
    SSOUT:=replace(SSOUT,'CPS3','ХБС3');
    SSOUT:=replace(SSOUT,'CPS4','ХБС4');
    return(SSOUT);
  end;  
  
--Получить перечень строкой назаначенных препаратов в указанной канцер-выписке
--22 02 2019
--ChemoTherapeutic - только химио
--HormoneImmuneTherapeutic - только гормоно
--Targeted - только таргетная
--null - все
--EMK - список выполненных препаратов из ЭМК
--EMK noexec - список в том числе невыполненных из ЭМК
  function GetCancerListDrugs(cas_id in number, typ varchar2 default null) return varchar2
  is 
    ssout varchar2(4000) default '';
    x number default 0;
  begin
   if typ||' ' not in ('EMK ','EMK noexec ') then
    for ii in (
       select --distinct
--         fdch1.code cc,
         initcap(decode(fdch1.name,
          null, 'неуказан',
          'Jm-8 (карбоплатин)','Карбоплатин',
          'ДДП (цисплатин)','Цисплатин',
          'СТХ (циклофосфан)','Циклофосфан',
          '5-FU (фторурацил)','Фторурацил',
          'НN2  (эмбихин)','Эмбихин',
          '6-МР (меркаптопурин)','Меркаптопурин',
          'CDDP  (цисплатин)','Цисплатин',
          'DDP  (цисплатин)','Цисплатин',
          'CCNU (Ломустин)','Ломустин',
          'DTIC  (дакарбазин)','Дакарбазин',
          'FT  (фторафур)','Фторафур',
          'VCR  (винкристин)','Винкристин',
          'VLB  (винбластин)','Винбластин',
          'ЕС 145','ЕС145',
          'МЕSNА (уромитексан)','Уромитексан',
          'Кальциумофолиант-EBEWE (Calciumfolinat EBEWE - лейковорин)','лейковорин',
          fdch1.name)) nn
       from  
         hospital.cancer_sum_drug_treat csdtch1 
         left join hospital.cancer_register_dictionary fdch1 on fdch1.id=csdtch1.federal_drug_id and (fdch1.dictionary_type='Drugs' or fdch1.dictionary_type='UserPrep')   --Федеральный препарат
       where
         csdtch1.cancer_summary_id=cas_id 
         and (csdtch1.drug_treatment_type=typ or typ is null)
       order by
         nn  
    ) loop
      x:=instr(ii.nn,' ');
      if x=0 then 
        x:=instr(ii.nn,'(');
      end if;
      if x=0 then 
        x:=20;
      end if;
      if instr(ssout||' ',substr(ii.nn,1,x-1))=0 then
        ssout:=ssout||' '||substr(ii.nn,1,x-1);
      end if;  
    end loop;
    ssout:=initcap(ltrim(ssout));
   else
    for ii in (
      select distinct
       cas.id,
       mr.project_id,
       dde.name
      from
       hospital.cancer_summary cas
       join hospital.hospital_card hc on hc.id=cas.hospital_card_id  
       join hospital.medical_record mr on mr.project_id=hc.project_id
       join hospital.appointment a on a.medical_record_id=mr.id
       join hospital.drug_appointment da on da.appointment_id=a.id
       join hospital.prescribed_drug pd on pd.id=da.prescribed_drug_id
       join hospital.drug_description dde on dde.id=pd.drug_id
      where
       cas.id=cas_id
       and (typ='EMK noexec' or exists (select 1 from hospital.appointment_task atas where atas.appointment_id=a.id and atas.execute_worker_id is not null)) --только выполненные
      order by
       dde.name
     ) loop
       ssout:=ssout||' '||ii.name;
     end loop;      
   end if;       
   return(ssout);
  end;  
  
--порядковый номер для стандартного порядка отделений-стационаров
  function GetDepOrder(dep_id in number) return number
  is
   r number default null;
  begin
    case dep_id 
      when 122 then r:=1;
      when 138 then r:=2;
      when 142 then r:=3;
      when 143 then r:=4;
      when 139 then r:=5;
      when 140 then r:=6;
      when 97 then r:=7;
      when 145 then r:=8;
      when 146 then r:=9;
      when 77 then r:=10;
      when 95 then r:=11;
      when 141 then r:=12;
      when 334 then r:=13;
      when 339 then r:=14;
    else 
      r:=null;
    end case;
    return r;  
  end;
  
--костыль. подмена id врача на id с тем же фио, но из стационара
  function SubstWorkerToStac(w_id in number) return number
  is
   r number;
  begin
    r:=SubstWorkerToStac(w_id, 0);
    return r;  
  end;      

  function SubstWorkerToStac(w_id in number, ds in number) return number
  is
   r number;
  begin
    r:=w_id;
    if ds=1 then  --только дневной стационар
    for ii in (select w1.id
                from hospital.worker w1, hospital.worker w, hospital.staff stf
                where w.id=w_id
                      and w1.sur_name=w.sur_name and w1.first_name=w.first_name and w1.patr_name=w.patr_name 
                      and stf.id=w1.staff_id  and stf.department_id in (141,334,339)
              ) loop
      r:=ii.id;
    end loop;  
    end if;
    if ds=0 then
    for ii in (select w1.id
                from hospital.worker w1, hospital.worker w, hospital.staff stf
                where w.id=w_id
                      and w1.sur_name=w.sur_name and w1.first_name=w.first_name and w1.patr_name=w.patr_name 
                      and stf.id=w1.staff_id  and stf.department_id in (138,142,143,97,139,140,122,145,146,77, 141,334,339)
                order by
                      stat.parep.GetDepOrder(stat.parep.GetWorkerDepID(w1.id)) desc, w1.id
              ) loop      
      r:=ii.id;
    end loop;
    end if;  
    return r;  
  end;   
  
--вернуть список диагнозов для раздела из таблицы FORMGROUPMKB для отображения в отчете форма 14
  function GetFormGroupMKBs(groupcode in varchar2, formname in varchar2 default 'FORM14') return varchar2
  is
   s varchar2(4000) default null;
  begin
    for ii in (select gr.mkbfrom, gr.mkbto 
                 from stat.formgroupmkb gr 
                where gr.fgroupcode=groupcode  and gr.fform=formname
             order by gr.mkbfrom) loop
      if s is null then s:=ii.mkbfrom; else s:=s||','||ii.mkbfrom; end if;
      if ii.mkbto<>ii.mkbfrom then s:=s||'-'||ii.mkbto; end if;
    end loop;
    return(s);
  end; 
--раздвинуть код из таблицы FORMGROUPMKB для отображения в отчете форма 14 для упорядочивания
  function GetFormGroupOrder(groupcode in varchar2) return varchar2
  is
   s varchar2(4000) default null;
  begin
    s:=groupcode||'.'; 
    if instr(s,'.',1,1)=2 then s:='0'||s; end if;
    if instr(s,'.',1,2)=5 then s:=substr(s,1,3)||'0'||substr(s,4); end if;
    if instr(s,'.',1,3)=8 then s:=substr(s,1,6)||'0'||substr(s,7); end if;
    if instr(s,'.',1,4)=11 then s:=substr(s,1,9)||'0'||substr(s,10); end if;
    if instr(s,'.',1,5)=14 then s:=substr(s,1,12)||'0'||substr(s,13); end if;
    return(s);
  end;   
  
--вернуть список групп, к которым отнесен данный федеральный код операции
  function GetFedGroups(surgerycode in varchar2, formname in varchar2 default 'FORM14') return varchar2
  is
   s varchar2(4000) default null;
  begin
    for ii in (
      select
        listagg(sgs.grcode, '; ') WITHIN GROUP(order by sgs.grcode) r
      from
       stat.surgerygroups sgs 
      where
       sgs.grform=formname and sgs.scode=surgerycode
    ) loop   
      s:=ii.r;
    end loop;   
    return(s);
  end; 
  
  
--подбор подходящего адреса из справочника адресов из названия улицы, под справочник адреса-поликлиники
  function LoremOratioApta(streetname in varchar2) return varchar2
  is
   s varchar2(4000) default null;
  begin
   if instr(streetname,'/')>0 and instr(streetname,'/',1,2)>0 then  --адрес с населенным пунктом
    for ii in (
      select a.full_name from hospital.address a 
       where (a.full_name like 'Тюменская обл., Тюмень г.%' or a.full_name like 'Россия, обл. Тюменская, г. Тюмень%')
        and (a.full_name like '% п.%' or a.full_name like '% пгт.%' or a.full_name like '% снт.%' or a.full_name like '% д.%' or a.full_name like '% с.%') 
        and upper(a.full_name) like upper('%'||substr(streetname,instr(streetname,'/')+1,instr(streetname,'/',1,2)-instr(streetname,'/')-1)||'%') --поселок
        and (upper(a.full_name) like upper('%'||trim(substr(streetname,1,instr(streetname,'/')-1))||'%')  --улица 
             or 
             upper(a.name_with_type_revers) like upper(trim(substr(streetname,1,instr(streetname,'/')-1))||'%') )
             
    ) loop
      if (length(ii.full_name)<length(s))or(s is null) then
        s:=ii.full_name;
      end if;  
      end loop;
   else   --адрес только улица
    for ii in (
      select a.full_name from hospital.address a 
       where (a.full_name like 'Тюменская обл., Тюмень г.%' or a.full_name like 'Россия, обл. Тюменская, г. Тюмень%') and 
             (upper(a.full_name) like upper('%'||streetname||'%') 
              or upper(a.name_with_type_revers) like upper(streetname||'%') )
               
    ) loop
      if (length(ii.full_name)<length(s))or(s is null) then
        s:=ii.full_name;
      end if;  
      end loop;            
   end if; 
   return(s);
  end;   
  

--получить список отделений стационаров выписывающих
--0=круглосуточные, 1=дневные, 2=все
  function GetListDep(ds number default 2) return tblDepID 
  pipelined  
  is
  begin 
    for curr in
    (  
    select d.id, d.name, GetShortDepname(d.id) shortname, GetDepOrder(d.id) ordernum ,decode(instr(d.name,'Дневной'),0,'Круглосуточный стационар','Дневной стационар')
      from hospital.department d
     where (d.id in (138,142,143,97,139,140,122,145,146,77) and ds in (0,2)) or
           (d.id in (141,334,339) and ds in (1,2))  
     order by ordernum      
    ) loop
    pipe row (curr);
    end loop;  
  end;    
  
--получить вид анестезии 
  function GetAnesthesiaType(a_id number) return varchar2
  is
    r varchar2(4000);
  begin
    for cur in (select at.name
                  from hospital.anesthesia_anesth_type aat, hospital.anesthesia_type at 
                 where aat.anesthesia_id=a_id and at.id=aat.type_id) loop
      if r is not null then r:=r||', '; end if;
      r:=r||cur.name;           
    end loop;             
    return(r);
  end;
  
--получить осложнения анестезии 
  function GetAnesthesiaComplic(a_id number) return varchar2
  is
    r varchar2(4000);
  begin
    for cur in (select t.name
                  from hospital.anesthesia_anesth_complic a, hospital.anesthesia_complication t 
                 where a.anesthesia_id=a_id and t.id=a.complication_id and t.id<>21) loop
      if r is not null then r:=r||', '; end if;
      r:=r||cur.name;           
    end loop;             
    return(r);
  end;  
  
--получить особености послеоперационного периода анестезии 
  function GetAnesthesiaPosfea(a_id number) return varchar2
  is
    r varchar2(4000);
  begin
    for cur in (select t.name
                  from hospital.anesthesia_anesth_posfea a, hospital.postsurgery_feature t 
                 where a.anesthesia_id=a_id and t.id=a.postfeat_id) loop
      if r is not null then r:=r||', '; end if;
      r:=r||cur.name;           
    end loop;             
    return(r);
  end;    

--получить сопутсвующие заболевания анестезии 
  function GetAnesthesiaConcom(a_id number) return varchar2
  is
    r varchar2(4000);
  begin
    for cur in (select t.name
                  from hospital.anesthesia_concomitant a, hospital.anesthesia_related_disease t 
                 where a.anesthesia_id=a_id and t.id=a.disease_id) loop
      if r is not null then r:=r||', '; end if;
      r:=r||cur.name;           
    end loop;             
    return(r);
  end;   
  
--найти ид первой выполненной услуги у пациента от указанной даты с кодом scode
  function GetClientFirstService(cl_id in number, d in date default to_date('0001','yyyy'), scode in varchar2 default '%') return number
  is
   r number;
  begin
    for ii in ( select so.service_id 
                from hospital.service_operation so
                where so.id=
                ( 
                select 
                 min(so.id)
                from
                 hospital.service s
                 join hospital.project p on p.id=s.project_id
                -- join hospital.client cl on cl.id=nvl(p.client_id,s.client_id)  --для услуг без случая, медленно, не нужно
                 join hospital.client cl on cl.id=p.client_id
                 join hospital.service_type st on st.id=s.service_type_id
                 join hospital.service_operation so on so.service_id=s.id
                where
                 cl.id=cl_id  --для пациента
                 and so.operation_date>=d  --от даты
                 and st.code like (scode) --фильтр по коду услуги
                 and so.operation_type_id=4  -- смотрим только события выполнения
                 and not exists (select 1 from hospital.service_operation so1 where so1.service_id=so.service_id and so1.operation_type_id=10 and so1.id>so.id) --нет отмены выполнения
                 and not exists (select 1 from hospital.service_operation so2 where so2.service_id=so.service_id and so2.operation_type_id=4 and so2.id>so.id)  --только последнее событие выполнения смотрим
                )
              ) loop
      r:=ii.service_id;        
    end loop;            
    return r;  
  end;     
  
--найти ид последней выполненной услуги у пациента до указанной даты с кодом scode
  function GetClientLastService(cl_id in number, d in date default to_date('9999','yyyy'), scode in varchar2 default '%') return number
  is
   r number;
  begin
    for ii in ( select so.service_id 
                from hospital.service_operation so
                where so.id=
                ( 
                select 
                 max(so.id)
                from
                 hospital.service s
                 left join hospital.project p on p.id=s.project_id
                -- join hospital.client cl on cl.id=nvl(p.client_id,s.client_id)  --для услуг без случая, медленно, не нужно
                 join hospital.client cl on cl.id=p.client_id
                 join hospital.service_type st on st.id=s.service_type_id
                 join hospital.service_operation so on so.service_id=s.id
                where
                 cl.id=cl_id  --для пациента
                 and so.operation_date<=d  --до даты
                 and st.code like (scode) --фильтр по коду услуги
                 and so.operation_type_id=4  -- смотрим только события выполнения
                 and not exists (select 1 from hospital.service_operation so1 where so1.service_id=so.service_id and so1.operation_type_id=10 and so1.id>so.id) --нет отмены выполнения
                 and not exists (select 1 from hospital.service_operation so2 where so2.service_id=so.service_id and so2.operation_type_id=4 and so2.id>so.id)  --только последнее событие выполнения смотрим
                )
              ) loop
      r:=ii.service_id;        
    end loop;            
    return r;  
  end;      
  
--получить ид поликлиники из строки адреса, (ид из hospital.cancer_register_dict_med_org)
  function GetCancerPolyclinicID(address in varchar2) return number
  is 
     r number default null;
     adr varchar2(4000) default null;
     ul varchar2(4000) default null;
     dom varchar2(4000) default null;
  begin
     adr:=replace(address,'  д.',', д.');
     adr:=replace(adr,', кв.',' кв.');
     adr:=replace(adr,', кор.',' корп.');
     ul:=upper(substr(adr, 1, instr(adr,', д.',-1)-1 ));
     dom:=regexp_substr(substr(adr,instr(adr,', д.',-1)+4), '[^ ]+');
     for ii in (select ap.house_start, ap.house_end, ap.med_org_id 
                  from hospital.cancer_bind_fed_address ap
                 where upper(ap.address_area||', '||ap.address_city||', '||ap.address_street)=ul 
                       and ( (lpad(dom,4,'0') between lpad(ap.house_start,4,'0') and lpad(ap.house_end,4,'0') and regexp_replace(dom,'(\D)','')=dom  )  --если номер дома только цифры
                              or upper(dom)=upper(ap.house_start) )
                ) loop
        r:=ii.med_org_id;     
     end loop;         
     return r;
  end;  

--получить имя поликлиники из справочника канцеров по ид
  function GetCancerPolyclinic(med_org_id in number) return varchar2
  is 
    r varchar2(4000) default null;
  begin
    for ii in (select mo.name
                 from hospital.cancer_register_dict_med_org mo
                where mo.id=med_org_id ) loop
      r:=trim(ii.name);
    end loop;            
    return(r);
  end;   

--получить имя последней направившей МО у указанного пациента из электронного либо бумажного направления
--dtt дата по которую смотрим направления 
  function GetDirectPolyclinic(cl_id in number, dtt in date default to_date('9999','yyyy')) return varchar2
  is 
    r varchar2(4000) default null;
  begin
    for ii in (--список направлений 
        select
         od.client_id client_id, od.create_date di_date, mo.name di_mo, 'Эле' di_typ
        from 
         hospital.outer_direction od
         join hospital.outer_direction_med_org mo on mo.code=od.mo_code
        where
         od.client_id=cl_id and trunc(od.create_date)<=dtt
        union all 
        select
         p.client_id, dr.direction_date, o.name, 'Бум' di_typ
        from
         hospital.direction dr
         join hospital.service s on s.direction_id=dr.id
         join hospital.project p on p.id=s.project_id
         join hospital.organisation o on o.id=dr.organisation_id
        where
         o.id<>1 and p.client_id=cl_id and trunc(dr.direction_date)<=dtt
        order by
         di_date desc 
      ) loop
      r:=trim(ii.di_mo);
      exit; --вернем последнее по дате
    end loop;            
    return(r);
  end;   
  
--получить дату последнего направления у указанного пациента из электронного либо бумажного направления
--dtt дата по которую смотрим направления 
  function GetDirectDate(cl_id in number, dtt in date default to_date('9999','yyyy')) return date
  is 
    r date default null;
  begin
    for ii in (--список направлений 
        select
         od.client_id client_id, od.create_date di_date, mo.name di_mo, 'Эле' di_typ
        from 
         hospital.outer_direction od
         join hospital.outer_direction_med_org mo on mo.code=od.mo_code
        where
         od.client_id=cl_id and trunc(od.create_date)<=dtt
        union all 
        select
         p.client_id, dr.direction_date, o.name, 'Бум' di_typ
        from
         hospital.direction dr
         join hospital.service s on s.direction_id=dr.id
         join hospital.project p on p.id=s.project_id
         join hospital.organisation o on o.id=dr.organisation_id
        where
         o.id<>1 and p.client_id=cl_id and trunc(dr.direction_date)<=dtt
         and dr.direction_date<>to_date('01.01.0001','dd.mm.yyyy')
        order by
         di_date desc 
      ) loop
      r:=ii.di_date;
      exit; --вернем последнее по дате
    end loop;            
    return(r);
  end;  

  
--получить текстом вид лечения из канцер-документа по ид стацкарты
  function GetCancerTreatment(hc_id in number) return varchar2
  is 
    r varchar2(4000) default null;
  begin
    for ii in (select 
                (case
                   when csurgery.cnt is null and crad.cnt is null and cdrug.cnt is not null then 'только лекарственная'
                   when csurgery.cnt is not null and crad.cnt is null and cdrug.cnt is null then 'только операция'
                   when csurgery.cnt is null and crad.cnt is not null and cdrug.cnt is null then 'только лучевое'
                   when csurgery.cnt is not null and crad.cnt is null and cdrug.cnt is not null then 'операция и лекарственная'
                   when csurgery.cnt is not null and crad.cnt is not null and cdrug.cnt is null then 'операция и лучевое'
                   when csurgery.cnt is null and crad.cnt is not null and cdrug.cnt is not null then 'лекарственная и лучевое'
                   when csurgery.cnt is not null and crad.cnt is not null and cdrug.cnt is not null then 'операция и лекарственная и лучевое'
                   else 'без специального'
                 end) tr
                 from 
                   hospital.hospital_card hc 
                   join hospital.cancer_summary cas on cas.hospital_card_id=hc.id
                   --хирургическое лечение из стацкарты
                   left join (select s.project_id project_id, count(s.id) cnt 
                              from hospital.surgery s
                              where s.execute_state='Done'
                              group by s.project_id
                             ) csurgery on csurgery.project_id=hc.project_id
                   --лучевое лечение
                   left join (select csrt.cancer_summary_id cancer_summary_id, count(csrt.id) cnt
                              from hospital.cancer_sum_rad_treat_meth csrt
                              group by csrt.cancer_summary_id
                             ) crad on crad.cancer_summary_id=cas.id
                   --лекарственное лечение
                   left join (select csdt.cancer_summary_id cancer_summary_id, count(csdt.id) cnt
                              from hospital.cancer_sum_drug_treat csdt
                              group by csdt.cancer_summary_id
                              ) cdrug on cdrug.cancer_summary_id=cas.id
                where 
                   hc.id=hc_id ) loop
      r:=ii.tr;
    end loop;            
    return(r);
  end;   

/*
--так медленно слишком  
--получить текстом группу отнесения стацкарты, для универсальных отчетов
  function GetHCGroup(hc_id in number, vGroup in varchar2) return varchar2
  is
    r varchar2(4000) default null;
  begin
    for ii in (select (case 
           when vGroup='Пациент' then stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')
           when vGroup='Стацкарта' then hc.num||' с '||to_char(hc.receive_date,'dd.mm.yyyy')||' по '||to_char(hc.outtake_date,'dd.mm.yyyy')||' '||stat.parep.GetFIOClient(cl.id)||' '||to_char(cl.birthday,'dd.mm.yyyy')||' случай '||to_char(p.id)||' '||stat.parep.GetProjectMKBCode(1,p.id)
           when vGroup='Территория проживания' then stat.parep.GetTerritory(stat.parep.GetClientLiveAddress(cl.id))
           when vGroup='Регион проживания' then ltrim(stat.parep.GetTerritoryRegion(stat.parep.GetClientLiveAddress(cl.id)))
           when vGroup='Поликлиника' then stat.parep.GetCancerPolyclinic(stat.parep.GetCancerPolyclinicID(stat.parep.GetClientLiveAddress(cl.id)))
           when vGroup='Пол' then decode(cl.sex,'Ж','Женщины','М','Мужчины','Неопределен')
           when vGroup='Возраст' then 'Возраст '||to_char(stat.parep.GetClientAge(cl.id,hc.outtake_date),'00' )
           when vGroup='Трудоспособность' then (case when stat.parep.GetClientAge(cl.id,hc.outtake_date)<1 then 'Возраст до 1 года'
                                                      when stat.parep.GetClientAge(cl.id,hc.outtake_date)<18 then 'Возраст до 18 лет'
                                                      when stat.parep.GetClientIsPensioner(cl.id,hc.outtake_date)=1 then 'Старше трудоспособного возраста'
                                                 else 'Трудоспособный' end)
           when vGroup='Инвалидность' then (select it.name from hospital.invalidity_type it where it.id=cl.invalidity_id)  
           when vGroup='Этническая группа' then (select eg.name from hospital.ethnic_group eg where eg.id=cl.ethnic_group)
           when vGroup='Социально-профессиональная группа' then (select sg.name from hospital.social_prof_group sg where sg.id=cl.profession)
           when vGroup='Гражданство' then (select cz.fullname from hospital.citizenship cz where cz.id=cl.citizenship_id)
           when vGroup='Умерший' then decode(p.project_result_type2_id, -34, 'Мертвые', -25, 'Мертвые', 'Живые') 
           when vGroup='Номер госпитализации' then (select 'Госпитализация номер'||to_char(count(hc1.id),'00') from hospital.hospital_card hc1 where hc1.client_id=cl.id and hc1.state  not in ('Deleted','Refused') and hc1.outtake_date<=hc.outtake_date)
           when vGroup='Лечащий врач' then stat.parep.GetFIOWorker(p.worker_id)||' '||stat.parep.GetWorkerSpeciality(p.worker_id)
           when vGroup='Отделение' then to_char(stat.parep.GetDepOrder(stat.parep.GetOuttakeDepID(hc.id)),'00')||' '||stat.parep.GetDepname(stat.parep.GetOuttakeDepID(hc.id))
           when vGroup='Результат лечения в выписке' then (select stat.parep.GetCancerTreatmentResult(cas.hosp_treat_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
           when vGroup='Характер лечения в выписке' then (select stat.parep.GetCancerHospitalizationResult(cas.hospitalization_resid_result) from hospital.cancer_summary cas where cas.hospital_card_id=hc.id)
           when vGroup='Диагноз' then (select substr(mkb.code,1,3)||' '||m.n
                                          from hospital.disease dis
                                               left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                               left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkb.code,1,3)
                                         where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6) 
                                               and not exists (select 1 from hospital.disease disx where
                                                               disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )
           when vGroup='Клиническая группа' then (select 'Клиническая группа '||cg.name
                                          from hospital.disease dis
                                               left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                               left join hospital.cancer_clinic_group cg on cg.id=od.cancer_clinic_group_id
                                         where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6) 
                                               and not exists (select 1 from hospital.disease disx where
                                                               disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )        
           when vGroup='Стадия опухоли' then (select stat.parep.GetCancerStage(od.cancer_stage_value)
                                          from hospital.disease dis
                                               left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                         where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6) 
                                               and not exists (select 1 from hospital.disease disx where
                                                               disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )     
           when vGroup='Морфологический тип опухоли' then (select t.code||' '||t.name
                                          from hospital.disease dis
                                               left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                               left join hospital.cancer_type t on t.id=od.cancer_type_id
                                         where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6) 
                                               and not exists (select 1 from hospital.disease disx where
                                                               disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )         
           when vGroup='TNM' then (select 'T'||od.tnm_t||' N'||od.tnm_n||' M'||od.tnm_m
                                          from hospital.disease dis
                                               left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                         where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6) 
                                               and not exists (select 1 from hospital.disease disx where
                                                               disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )        
           when vGroup='Локализации метастазов' then (select stat.parep.GetCancerMetastasisAreas(od.metastasis_areas)
                                          from hospital.disease dis
                                               left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                         where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6) 
                                               and not exists (select 1 from hospital.disease disx where
                                                               disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )  
           when vGroup='Метод подтверждения' then (select stat.parep.GetCancerConfirmMethods(od.disease_confirm_methods)
                                          from hospital.disease dis
                                               left join hospital.oncologic_disease od on od.id=dis.oncologic_disease_id
                                         where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6) 
                                               and not exists (select 1 from hospital.disease disx where
                                                               disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id) )                                                             
           when vGroup='Диагноз в выписке' then (select substr(mkbcrd.code,1,3)||' '||m.n
                                                    from hospital.cancer_summary cas 
                                                         left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                         left join hospital.mkb mkbcrd on mkbcrd.id=crd.mkb_id
                                                         left join (select max(m.name) n, m.code c from hospital.mkb m where length(m.code)=3 group by m.code) m on m.c=substr(mkbcrd.code,1,3)
                                                   where cas.hospital_card_id=hc.id)
           when vGroup='Клиническая группа в выписке' then (select 'Клиническая группа в выписке '||cg.name
                                                               from hospital.cancer_summary cas 
                                                                    left join hospital.cancer_clinic_group cg on cg.id=cas.cancer_clinic_group_id
                                                              where cas.hospital_card_id=hc.id)    
           when vGroup='Стадия опухоли в выписке' then (select stat.parep.GetCancerStage(cas.cancer_stage)
                                                               from hospital.cancer_summary cas 
                                                              where cas.hospital_card_id=hc.id)                                                                                                       
           when vGroup='Морфологический тип опухоли в выписке' then (select ct.code||' '||ct.name
                                                                        from hospital.cancer_summary cas 
                                                                             left join hospital.cancer_type ct on ct.id=cas.cancer_type_id
                                                                       where cas.hospital_card_id=hc.id)   
           when vGroup='TNM в выписке' then (select 'T'||cas.tnm_t||' N'||cas.tnm_n||' M'||cas.tnm_m
                                                from hospital.cancer_summary cas 
                                               where cas.hospital_card_id=hc.id)      
           when vGroup='Локализации метастазов в выписке' then (select stat.parep.GetCancerMetastasisAreas(cas.metastasis_areas)
                                                                   from hospital.cancer_summary cas 
                                                                  where cas.hospital_card_id=hc.id)      
           when vGroup='Метод подтверждения в выписке' then (select stat.parep.GetCancerConfirmMethods(cas.disease_confirm_methods)
                                                                from hospital.cancer_summary cas 
                                                               where cas.hospital_card_id=hc.id)  
           when vGroup='Вид диагноза' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                         when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                    else 'Неопухолевый диагноз' end
                                               from hospital.disease dis left join hospital.mkb mkb on mkb.id=dis.mkb_id
                                              where dis.project_id=p.id and dis.diagnosis_type_id in (-4,-6) 
                                                    and not exists (select 1 from hospital.disease disx where disx.project_id=dis.project_id and disx.diagnosis_type_id in (-4,-6) and disx.id>dis.id)
                                             )       
           when vGroup='Вид диагноза по выписке' then (select case when (substr(mkb.code,1,1)='C' or substr(mkb.code,1,2)='D0') then 'Злокачественное новообразование'
                                                                    when (substr(mkb.code,1,2) in ('D1','D2','D3','D4','D5','D6','D7','D8','D9') and substr(mkb.code,1,3)<>'D86') then 'Доброкачественное новообразование'
                                                               else 'Неопухолевый диагноз' end  
                                                          from hospital.cancer_summary cas 
                                                               left join hospital.cancer_register_document crd on crd.id=cas.document_id
                                                               left join hospital.mkb mkb on mkb.id=crd.mkb_id
                                                         where cas.hospital_card_id=hc.id
                                                        )    
           when vGroup='Лечение' then stat.parep.GetCancerTreatment(hc.id) 
           when vGroup='Вид оплаты' then stat.parep.GetProjectPayType(p.id)
           when vGroup='Страховая компания' then (select o.name
                                                     from hospital.client_certificate cc left join hospital.organisation o on o.id=cc.organization_id
                                                    where cc.id=p.client_certificate_id )
           when vGroup='КСГ' then (select csg.code||' '||csg.name
                                      from hospital.project_clinic_stat_group pcsg left join hospital.clinical_statistic_group csg on csg.id=pcsg.group_id 
                                     where pcsg.project_id=p.id)
           when vGroup='Лекарственная схема' then (select sh.code||' '||sh.mnn_drugs
                                                      from hospital.project_clinic_stat_group pcsg left join hospital.register_drug_schema sh on sh.id=pcsg.drug_schema_id
                                                     where pcsg.project_id=p.id)    
           when vGroup='Комбинации препаратов химиолечения' then (select stat.parep.GetCancerListDrugs(cas.id,'ChemoTherapeutic')
                                                                  from hospital.cancer_summary cas 
                                                                 where cas.hospital_card_id=hc.id)
           when vGroup='Применённые препараты' then (select stat.parep.GetCancerListDrugs(cas.id,'EMK')
                                                                  from hospital.cancer_summary cas 
                                                                 where cas.hospital_card_id=hc.id)       
           when vGroup='Хирургические операции' then (select listagg(decode(st.id,null,'нет услуги',st.code||' '||substr(st.name,1,100)), ', ') WITHIN GROUP(order by s.start_date, s.id) text
                                                                 from hospital.surgery s
                                                                      left join hospital.service_type st on st.id=s.service_type_id 
                                                                where s.project_id=p.id and s.execute_state='Done'
                                                               group by s.project_id)                                                      
           when vGroup='Хирургические операции из выписок' then (select listagg(decode(cst.id,null,'нет кода',cst.code||' '||substr(cst.name,1,100)), ', ') WITHIN GROUP(order by csst.start_date, csst.surgery_id, csst.id) text
                                                                 from hospital.cancer_summary cas 
                                                                      join hospital.cancer_sum_surgery_treat csst on csst.cancer_summary_id=cas.id
                                                                      left join hospital.cancer_surgery_type cst on cst.id=csst.surgery_type_id
                                                                where cas.hospital_card_id=hc.id
                                                               group by csst.cancer_summary_id)
           when vGroup='Лучевые воздействия из выписок' then (select listagg(ra1.name||' '||crtm1.summary_dose, ', ') WITHIN GROUP(order by ra1.name) text
                                                                       from hospital.cancer_summary cas 
                                                                            join hospital.cancer_sum_rad_treat_meth crtm1 on crtm1.cancer_summary_id=cas.id
                                                                            left join hospital.radiation_area ra1 on ra1.id=crtm1.area_id
                                                                      where cas.hospital_card_id=hc.id
                                                                     group by crtm1.cancer_summary_id)     
           when vGroup='Перечень выполненых услуг' then (select listagg(c, ', ') WITHIN GROUP(order by c) text
                                                            from(select distinct st.code c
                                                                 from hospital.service s
                                                                      left join hospital.service_type st on st.id=s.service_type_id 
                                                                where s.project_id=p.id and stat.parep.GetServiceExecDate(s.id) is not null) )                                                                                                                         
      else null end) t  
    from
     hospital.hospital_card hc, hospital.project p, hospital.client cl
    where
     hc.id=hc_id and p.id=hc.project_id and cl.id=p.client_id 
    ) loop
      r:=ii.t;
    end loop;            
    return(r); 
  end;      
*/

--получить перечень выполненных препаратов в случае
--v=type - тип препарата из паруса, v=name - имя препарата как в парусе, v=mnn - МНН препарата из паруса
  function GetDrugs(p_id in number, v in varchar2 default 'name') return varchar2
  is
    r varchar2(4000) default '';
    z varchar2(4000) default '';
  begin
    for ii in (select case
                       when v='name' then dd.name
--                       when v='mnn'  then dd.parusmnn
--                       when v='type' then dd.parustype
--                       when v='mnn' then (select vpd.smn_name from Parus.V_P8TOMIS_MODIFDC@Parus vpd where vpd.nrn=dd.outer_drug_id)
--                       when v='type' then (select vpd.smed_type from Parus.V_P8TOMIS_MODIFDC@Parus vpd where vpd.nrn=dd.outer_drug_id)  
                       when v='mnn' then (select mdd.parusmnn from stat.mv_drug_description mdd where mdd.id=dd.id)
                       when v='type' then (select mdd.parustype from stat.mv_drug_description mdd where mdd.id=dd.id)  
                      end text
                from 
                  hospital.appointment a
                  join hospital.drug_appointment da on da.appointment_id = a.id
                  join hospital.prescribed_drug pd on da.prescribed_drug_id = pd.id
                  join hospital.drug_description dd on pd.drug_id = dd.id
--                  join stat.mv_drug_description dd on pd.drug_id = dd.id
                where 
                  a.project_id=p_id --and a.state <> 'Cancelled'
                  and exists (select 1 from hospital.appointment_task atas where atas.appointment_id=a.id and atas.execute_date is not null)
                order by text
               ) loop 
      z:=ii.text;
      if r is null then 
        r:=z;
      else
        if instr(r,z)=0 then r:=r||', '||z; end if;    
      end if;   
    end loop;  
    return(r);
  end;
  
--получить перечень препаратов списаных в Парус на этого пациента в период лежания в стационаре в указанной стацкарте
--hc_id  ИД_стацкарты,  groupst перечень групп препаратов, пример 'НАРКОТИКИ СИЛЬНОДЕЙСТВУЮЩИЕ'
  function GetDrugsParus(hc_id in number, groupst in varchar2 default '') return varchar2  
  is
    r varchar2(4000) default '';
  begin
    for ii in (select distinct spi.snomenname
                 from hospital.hospital_card hc, stat.mv_mis_spismedpecs spi
                where hc.id=hc_id
                      and spi.client_id=hc.client_id
                      and spi.dwork_date between trunc(hc.receive_date) and trunc(nvl(hc.outtake_date,sysdate))+4
                      and (groupst is null or instr(groupst,spi.snomgroup)>0)
               order by spi.snomenname) loop
      if r is null then 
        r:=ii.snomenname;
      else
        r:=r||', '||ii.snomenname;    
      end if;
    end loop;         
    return(r);
  end;    
  
--получить любые осложнения внесенные в выписку строкой
--Anesthesia, Postoperative, Intraoperative, Radiation, ChemoTherapeutic, HormoneImmuneTherapeutic, Targeted, ''  
--short=0 с названием, short=1 только код
  function GetCancerComplic(cas_id in number, param in varchar2 default '', short in number default 0) return varchar2
  is
    r varchar2(4000) default '';
  begin
    if nvl(param,'Anesthesia')='Anesthesia' then
      for ii in (select a.id from hospital.cancer_sum_anes_resus_aid a 
                  where a.cancer_summary_id=cas_id
                ) loop
        r:=r||' '||GetAnesthesiaComplic(ii.id);
      end loop;  
    end if;
    if nvl(param,'Postoperative') in ('Postoperative','Intraoperative') then
      for ii in (select sc.code, sc.name
                   from hospital.cancer_sum_surgery_treat s, hospital.cancer_sum_surgery_compl c, hospital.surgery_complication sc
                  where s.cancer_summary_id=cas_id and c.cancer_summary_surgery_id=s.id and sc.id=c.complication_id
                        and c.type=nvl(param,c.type)
                  order by s.id,c.id
                ) loop
        r:=r||' '||ii.code;
        if short=0 then r:=r||' '||ii.name; end if;
      end loop;  
    end if;
    if nvl(param,'Radiation') in ('Radiation','ChemoTherapeutic','HormoneImmuneTherapeutic','Targeted') then
      for ii in (select sc.code, sc.name
                   from hospital.cancer_sum_complication c, hospital.surgery_complication sc
                  where c.cancer_summary_id=cas_id and sc.id=c.complication_id
                        and c.treatment_type=nvl(param,c.treatment_type)
                  order by c.id      
                ) loop
        r:=r||' '||ii.code;
        if short=0 then r:=r||' '||ii.name; end if;
      end loop;  
    end if;    
    return trim(r);
  end;
  
--получить тариф для указаного КСГ на указанную дату
  function GetCSGTarif(csg_id in number, d in date default sysdate) return number
  is
    r number(9,2) default null;
    i number;
  begin
    i:=csg_id;
    for ii in (select
                  cp.price
                 from
                  hospital.csg_tariff_plan tp
                  join hospital.csg_price cp on tp.id=cp.csg_tariff_plan_id and cp.csg_id=i
                where
                  d between tp.start_date and tp.end_date  
               ) loop   
      r:=ii.price;            
    end loop;
    return r;    
  end;   
  
--получить тип КСГ
  function GetCSGType(csg_id in number) return varchar2
  is
    r varchar2(4000);
  begin
    for ii in (select csg.full_code from hospital.clinical_statistic_group csg 
                where csg.id=csg_id
               ) loop   
      r:=ii.full_code;            
    end loop;
    if r is null then
       r:='КСГ не указан';
    elsif r like '1.1%' and length(r) > 9 and substr(r,8,1) <> '.' then
       r:='ВМП базовая';
    elsif r like '2.2%' and length(r) > 9 and substr(r,8,1) <> '.' then
       r:='ВМП сверхбазовая';
    elsif r in ('1.2.1.013','1.2.1.032') then
       r:='Паллиативная';
    else
       r:='КСГ';   
    end if;   
    return r;    
  end;     
  
--код счета ТФОМС в краткое именование типа счета  
  function GetShortSchetType(code in varchar2) return varchar2
  is
  begin
   return(case when code in ('01','14') then 'База'
               when code in ('02','15') then 'Сверхбаза'
               when code in ('10','22') then 'Межтер'
               when code in ('03','23') then 'Высокотех'
          else code end); 
  end;
  
--получить полис ОМС пациента
--param num номер ser серия orgname имя СМО orgcode код тфомс СМО orgokato ОКАТО СМО
  function GetClientCertificate(cl_id in number, d in date default sysdate, param in varchar2 default 'num') return varchar2
  is
    r varchar2(4000) default '';
  begin
    for ii in (select (case param  
                       when 'ser' then cc.ser 
                       when 'orgname' then o.name
                       when 'orgcode' then o.tfoms_code
                       when 'orgokato' then o.okato
                       else cc.num end) n
                 from hospital.client_certificate cc
                      left join hospital.organisation o on o.id=cc.organization_id
                where cc.client_id=cl_id and cc.certificate_type_id in (1,2)
                      and d between nvl(cc.give_date,to_date('0001','yyyy')) and nvl(cc.annul_date,to_date('9999','yyyy'))
                      and d between nvl(cc.start_date,to_date('0001','yyyy')) and nvl(cc.end_date,to_date('9999','yyyy'))
               ) loop   
      r:=ii.n;
    end loop;
    return r;    
  end;     
  
--получить полис случая
--param num номер ser серия orgname имя СМО orgcode код тфомс СМО orgokato ОКАТО СМО
  function GetProjectCertificate(p_id in number, param in varchar2 default 'num') return varchar2
  is
    r varchar2(4000) default '';
  begin
    for ii in (select (case param  
                       when 'ser' then cc.ser 
                       when 'orgname' then o.name
                       when 'orgcode' then o.tfoms_code
                       when 'orgokato' then o.okato
                       else cc.num end) n
                 from hospital.project p
                      join hospital.client_certificate cc on cc.id=p.client_certificate_id
                      left join hospital.organisation o on o.id=cc.organization_id
                where p.id=p_id
               ) loop   
      r:=ii.n;
    end loop;
    return r;    
  end;     
  
--определение первичности пациента
--для пациента вернуть первый первичный онко диагноз (disease.id) при наличии в указаный период по алгоритму из Аналит раздел D
--dtf дата с включительно ddt дата до не включительно наличия первичного диагноза, n - номер обнаруженого первичного диагноза
  function GetClientFirstDisease(cl_id in number, dtf in date default to_date('01.01.0001','dd.mm.yyyy'), dtt in date default to_date('01.01.9999','dd.mm.yyyy'), n in number default 1) return number
  is
    r number default null;
    i number default 1;
  begin
    for ii in (select 
                  d2.id
                 from 
                  hospital.disease d2
                  join hospital.oncologic_disease od2 on d2.oncologic_disease_id = od2.id
                  join hospital.project p2 on d2.project_id = p2.id
                  join hospital.project_type pt2 on p2.project_type_id = pt2.id
                  join hospital.diagnosis_type dt2 on d2.diagnosis_type_id = dt2.id
                  join hospital.mkb m2 on d2.mkb_id = m2.id
                where  
                  p2.client_id=cl_id
                  and d2.start_date >= dtf
                  and d2.start_date < dtt
                  and (od2.source_cancer_date is null)           --во время выставления диагноза в канцер-регистре этот пациент отсутсвовал
                  and pt2.care_type_id = 3                       --только в амбулаторных случаях
                  and (od2.cancer_clinic_group_id in (3, 6, 4))  --только выставлена клиническая группа II, II а, IV
                  and (dt2.code in (2, 4, 7, 3))                 --только предварительный, сопутсвующий, заключительный, заключительный клинический
                  and not (exists (select d1.id                  --ранее у пациента не выставлялся этот диагноз с точностью до точки
                                     from hospital.disease d1
                                          join hospital.project p1 on d1.project_id = p1.id
                                          join hospital.oncologic_disease od1 on d1.oncologic_disease_id = od1.id
                                          join hospital.diagnosis_type dt1 on d1.diagnosis_type_id = dt1.id
                                          join hospital.mkb m1 on d1.mkb_id = m1.id
                                    where p1.client_id = p2.client_id
                                          and (od1.cancer_clinic_group_id in (3, 6, 4))
                                          and (dt1.code in (2, 4, 7, 3))
                                          and d1.start_date < d2.start_date
                                          and substr(m1.code, 1, 3) = substr(m2.code, 1, 3))) 
                order by
                  d2.start_date, d2.id
               ) loop
      if i=n then 
        r:=ii.id;         
        exit; 
      end if;   --возвращаем только указанный по порядку первичный диагноз
      i:=i+1;
    end loop;           
    return(r);
  end;
  
end PAREP;
/
