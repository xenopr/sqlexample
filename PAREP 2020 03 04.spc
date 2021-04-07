create or replace package PAREP is

  -- Создано  Протасов.А.А.
  -- 25.08.2017 10:04:23
  -- набор функций для быстрого построения отчетов


--тип для функций возвращающих ID журнала госпитализаций
  type typeID is record (hospital_card_id NUMBER, hospital_card_movement_id NUMBER );
--тип таблица журнала госпитализаций
  type tblID is table of typeID;


--тип для функций возвращающих ID по хирургии
  type typeSurgeryID is record (hospital_card_id NUMBER, project_id NUMBER, surgery_id NUMBER );
--тип таблица по хирургии
  type tblSurgeryID is table of typeSurgeryID;
  
--тип для функций возвращающих список актуальных отделений
  type typeDepID is record (id NUMBER, name VARCHAR2(2000), shortname VARCHAR2(1000), ordernum NUMBER, dayhospital VARCHAR2(30) );
--тип таблица списка отделений
  type tblDepID is table of typeDepID;  

--получить ФИО пациента как строку
  function GetFIOClient(CLIENTID INTEGER) return VARCHAR2;
--получить ФИО пациента кратко с датой рожденья как строку 
  function GetShortFIOClient(CLIENTID INTEGER) return VARCHAR2;  
--получить дату рождения пациента
  function GetBirthDayClient(CLIENTID INTEGER) return DATE;
--получить ФИО врача как строку
  function GetFIOWorker(WORKERID INTEGER) return VARCHAR2; 
--получить ID отделения врача 
  function GetWorkerDepID(WORKERID INTEGER) return NUMBER; 
--получить специальность врача 
  function GetWorkerSpeciality(WORKERID INTEGER) return VARCHAR2;   
--получить ФИО с инициалами врача как строку
  function GetShortFIOWorker(WORKERID INTEGER) return VARCHAR2;
--получить логин врача
  function GetLoginWorker(WORKERID INTEGER) return VARCHAR2;   

--получить последний основной диагноз по пациенту на указанную дату
  function GetLastDiagnose(CLIENTID IN NUMBER, DD IN DATE) return VARCHAR2;
--получить последний код основного диагноза по пациенту на указанную дату
  function GetLastDiagnoseCode(CLIENTID IN NUMBER, DD IN DATE) return VARCHAR2;
--получить последний заключительный диагноз по пациенту на указанную дату
  function GetLastDisease(CLIENTID IN NUMBER, DD IN DATE) return VARCHAR2;
--получить последний код заключительного диагноза по пациенту на указанную дату
  function GetLastDiseaseCode(CLIENTID IN NUMBER, DD IN DATE) return VARCHAR2;
--получить коды диагноза по случаю указанного типа
-- 1 - заключительный
-- 2 - сопутсвующие
-- 3 - осложнения
-- 4 - предварительные
  function GetProjectMKBCode(DisType IN NUMBER, ProjectID IN NUMBER) return VARCHAR2; 
  
--получить строкой коды всех уникальных основных и сопутсвующих диагнозов пациента после указанной даты
  function GetClientMKBCodes(CLIENTID IN NUMBER, DD IN DATE default to_date('01.01.0001','dd.mm.yyyy'), param in number default 1) return VARCHAR2;
--получить дату первого установления основного либо сопутсвующего диагноза пациента после указанной даты
  function GetClientMKBDate(CLIENTID IN NUMBER, DD IN DATE default to_date('01.01.0001','dd.mm.yyyy')) return DATE;
--получить самый первый основной диагноз пациента после указанной даты
  function GetClientFinalMKB(CLIENTID IN NUMBER, DD IN DATE default to_date('01.01.0001','dd.mm.yyyy')) return VARCHAR2;  
--получить название самого первого основного диагноза пациента после указанной даты
  function GetClientFinalMKBName(CLIENTID IN NUMBER, DD IN DATE default to_date('01.01.0001','dd.mm.yyyy')) return VARCHAR2;
--получить дату первого установления основного диагноза пациента после указанной даты
  function GetClientFinalMKBDate(CLIENTID IN NUMBER, DD IN DATE default to_date('01.01.0001','dd.mm.yyyy')) return DATE;

--получить список кодов сопутсвующих заболеваний канцер-выписки
  function GetCancerAccompanyCode(CancerSummaryID IN NUMBER) return VARCHAR2;
 
 
