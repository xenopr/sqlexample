with s as (select 'Бендамустин Винкристин Доксорубицин Циклофосфамид Циклофосфамид Винкристин Доксорубицин Циклофосфамид Винкристин Кокаин Кокаин Кокаин Бендамустин Анаша ' s from dual)

select(listagg(s, ' ') within group(order by s))
from
(
select distinct
  trim(regexp_substr(s.s,'(\S*)(\s|$)',1,level)) as s
--  substr(s.s,regexp_instr(s.s,'( |^)',1,level,1),regexp_instr(s.s,'( |$)',1,level)-regexp_instr(s.s,'( |^)',1,level,1)) as s 
from s
connect by regexp_instr(s.s,'( |$)',1,level,1)>0
--connect by instr(s.s,' ',1,level)>0
)
