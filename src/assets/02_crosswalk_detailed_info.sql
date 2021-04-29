with a as(
	select soc
	from stw_pathways.crosswalk_info
	group by soc
	having true = any(array_agg(technical))
),
b as (
	select b.*
	from a
	join stw_pathways.crosswalk_info b
	on a.soc = b.soc
),
c as (
	select soc
	from stw_pathways.crosswalk_info
	group by soc
	having true = any(array_agg(ed_bls OR ed_onet))
),
d as (
	select a.*
	from b a
	join c b
	on a.soc = b.soc
),
e as (
	select soc, true = all(array_agg(technical)) soc_technical
	from d
	group by soc
),
f as (
	select soc, true = all(array_agg(
		case
			when not detailed then coalesce(ed_bls, ed_onet)
			else ed_onet
		end
	)) soc_ed
	from d
	group by soc
),
g as (
	select a.*, soc_technical
	from d a
	join e b
	on a.soc = b.soc
),
h as (
	select a.*, soc_ed
	from g a
	join f b
	on a.soc = b.soc
),
i as (
	select distinct soc, soc_technical and soc_ed stw
	from h
),
j as (
	select a.*, stw
	from h a
	join i b
	on a.soc = b.soc
),
k as (
	select *
	from j
	where coalesce(not stw, true)
),
l as (
	select distinct on (soc) soc,
		case
			when soc_technical and soc_ed is null then 'Missing Education Information'
			when soc_technical and not soc_ed then 'Some Requiring Higher Education'
			when not soc_technical and not soc_ed then 'Some Technical and Some Sub-Bachelor'
			when not soc_technical and soc_ed is null then 'Some Technical and Missing Information for Education'
			when not soc_technical and soc_ed then 'Some Technical'
		end scenario
	from k
),
m as (
	select distinct scenario, a.soc, soc_title title
	from onet_25_1.onet19_soc18 a
	join l b
	on a.soc = b.soc
)
select *
from j
order by soc
;