--получить дату последней выполненной услуги совпадающей с датой в расписании по клиенту ранее указанной даты в пределах указанного количества дней
  function GetLastExecutedServiceDate(CLIENTID IN NUMBER, DD IN DATE, NN INTEGER) return DATE;  

--получить все телефоны пациента
  function GetClientTlf(CLIENTID IN NUMBER) return VARCHAR2;  
  
--определить городской или сельский житель
  function GetClientIsCity(CLIENTID IN NUMBER) return VARCHAR2; 

--Вернуть возраст пациента на дату, по умолчанию - на сегодня
  function GetClientAge(CLIENTID IN NUMBER, DD IN DATE default SYSDATE) return NUMBER;
--Вернуть признак, пациент пенсионного возраста (нетрудоспособный) на дату, по умолчанию - на сегодня --1 - пенсионер, 0 - не пенсионер, null - не найден
  function GetClientIsPensioner(CLIENTID IN NUMBER, DD IN DATE default SYSDATE) return NUMBER;

--определить относится ли человек к югу тюменской области - т.е. тюменской области, к г.тюмень, иной, неизвестно по прописке  
  function GetClientIsTyumen(CLIENTID IN NUMBER) return VARCHAR2;   
--определить относится ли человек к югу тюменской области на русском
  function GetClientIsTyumenRus(CLIENTID IN NUMBER) return VARCHAR2;   
  
--паспорт пациента
  function GetClientPassport(CLIENTID IN NUMBER) return VARCHAR2;    

--получить адрес регистрации пациента (прописки)
  function GetClientAddress(CLIENTID IN NUMBER) return VARCHAR2;  
--получить адрес фактического проживания пациента
  function GetClientLiveAddress(CLIENTID IN NUMBER) return VARCHAR2;
--получить гражданство пациента
  function GetClientCitizenship(CLIENTID IN NUMBER) return VARCHAR2;    
--получить адрес кодом КЛАДР (проживания)
  function GetClientLiveKLADR(CLIENTID IN NUMBER) return VARCHAR2;  

--получить дату последней выполненной услуги у пациента на дату
  function GetLastServiceDate(CLIENTID IN NUMBER, DD IN DATE) return DATE;  
  
--получить текстом всю команду оперерирующих для операции в выписке БЗН
  function GetCancerSurgeryCommand(CSST_ID IN NUMBER) return VARCHAR2;  
--получить текстом всю команду оперерирующих для операции в выписке БЗН, кратко
  function GetShortCancerSurgeryCommand(CSST_ID IN NUMBER) return VARCHAR2;  
  
--получить текстом всю команду оперерирующих для операции из ЭМК
  function GetSurgeryCommand(SurgeryID IN NUMBER) return VARCHAR2;  
--получить текстом всю команду оперерирующих для операции из ЭМК, кратко
  function GetShortSurgeryCommand(SurgeryID IN NUMBER) return VARCHAR2;    

--Получить расшифровки  
--Житель города,села
  function GetCancerLocalityType(SSIN IN VARCHAR2) return VARCHAR2;  
--Стадии опухолевого процесса
  function GetCancerStage(SSIN IN VARCHAR2) return VARCHAR2;  
--Локализации отдаленных метастазов
  function GetCancerMetastasisAreas(SSIN IN VARCHAR2) return VARCHAR2;  
--Методы подтверждения диагноза
  function GetCancerConfirmMethods(SSIN IN VARCHAR2) return VARCHAR2;  
--Причины поздней диагностики
  function GetCancerCauseOfLateDiagnosis(SSIN IN VARCHAR2) return VARCHAR2;  
--Обстоятельства выявления опухоли
  function GetCancerDetectionCircum(SSIN IN VARCHAR2) return VARCHAR2; 
--Цель госпитализации
  function GetCancerHospitalizationGoal(SSIN IN VARCHAR2) return VARCHAR2;  
--Результат госпитализации
  function GetCancerHospitalizationResult(SSIN IN VARCHAR2) return VARCHAR2;  
--Характер лечения
  function GetCancerNeoplTreaCharacter(SSIN IN VARCHAR2) return VARCHAR2;  
--Причина незавершенности лечения
  function GetCancerNeoplIncomplCause(SSIN IN VARCHAR2) return VARCHAR2;  
--Результат лечения
  function GetCancerTreatmentResult(SSIN IN VARCHAR2) return VARCHAR2;
