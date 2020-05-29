-- Scapula fractures removed from dataset
--commented out on lines 112,124,231,282,291,300,307
/*
181004			
each analgesia group - median age, ISS, proportion with injuries, rib fractures listed, mortality, LOS median,  male, r

mortality in patients where analgesia and strong/regional analgesia is delayed, time till analgesia vs mortality 
(or expected mortality vs time till analgesia)
*/



drop table #ribsdataset
select 
p.SubmissionID,caseID,mtc,arvdt,age,sex,case when sex = 'male' then 1 else 0 end as Male,
charl,ISS,issband,GCS,intubvent,msev,head,face,thor,abdo,spine,pelv,limb,other otherinj,
case when ps14 is null then ImputePs*100 else ps14 end as PS_14,died,los,loscc,mech,
mechtype,ttype,transfertype,AISCode,SupplementaryCode,severity,Injuries,OperDesc operation,
case	when OperDesc = 'Rib fracture fixation' then 1	else 0	end as RibFixation,
isnull (CAST([ANLG DateTime] AS datetime), '2100-01-01 00:01:00.000') AnlgDT,
Analgesia,
case 
	when EpiduralAnaesthetic is not null then 1
	else 0
	end as EpiduralAnaesthetic,
case
	when Analgesia is null and EpiduralAnaesthetic is not null then 'Epidural'
	when Analgesia = 'other' and EpiduralAnaesthetic is not null then 'Epidural'
	when Analgesia is null and EpiduralAnaesthetic is null then 'N/a'
	else Analgesia
	end as CombAnalgesia,
case
	when Analgesia is null and EpiduralAnaesthetic is null then 1
	else 0
	end as [N/a],
case
	when analgesia = 'Intravenous opioid' then 1
	else 0
	end as Intravenousopioid,
case
	when  analgesia = 'Intravenous paracetamol' then 1
	else 0
	end as IntravenousParacetamol,
case
	when analgesia = 'Entonox' then 1
	else 0
	end as Entonox,
case 
	when analgesia = 'Ketamine' then 1
	else 0
	end as Ketamine,
case
	when Analgesia = 'Epidural block' then 1
	when Analgesia = 'other' and EpiduralAnaesthetic is not null then 1
	when Analgesia is null and EpiduralAnaesthetic is not null then 1
	else 0
	end as Epidural,
case
	when Analgesia in ('Other','Patient controlled Intravenous Opioid (PCA)',
						'Local anaesthetic blockade (non epidural/paravertebral)',
						'Paravertebral block','Local anaesthetic patches','Methoxyflurane') then 1
	else 0
	end as Other,
case
	when supplementarycode in ('57','59') or aiscode = '450201' then 1
	when supplementarycode in  ('58','60','61') or aiscode = '450202' then 2
	when supplementarycode in ('63','73','83') then 3
	when supplementarycode in ('64','74','84') then 4
	when supplementarycode in ('65','75','85') then 5
	when supplementarycode in ('66','76','86') then 6
	when supplementarycode in ('67','77','87') then 7
	when supplementarycode in ('68','78','88') then 8
	when supplementarycode in ('69','79','89') then 9
	when supplementarycode in ('70','80','90') then 10
	when supplementarycode in ('71','81','91') then 11
	when supplementarycode in ('62','72','82') then NULL
	end as RibFractures,
case
	when aiscode between '450209' and '450214' then 1
	else 0
	end as FlailChest,
case
	when aiscode = '450804' then 1
	else 0
	end as SternalFracture
--case
--	when aiscode between '750900' and '750972' then 1
--	else 0 
--	end as ScapulaFracture 

into #ribsdataset
from PRIcache P

inner join (select AISCode, submissionid, severity, supplementarycode
			from SubmissionCodingView
			where aiscode between '450201' and '450214'
			or aiscode = '450804'
			--or aiscode between '750900' and '750972'
			) scv
			on scv.submissionid = p.SubmissionID

left join (select submissionID, QuestionID, Description EpiduralAnaesthetic from submissionsectionview s
			left join lookup on AnswerText = LookupName
			where S.QuestionID = 'INTER_PROC_PROC'
			and Description = 'Epidural Anaesthetic') Epi
			on epi.submissionID = p.submissionID

--***************Maydul's ChestWall Report code ************
LEFT JOIN (SELECT SubmissionID AngID, CAST([AGDate] + ' ' + LEFT(AGTime,2) + ':' + RIGHT(AGTime, 2) AS DATETIME) AS [ANLG DateTime], 
			ROW_NUMBER () OVER (PARTITION BY SUBMISSIONID ORDER BY CAST([AGDate] + ' ' + LEFT(AGTime,2) + ':' + RIGHT(AGTime, 2) AS DATETIME)) ANRNK,
			Description Analgesia FROM SubmissionSectionView S 

LEFT JOIN (SELECT SUBMISSIONID DATEID,
				SubmissionSectionID SDID,
				QUESTIONID,
				AnswerText AGDate
				FROM SubmissionSectionView 
				WHERE QuestionID = 'INTER_DATE_ANAL' 
				AND AnswerText LIKE '[12][0-9][0-9][0-9][01][0-9][0-3][0-9]') THD
				ON THD.SDID = S.SubmissionSectionID

LEFT JOIN (SELECT SUBMISSIONID TIMEID,
				 SubmissionSectionID STID,
				 QUESTIONID,
				 AnswerText AGTime 
				 FROM SubmissionSectionView
				 WHERE QuestionID = 'INTER_TIME_ANAL'
				 AND AnswerText LIKE '[012][0-9][0-5][0-9]') THT
				 ON THT.STID = S.SubmissionSectionID
	
JOIN Lookup ON ANSWERTEXT = LookupName
	WHERE  S.QuestionID = 'INTER_ANAL_ANALG' AND LookupTypeID = 'AnalgesiaName' AND CAST([AGDate] + ' ' + LEFT(AGTime,2) + ':' + RIGHT(AGTime, 2) AS DATETIME) IS NOT NULL) ANG
	ON P.SubmissionID = ANG.AngID
	AND ANRNK = '1'