--Модифицирующие средства лучевого лечения rad_treat_modifying_tools
  function GetCancerRadModifyingTools(SSIN IN VARCHAR2) return VARCHAR2;  
--Канцер-выписка, пункт 26_1 хир.лечение surgical_treatment_number
  function GetCancerItem26_1(SSIN IN VARCHAR2) return VARCHAR2;  
--Канцер-выписка, пункт 26_2 хир.лечение surgical_treatment_character
  function GetCancerItem26_2(SSIN IN VARCHAR2) return VARCHAR2;
--Канцер-выписка, применение лучевой терапии  rad_treat_using 
  function GetCancerRadTreatUsing(SSIN IN VARCHAR2) return VARCHAR2;
--Канцер-выписка, условия применения лучевой терапии  rad_treat_using_conditions
  function GetCancerRadTreatUsingCond(SSIN IN VARCHAR2) return VARCHAR2;    
--Канцер-выписка, пункт 27_1 рад.лечение rad_treat_number
  function GetCancerItem27_1(SSIN IN VARCHAR2) return VARCHAR2;  
--Канцер-выписка, пункт 27_2 рад.лечение rad_treat_mode
  function GetCancerItem27_2(SSIN IN VARCHAR2) return VARCHAR2;  
--Канцер-выписка, пункт 27_3 рад.лечение rad_treat_power
  function GetCancerItem27_3(SSIN IN VARCHAR2) return VARCHAR2;  
--Канцер-выписка, пункт 27_4 рад.лечение rad_treat_type
  function GetCancerItem27_4(SSIN IN VARCHAR2) return VARCHAR2;  
--Канцер-выписка, пункт 28_1 хим.лечение chemother_treat_number
  function GetCancerItem28_1(SSIN IN VARCHAR2) return VARCHAR2;  
--Канцер-выписка, пункт 28_2 хим.лечение chemother_treat_type
  function GetCancerItem28_2(SSIN IN VARCHAR2) return VARCHAR2;  

--Канцер-выписка, Анестезия, сопутсвующие заболевания anesthesia_related_disease_ids  
  function GetCancerAnesthesiaRelated(SSIN IN VARCHAR2) return VARCHAR2; 
--Канцер-выписка, Анестезия, осложнения
  function GetCancerAnesthesiaComplic(SSIN IN VARCHAR2) return VARCHAR2;      

--Канцер-выписка, дешифровка вида лекарственной терапии  hospital.cancer_sum_drug_treat.drug_treatment_type
  function GetCancerDrugTreatType(SSIN IN VARCHAR2) return VARCHAR2;        
  
--Вернуть строкой палату и койку где лежит пациент по стацкарте в указанную дату  
  function GetPatientRoomBed(DD IN DATE, HC_ID IN NUMBER) return VARCHAR2;
  
--Список стацкарт лежащих в указанном отделении в указанную дату по нахождению InDepartment, игнорим Анестизиологию
  function GetListBedBusy(DD IN DATE, DepID IN NUMBER) return tblID pipelined;   
--Список стацкарт лежащих в указанном отделении в указанный период
--суммируем стацкарты лежащие в ночь в даты указанного периода , игнорим Анестизиологию
  function GetListBedBusyPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID pipelined;  

--Список стацкарт лежащих в указанном отделении в указанную дату по нахождению InDepartment, с учетом Анестизиологии
  function GetListBedBusy95(DD IN DATE, DepID IN NUMBER) return tblID pipelined;   
--Список стацкарт лежащих в указанном отделении в указанный период
--суммируем стацкарты лежащие в ночь в даты указанного периода, с учетом Анестизиологии
  function GetListBedBusyPeriod95(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID pipelined;  
   
--Список стацкарт поступивших в указанное отделение в указанную дату (принятых) по первому нахождению InDepartment
  function GetListBedRecieved(DD IN DATE, DepID IN NUMBER) return tblID pipelined;    
--Список стацкарт поступивших в указанное отделение в указанный период (поступивших в стационар)
  function GetListBedRecievedPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID pipelined;   

--Список стацкарт поступивших в указанное отделение в указанную дату по изменению нахождения InDepartment без анестизиологии
  function GetListBedIn(DD IN DATE, DepID IN NUMBER) return tblID pipelined; 
--Список стацкарт поступивших в указанное отделение в указанный период по изменению нахождения InDepartment без анестизиологии
  function GetListBedInPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID pipelined;   
    
--Список стацкарт поступивших в указанное отделение в указанную дату по SentTo
--не исп неправ
--  function GetListBedIn2(DD IN DATE, DepID IN NUMBER) return tblID pipelined;   

--Список стацкарт отправленых из указанного отделения в указанную дату по изменению нахождения InDepartment без анестизиологии
  function GetListBedOut(DD IN DATE, DepID IN NUMBER) return tblID pipelined;  
--Список стацкарт отправленых из указанного отделения в указанный период по изменению нахождения InDepartment без анестизиологии
  function GetListBedOutPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID pipelined;   
   
--Список стацкарт отправленых из указанного отделения в указанную дату по SentTo
--не исп неправ
--  function GetListBedOut2(DD IN DATE, DepID IN NUMBER) return tblID pipelined;   

--Список стацкарт выписанных из указанного отделения в указанную дату
  function GetListBedDischarged(DD IN DATE, DepID IN NUMBER) return tblID pipelined;   
--Список стацкарт выписанных из указанного отделения в указанный период
  function GetListBedDischargedPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblID pipelined; 
 
--Список стацкарт с первой операцией у выписанных в указанную дату относящихся к указанному отделению 
  function GetListSurgery(DD IN DATE, DepID IN NUMBER) return tblSurgeryID pipelined;     
--Список стацкарт с первой операцией у выписанных в указанный период относящихся к указанному отделению 
  function GetListSurgeryPeriod(DTF IN DATE, DTT IN DATE, DepID IN NUMBER) return tblSurgeryID pipelined;  

--Вернуть краткое имя отделения стационара для отчетов
  function GetShortDepname(DepID IN NUMBER) return VARCHAR2; 
--Вернуть полное имя отделения стационара по ид
  function GetDepname(DepID IN NUMBER) return VARCHAR2;   
  
--поиск пациента в федеральном списке импортированом из федеральной базы канцер-регистров, по ФИО и дате рождения
  function FindFederalPatient(surname IN VARCHAR2, firstname IN VARCHAR2, patrname IN VARCHAR2, bday IN DATE, diag IN VARCHAR2 default '') return NUMBER;
--поиск пациента в федеральном списке, по строке фамилия имя отчество dd.mm.yyyy , перегрузка функции
  function FindFederalPatient(findst IN VARCHAR2) return NUMBER;
--поиск пациента по строке поиска в ЭМК, для поисков из excel-списков, возвращает client_id
  function FindClient(findst in varchar2, project_date in date default null) return number;
      
--удовлетворяет ли данный случай условию необходимости создания Извещения о ЗНО
  function CheckProjectFirstNotice(pID IN NUMBER) return VARCHAR2;   
--удовлетворяет ли данный случай условию необходимости создания Извещения о ЗНО, проверка вхождения текста
--  function CheckProjectFirstNoticeText(pID IN NUMBER, st IN VARCHAR2) return BOOLEAN;
  
--удовлетворяет ли данный случай условию необходимости создания Протокола IV о ЗНО
  function CheckProjectNeglectedProtocol(pID IN NUMBER) return VARCHAR2;   
  
  
--КЛАДР
--получить имя региона из кода КЛАДР
  function GetKLADRRegion(kladr IN VARCHAR2) return VARCHAR2;
--получить имя района из кода КЛАДР
  function GetKLADRArea(kladr IN VARCHAR2) return VARCHAR2;
--получить имя города из кода КЛАДР
  function GetKLADRCity(kladr IN VARCHAR2) return VARCHAR2; 
--получить имя населенного пункта из кода КЛАДР
  function GetKLADRVillage(kladr IN VARCHAR2) return VARCHAR2;   

--получить имя территории из строки адреса
  function GetTerritory(address IN VARCHAR2) return VARCHAR2;
--получить имя региона территории из строки адреса 
  function GetTerritoryRegion(address IN VARCHAR2) return VARCHAR2; 
--получить имя области из территории из строки адреса
  function GetTerritoryState(address IN VARCHAR2) return VARCHAR2;  
--получить имя населенного пункта из строки адреса
  function GetTerritoryCity(address IN VARCHAR2) return VARCHAR2;      
--получить федеральный код территории из строки адреса 
  function GetTerritoryFedCode(address IN VARCHAR2) return INTEGER;    
--получить имя куста из территории (группа районов) 
  function GetTerritoryBush(address IN VARCHAR2) return varchar2;       
  
--проверка канцер-выписки. выявление кривых данных.
  function CheckCancerSummary(Cancer_Summary_ID IN NUMBER) return VARCHAR2;    
  
--получить планируемое количество койко-дней для указанного отделения за указанный период (корректно для периода внутри одного года)  
  function GetPlanBedDays(Dep_ID IN NUMBER, DTF IN DATE, DTT IN DATE) return NUMBER;
--получить планируемое количество коек для указанного отделения за указанный период (корректно для периода внутри одного года)  
  function GetPlanBeds(Dep_ID IN NUMBER, DTF IN DATE, DTT IN DATE) return NUMBER;  
  
--получить количество койкодней для указанной стацкарты, с учетом расчета для дневного стационара, из дат занятия-освобождения койки
  function GetBedDays(HC_ID IN NUMBER) return NUMBER; 
--получить количество койконочей в реанимации для указанной стацкарты
  function GetBedDays95(HC_ID in number, param in number default 0) return NUMBER;

--получить ID отделения в котором стацкарта находится на указанную дату время, anest=1 с учетом нахождения в анестезии
  function GetBusyDepID(HC_ID in number, DD in date default sysdate, Anest in number default 0) return number;  
--получить ID отделения выписки для указанной стацкарты по отделению освобождения койки  
  function GetOuttakeDepID(HC_ID IN NUMBER) return NUMBER;   
--получить ID отделения поступления для указанной стацкарты по отделению занятия койки  
  function GetReceiveDepID(HC_ID IN NUMBER) return NUMBER;
--получить для указанной стацкарты по дату освобождения койки  
  function GetOuttakeDate(HC_ID IN NUMBER) return DATE;
--получить для указанной стацкарты по дату занятия койки  
  function GetReceiveDate(HC_ID IN NUMBER) return DATE;          
  
--Вид оплаты указанного случая, текстом, для отчетов канцеров  
  function GetProjectPayType(P_ID IN NUMBER) return VARCHAR2; 
--Вид оплаты указанной услуги, текстом, которым было назначено либо оплачено 
--SO_ID не указано или 1 - каким назначено, 2 - каким оплачено
  function GetServicePayType(S_ID IN NUMBER, SO_ID IN NUMBER DEFAULT 2) return VARCHAR2;   
--Получить дату выполнения услуги
  function GetServiceExecDate(S_ID in number) return date;
--Получить дату оплаты услуги
  function GetServicePayDate(S_ID in number) return date;
--Получить дату назначения услуги
  function GetServiceAppointDate(S_ID in number) return date;
--Получить сумму оплаты услуги
  function GetServicePaySum(S_ID in number) return number;
--Получить id кем назначена услуга
  function GetServiceAppointWorker(S_ID in number) return number;
--Получить id кем оплачена услуга
  function GetServicePayWorker(S_ID in number) return number;
--Получить id выполнившего услугу
  function GetServiceExecWorker(S_ID in number) return number;  
--Получить список фио ассистентов в услуге
  function GetServiceAssistents(S_ID in number) return varchar2;    
      
--получить чистый текст из разделов медзаписи для указанной медзаписи и указанного раздела
  function GetMedicalRecordPartText(mr_id number, mrp_id number, part number default 0) return varchar2;
--получить чистый текст протокола операции
  function GetSurgeryProtocolText(surgery_protocol_id number, part number default 0) return varchar2;  
  
--дешифровка ХБС
  function GetHBS(SSIN IN VARCHAR2) return VARCHAR2;
  
--Получить перечень строкой назаначенных препаратов в указанной канцер-выписке
--ChemoTherapeutic - только химио
--HormoneImmuneTherapeutic - только гормоно
--Targeted - только таргетная
--null - все
  function GetCancerListDrugs(cas_id in number, typ varchar2 default null) return varchar2;

--порядковый номер для стандартного порядка отделений-стационаров
  function GetDepOrder(dep_id in number) return number;    
  
--костыль. подмена id врача на id с тем же фио, но из стационара, с приоритетом круглосуточный
  function SubstWorkerToStac(w_id in number) return number; 
--костыль. подмена id врача на id с тем же фио, но из стационара  ds=1 - подмена только на дневной стационар если есть, 0-на стационар с приоритетом круглосуточный  
  function SubstWorkerToStac(w_id in number, ds in number) return number;

--вернуть список диагнозов для раздела из таблицы FORMGROUPMKB для отображения в отчете форма 14
  function GetFormGroupMKBs(groupcode in varchar2, formname in varchar2 default 'FORM14') return varchar2;
--раздвинуть код из таблицы FORMGROUPMKB для отображения в отчете форма 14 для упорядочивания
  function GetFormGroupOrder(groupcode in varchar2) return varchar2;
--вернуть список групп, к которым отнесен данный федеральный код операции
  function GetFedGroups(surgerycode in varchar2, formname in varchar2 default 'FORM14') return varchar2;
  
--подбор подходящего адреса из справочника адресов из названия улицы, под справочник адреса-поликлиники
  function LoremOratioApta(streetname in varchar2) return varchar2;  
  

--получить список отделений стационаров
--0=круглосуточные, 1=дневные, 2=все
  function GetListDep(ds number default 2) return tblDepID pipelined;
  
--получить вид анестезии 
  function GetAnesthesiaType(a_id number) return varchar2;
--получить осложнения анестезии 
  function GetAnesthesiaComplic(a_id number) return varchar2;
--получить особености послеоперационного периода анестезии 
  function GetAnesthesiaPosfea(a_id number) return varchar2;
--получить сопутсвующие заболевания анестезии 
  function GetAnesthesiaConcom(a_id number) return varchar2; 
  
--найти ид первой выполненной услуги у пациента от указанной даты с кодом scode
  function GetClientFirstService(cl_id in number, d in date default to_date('0001','yyyy'), scode in varchar2 default '%') return number;
--найти ид последней выполненной услуги у пациента до указанной даты с кодом scode
  function GetClientLastService(cl_id in number, d in date default to_date('9999','yyyy'), scode in varchar2 default '%') return number;
    
--получить ид поликлиники из строки адреса, (ид из hospital.cancer_register_dict_med_org)
  function GetCancerPolyclinicID(address in varchar2) return number;
--получить имя поликлиники из справочника канцеров
  function GetCancerPolyclinic(med_org_id in number) return varchar2;    

--получить имя последней направившей МО у указанного пациента из электронного либо бумажного направления
  function GetDirectPolyclinic(cl_id in number, dtt in date default to_date('9999','yyyy')) return varchar2;
--получить дату последнего направления у указанного пациента из электронного либо бумажного направления
  function GetDirectDate(cl_id in number, dtt in date default to_date('9999','yyyy')) return date;
      
--получить текстом вид лечения из канцер-документа по ид стацкарты
  function GetCancerTreatment(hc_id in number) return varchar2;  

--получить перечень выполненных препаратов в случае, v=type - тип препарата из паруса, v=name - имя препарата как в парусе, v=mnn - МНН препарата из паруса
  function GetDrugs(p_id in number, v in varchar2 default 'name') return varchar2;
  
--получить перечень препаратов списаных в Парус на этого пациента в период лежания в стационаре в указанной стацкарте
  function GetDrugsParus(hc_id in number, groupst in varchar2 default '') return varchar2;

--получить любые осложнения внесенные в выписку строкой
--Anesthesia, Postoperative, Intraoperative, Radiation, ChemoTherapeutic, HormoneImmuneTherapeutic, Targeted, ''  
  function GetCancerComplic(cas_id in number, param in varchar2 default '', short in number default 0) return varchar2;
  
  
--получить тариф для указаного КСГ на указанную дату
  function GetCSGTarif(csg_id in number, d in date default sysdate) return number;  
--получить тип КСГ
  function GetCSGType(csg_id in number) return varchar2; 
--код счета ТФОМС в краткое именование типа счета  
  function GetShortSchetType(code in varchar2) return varchar2;
  
--получить полис ОМС пациента
--param num номер ser серия orgname имя СМО orgcode код тфомс СМО orgokato ОКАТО СМО
  function GetClientCertificate(cl_id in number, d in date default sysdate, param in varchar2 default 'num') return varchar2;
--получить полис случая
  function GetProjectCertificate(p_id in number, param in varchar2 default 'num') return varchar2;
  
--определение первичности пациента
--для пациента вернуть первый первичный онко диагноз (disease.id) при наличии в указаный период по алгоритму из Аналит раздел D
--dtf дата с включительно ddt дата до не включительно наличия первичного диагноза, n - номер обнаруженого первичного диагноза
  function GetClientFirstDisease(cl_id in number, dtf in date default to_date('01.01.0001','dd.mm.yyyy'), dtt in date default to_date('01.01.9999','dd.mm.yyyy'), n in number default 1) return number;
   
  
end PAREP;
/