LEFT JOIN (SELECT SubmissionID OpID, SubmissionSectionID SSOpID, DESCRIPTION OperDesc FROM SubmissionSectionView S JOIN Lookup ON ANSWERTEXT = LookupName 
	WHERE  S.QuestionID = 'INTER_PROC_PROC' AND Description = 'RIB FRACTURE FIXATION') OP 
	ON P.SubmissionID = OP.OpID
--*****************************************
where countryid in (1,2)
arvd between '20170101' and '20200228'


select * from #ribsdataset

--******************************************
--*****************Analgesia****************
--******************************************

Drop table #Analgesia
select distinct
caseID,
Intravenousopioid,
IntravenousParacetamol,
Entonox,
Ketamine,
Epidural,
Other,
[N/a]
into #Analgesia
from #ribsdataset
where aiscode not between '750900' and '750972'

 --Totals
Select
count(caseID) Total,
sum(Intravenousopioid) Intravenousopioid,
sum(IntravenousParacetamol) IntravenousParacetamol,
sum(Entonox) Entonox,
sum(Ketamine) Ketamine,
sum(Epidural) Epidural,
sum(Other) Other,
sum([N/a]) [n/a]
from #Analgesia

--Percentages
Select
(Round(100*cast(sum(Intravenousopioid) as float)/count(caseID),2)) [Intravenousopioid%],
(Round(100*cast(sum(IntravenousParacetamol) as float)/count(caseID), 2)) [IntravenousParacetamol%],
(Round(100*cast(sum(Entonox)as float)/count(caseID),2)) [Entonox%],
(Round(100*cast(sum(Ketamine)as float)/count(caseID),2)) [Ketamine%],
(Round(100*cast(sum(Epidural) as float)/count(caseID),2)) [Epidural%],
(Round(100*cast(sum(Other) as float)/count(caseID),2)) [Other%],
(Round(100*cast(sum([N/a]) as float)/count(caseID),2)) [n/a%]
from #Analgesia

/**************************************************************
********************Aggregation Tables**************************
**************************************************************/

--need to add median LOS
--median age, ISS, proportion with injuries, rib fractures listed, mortality, LOS median,  male


drop table #ribsagg
select 
caseID,
max(age) age,
max(male) male,
max(iss) ISS,
min(GCS) GCS,
avg(PS_14) PS14,
max(died) died,
sum(los) LOS,
sum(loscc) LOScc,
max(ribfixation) Ribfixation,
max(ribfractures) ribsfractured,
max(flailchest) Flail,
max(sternalfracture) Sternumfracture,
--max(ScapulaFracture) ScapulaFracture,
max(Intravenousopioid) Intravenousopioid,
max(IntravenousParacetamol) IntravenousParacetamol,
max(Entonox) Entonox,
max(Ketamine) Ketamine,
max(Epidural) Epidural,
max(Other) other,
max([n/a]) [n/a]

into #ribsagg
from #ribsdataset
group by caseid


--combined analgesia
select
flail,
sternumfracture,
ribfixation,
--ScapulaFracture,
sum(Intravenousopioid) Intravenousopioid,
sum(IntravenousParacetamol) IntravenousParacetamol,
sum(Entonox) Entonox,
sum(Ketamine) Ketamine,
sum(Epidural) Epidural,
sum(Other) other,
sum([n/a]) [n/a]
from #ribsagg
group by Flail, ribfixation, sternumfracture --,ScapulaFracture

--Totals
select
count(caseID) TotalChestwallpatients,
sum(flail) Flail,
sum(sternumfracture) Sternal,
sum(ribfixation) ribfixation
--sum(scapulafracture) Scapula
from #ribsagg

--LOS Median
select 
Ribfixation,
count(*)n,
case
	when elig % 2 = 1 then mediodd
	else (mediodd+medieven)/2
	end mediTT,
iqrLwr,
iqrUpr
from #ribsagg
left join (select medID, count(*)elig,
					  max(case when hemi = 2 then val else null end)mediodd,
					  min(case when hemi = 3 then val else null end)medieven,
					  min(case when hemi = 2 then val else null end)iqrLwr,
					  max(case when hemi = 3 then val else null end)iqrUpr
			   from (select Ribfixation medID, los val,
							ntile(4) over(partition by Ribfixation order by los)hemi
					 from #ribsagg
					 where LOS is not null)x
			group by medID) LOSmedian
			on medid = Ribfixation
group by Ribfixation, elig, mediodd, medieven, iqrupr, iqrlwr

--LOSCC median *******************************************CHECK THIS*******************************************
select 
Ribfixation,
count(*)n,
case
	when elig % 2 = 1 then mediodd
	else (mediodd+medieven)/2
	end mediLOSCC,
iqrLwr,
iqrUpr
from #ribsagg
left join (select medID, count(*)elig,
					  max(case when hemi = 2 then val else null end)mediodd,
					  min(case when hemi = 3 then val else null end)medieven,
					  min(case when hemi = 2 then val else null end)iqrLwr,
					  max(case when hemi = 3 then val else null end)iqrUpr
			   from (select Ribfixation medID, LOScc val,
							ntile(4) over(partition by Ribfixation order by losCC)hemi
					 from #ribsagg
					 where LOScc >0)x
			group by medID) LOSCCmedian
			on medid = Ribfixation
where LOscc >0
group by Ribfixation,elig, mediodd, medieven, iqrupr, iqrlwr

