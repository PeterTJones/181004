-- Scapula fractures removed from dataset
--commented out on lines 112,124,231,282,291,300,307
/*
181004			
each analgesia group - median age, ISS, proportion with injuries, rib fractures listed, mortality, LOS median,  male, r

mortality in patients where analgesia and strong/regional analgesia is delayed, time till analgesia vs mortality 
(or expected mortality vs time till analgesia)
*/ 


--Patient inclusion & select table
If object_ID('tempdb..#select') is not null
drop table #select
select --count(distinct caseid) PtCount 
distinct p.submissionid
into #select
from pricache p
inner join (select AISCode, submissionid, severity, supplementarycode
			from SubmissionCodingView
			where aiscode between '450201' and '450214'
			or aiscode = '450804'
			or aiscode between '750900' and '750972'
			) scv
			on scv.submissionid = p.SubmissionID

where countryid in (1,2)
and dispatchDate < '20200529'
and arvd between '20170301' and '20200228'
and knownoutcome =1

--*********************************************************
--************Air and Breathing supp/status****************
--*********************************************************

If object_ID('tempdb..#Breathsupp') is not null
drop table ##Breathsupp
select SubmissionID, description, case when loc in ('At Scene', 'Enroute') then 'Pre-Hospital' else loc end Loc
into #breathsupp
from submissionsectionextview
inner join (select * from lookup 
			where lookuptypeid = 'BreathingSupport'
		) lk on lk.LookupName = AnswerText
where questionid ='INTER_BSUPP_VAL'
and submissionid in (select submissionid from #select)

If object_ID('tempdb..#Airsupp') is not null
drop table #Airsupp
select SubmissionID, description, case when loc in ('At Scene', 'Enroute') then 'Pre-Hospital' else loc end Loc
into #airsupp
from submissionsectionextview
inner join (select * from lookup 
			where lookuptypeid = 'AirwaySupport'
		) lk on lk.LookupName = AnswerText
where questionid ='INTER_AIRWAYSUPP'
and submissionid in (select submissionid from #select)

If object_ID('tempdb..#Airstatus') is not null
drop table #Airstatus
select SubmissionID, description, case when loc in ('At Scene', 'Enroute') then 'Pre-Hospital' else loc end Loc
into #airstatus
from submissionsectionextview
inner join (select * from lookup 
			where lookuptypeid = 'AirwayStatus'
		) lk on lk.LookupName = AnswerText
where questionid ='ASSESS_AIRWAYS_VAL'
and submissionid in (select submissionid from #select)

If object_ID('tempdb..#Breathstatus') is not null
drop table #breathstatus
select SubmissionID, description, case when loc in ('At Scene', 'Enroute') then 'Pre-Hospital' else loc end Loc
into #Breathstatus
from submissionsectionextview
inner join (select * from lookup
			where lookuptypeid = 'BreathingStatus'
		) lk on lk.LookupName = AnswerText
where questionid ='ASSESS_BREATHS_VAL'
and submissionid in (select submissionid from #select)

--*********************************************************
--***********************Main Table************************
--*********************************************************

If object_ID('tempdb..#ribsdataset') is not null
drop table #ribsdataset
select 
p.SubmissionID,caseID,countryid, dispatchdate, crank,
knownoutcome, mtc,arvdt,age,sex,
case when sex = 'male' then 1 else 0 end as Male,
charl,ISS,issband,GCS,intubvent,Ps14, psONS,died,los,loscc,mech,mechtype,
ttype, transfertype, Injuries,OperDesc operation, OpDT,
HospBreathSupp, HospAirwaySupp, HospBreathStatus, HospAirwayStatus,
PrehospBreathSupp,PrehospAirwaySupp, PrehospBreathStatus, prehospAirwayStatus, 
case	when OperDesc = 'Rib fracture fixation' then 1	else 0	end as RibFixation,
AnalgesiaLoc,
isnull (CAST([ANLG DateTime] AS datetime), '2100-01-01 00:01:00.000') AnlgDT,
Analgesia,
case when Analgesia is null and EpiduralAnaesthetic is null then 1 
	else 0
 end NoAnalgesia,
case when EpiduralAnaesthetic is not null then 1
	else 0
	end as EpiduralAnaesthetic,
case when Analgesia is null and EpiduralAnaesthetic is not null then 'Epidural'
	when Analgesia = 'other' and EpiduralAnaesthetic is not null then 'Epidural'
	when Analgesia is null and EpiduralAnaesthetic is null then 'N/a'
	else Analgesia
	end as CombAnalgesia,
case when Analgesia is null and EpiduralAnaesthetic is null then 1
	else 0
	end as [N/a],
case when analgesia = 'Intravenous opioid' then 1
	else 0
	end as Intravenousopioid,
case when  analgesia = 'Intravenous paracetamol' then 1
	else 0
	end as IntravenousParacetamol,
case when analgesia = 'Entonox' then 1
	else 0
	end as Entonox,
case when analgesia = 'Ketamine' then 1
	else 0
	end as Ketamine,
case when Analgesia = 'Epidural block' then 1
	when Analgesia = 'other' and EpiduralAnaesthetic is not null then 1
	when Analgesia is null and EpiduralAnaesthetic is not null then 1
	else 0
	end as Epidural,
case when Analgesia in ('Other','Patient controlled Intravenous Opioid (PCA)',
						'Local anaesthetic blockade (non epidural/paravertebral)',
						'Paravertebral block','Local anaesthetic patches','Methoxyflurane') 
	then 1 else 0
	end as Other,
case when supplementarycode in ('62','72','82') then 1 else 0
	end UnknownNoRibFractures,
RibFractures,
case when aiscode between '450209' and '450214' then 1
	else 0
	end as FlailChest,
case when aiscode = '450804' then 1
	else 0
	end as SternalFracture

into #ribsdataset
from PRIcache P

left join (select AISCode, submissionid, severity, supplementarycode,
			sum(case 
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
				end) over (partition by submissionid) RibFractures
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

---------------------------
LEFT JOIN (SELECT SubmissionID AngID, CAST([AGDate] + ' ' + LEFT(AGTime,2) + ':' + RIGHT(AGTime, 2) AS DATETIME) AS [ANLG DateTime], 
			ROW_NUMBER () OVER (PARTITION BY SUBMISSIONID ORDER BY CAST([AGDate] + ' ' + LEFT(AGTime,2) + ':' + RIGHT(AGTime, 2) AS DATETIME)) ANRNK,
			Description Analgesia, loc AnalgesiaLoc
		FROM SubmissionSectionExtView S 

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

		WHERE  S.QuestionID = 'INTER_ANAL_ANALG' AND LookupTypeID = 'AnalgesiaName' 
		AND CAST([AGDate] + ' ' + LEFT(AGTime,2) + ':' + RIGHT(AGTime, 2) AS DATETIME) IS NOT NULL
) ANG ON P.SubmissionID = ANG.AngID 
----------------------------

LEFT JOIN (SELECT S.SubmissionID OpID, S.SubmissionSectionID SSOpID, DESCRIPTION OperDesc, OpDT
			FROM SubmissionSectionView S
			left join(select Date.submissionid, date.submissionsectionid,
							 cast([answertext] + ' ' + LEFT(Optime,2) + ':' + RIGHT(OpTime, 2) as datetime) OpDT
						from SubmissionSectionExtView Date
						inner join(	select submissionid, submissionsectionid, answertext OpTime
									from SubmissionSectionExtView
									where QuestionID = 'INTER_TIME'
									and AnswerText LIKE '[012][0-9][0-5][0-9]'
								) tme on tme.SubmissionSectionID = date.SubmissionSectionID and tme.SubmissionID = date.SubmissionID
						where questionid = 'Inter_date'
						and AnswerText LIKE '[12][0-9][0-9][0-9][01][0-9][0-3][0-9]'
					) OpDT on OpDT.SubmissionSectionID = S.SubmissionSectionID and OPDT.SubmissionID = S.SubmissionID
			inner join (select * from Lookup 
						where LookupTypeID = 'OperativeProcedure'
					)Lk ON ANSWERTEXT = LookupName 
			WHERE  S.QuestionID = 'INTER_PROC_PROC' AND Description = 'RIB FRACTURE FIXATION'
	) OP ON P.SubmissionID = OP.OpID

---------------------------

left join(	select distinct submissionid, 
			stuff((select ', ' + t.[description]
       				from #breathsupp t
       				where t.SubmissionID = #breathsupp.SubmissionID
					and loc = 'Pre-Hospital'
					order by t.[Description]
       				for xml path('')
 				),1,1,'') as PrehospBreathSupp,
			stuff((select ', ' + t.[description]
       				from #breathsupp t
       				where t.SubmissionID = #breathsupp.SubmissionID
					and loc != 'Pre-Hospital'
					order by t.[Description]
       				for xml path('')
 				),1,1,'') as HospBreathSupp
			from #breathsupp
	) Bsu on Bsu.SubmissionID = p.SubmissionID
left join(	select distinct submissionid, 
			stuff((select ', ' + t.[description]
       				from #AirSupp t
       				where t.SubmissionID = #AirSupp.SubmissionID
					and loc = 'Pre-Hospital'
					order by t.[Description]
       				for xml path('')
 				),1,1,'') as PrehospAirwaySupp,
			stuff((select ', ' + t.[description]
       				from #AirSupp t
       				where t.SubmissionID = #AirSupp.SubmissionID
					and loc != 'Pre-Hospital'
					order by t.[Description]
       				for xml path('')
 				),1,1,'') as HospAirwaySupp
			 from #airsupp
		)AwSu on AwSu.SubmissionID = p.SubmissionID
left join(	select distinct submissionid, 
			stuff((select ', ' + t.[description]
       				from #AirStatus t
       				where t.SubmissionID = #AirStatus.SubmissionID
					and loc = 'Pre-Hospital'
					order by t.[Description]
       				for xml path('')
 				),1,1,'') as PrehospAirwayStatus,
			stuff((select ', ' + t.[description]
       				from #AirStatus t
       				where t.SubmissionID = #AirStatus.SubmissionID
					and loc != 'Pre-Hospital'
					order by t.[Description]
       				for xml path('')
 				),1,1,'') as HospAirwayStatus 
			from #airstatus
		)AwSt on AwSt.SubmissionID = p.SubmissionID
left join(	select distinct submissionid, 
			stuff((select ', ' + t.[description]
       				from #BreathStatus t
       				where t.SubmissionID = #BreathStatus.SubmissionID
					and loc = 'Pre-Hospital'
					order by t.[Description]
       				for xml path('')
 				),1,1,'') as PrehospBreathStatus,
			stuff((select ', ' + t.[description]
       				from #BreathStatus t
       				where t.SubmissionID = #BreathStatus.SubmissionID
					and loc != 'Pre-Hospital'
					order by t.[Description]
       				for xml path('')
 				),1,1,'') as HospBreathStatus
			from #Breathstatus
		) BSt on BSt.SubmissionID = p.SubmissionID

where p.submissionid in (select submissionid from #select)

--******************************************
--******************************************
--******************************************

--select count(distinct caseid)
--from #ribsdataset
--where CombAnalgesia = 'N/a'


select  count(distinct caseid)
 from #ribsdataset
 where Analgesia is null or EpiduralAnaesthetic is null



--******************************************
--*****************Analgesia****************
--******************************************
If object_ID('tempdb..#Analgesia') is not null
Drop table #Analgesia
select distinct
caseID,
max(case when Analgesia is null or EpiduralAnaesthetic is null then 1 else 0 end) NoAnalgesia,
max(Intravenousopioid)Intravenousopioid,
max(IntravenousParacetamol) IntravenousParacetamol,
max(Entonox) Entonox,
max(Ketamine) Ketamine,
max(Epidural) Epidural,
max(Other) Other,
max([N/a])[N/a]
into #Analgesia
from #ribsdataset
group by caseid

 --Totals
Select
count(distinct caseID) Total,
sum(NoAnalgesia) NoAnalgesia,
sum(Intravenousopioid) Intravenousopioid,
sum(IntravenousParacetamol) IntravenousParacetamol,
sum(Entonox) Entonox,
sum(Ketamine) Ketamine,
sum(Epidural) Epidural,
sum(Other) Other
from #Analgesia

--Percentages
Select
(Round(100*cast(sum(NoAnalgesia)as float)/count(caseID),2)) [NoAnalgesia],
(Round(100*cast(sum(Intravenousopioid) as float)/count(caseID),2)) [Intravenousopioid%],
(Round(100*cast(sum(IntravenousParacetamol) as float)/count(caseID), 2)) [IntravenousParacetamol%],
(Round(100*cast(sum(Entonox)as float)/count(caseID),2)) [Entonox%],
(Round(100*cast(sum(Ketamine)as float)/count(caseID),2)) [Ketamine%],
(Round(100*cast(sum(Epidural) as float)/count(caseID),2)) [Epidural%],
(Round(100*cast(sum(Other) as float)/count(caseID),2)) [Other%]
from #Analgesia

/*********************************************************
********************AISCODEs for Sev**********************
*********************************************************/

If object_id('tempdb..#AISbody') is not null
drop table #AISBody
select	submissionid AISID,
		max(case when bodyarea = 1 then severity else 0 end) AISHead,
		max(case when bodyarea = 2 then severity else 0 end) AISFace,
		max(case when bodyarea = 3 then severity else 0 end) AISThorax,
		max(case when bodyarea = 4 then severity else 0 end) AISAbdomen,
		max(case when bodyarea = 5 then severity else 0 end) AISLimb,
		max(case when bodyarea = 6 then severity else 0 end) AISExternal
into #AISbody
from (		select distinct submissionid, bodyarea, severity,
			dense_rank() over (partition by submissionid, bodyarea order by severity desc) AISAreaRnk --Ranks all injuries within a body region,
			from submissioncodingview
			where submissionid in (select submissionid from #select)
	) A
where AISAreaRnk =1
group by submissionid


/**************************************************************
********************Aggregation Table**************************
**************************************************************/


If object_ID('tempdb..#ribsagg') is not null
drop table #ribsagg
select 
#ribsdataset.caseID,
max(age) age,
max(male) male,
max(AISHead)AISHead ,
max(AISFace)AISFace,
max(AISThorax)AISThorax,
max(AISAbdomen)AISAbdomen,
max(AISLimb) AISLimb,
max(AISExternal)AISExternal,
max(iss) ISS,
min(GCS) GCS,
max(charl) charl,
max(Ps14) PS14,
max(psONS) PS_14WithImputation,
max(died) died,
sum(los) LOS,
sum(loscc) LOScc,
max(flailchest) Flail,
max(sternalfracture) Sternumfracture,
max(UnknownNoRibFractures) UnknownNoRibFractures,
max(ribfractures) ribfractures,
max(ribfixation) ribfixation,
min(TimetoRibFixation) TimetoRibFixation,
--max(ScapulaFracture) ScapulaFracture,
max(case when analgesialoc in('At Scene','Enroute') then 1 else 0 end) AnalgesiaPrehospital, 
min(case when TimetoAnalgesia >'40000000' then Null
	when TimetoAnalgesia < 0 then Null --Prevents negative values (not anomalous, just pre hosp ones)
	 else TimetoAnalgesia end) TimetoAnalgesia, -- this removes earlier Null values from calculation
max(case when Analgesia is null or EpiduralAnaesthetic is null then 1 else 0 end) NoAnalgesia,
max(Intravenousopioid) Intravenousopioid,
max(IntravenousParacetamol) IntravenousParacetamol,
max(Entonox) Entonox,
max(Ketamine) Ketamine,
max(Epidural) Epidural,
max(Other) other,
max(PHBS) PrehospBreathSupp, max(PHAS)PrehospAirwaySupp,
max(PHBST) PrehospBreathStatus,max(PHAST) PrehospAirwayStatus,
max(HospBreathSupp) HospBreathSupp, max(HospAirwaySupp) HospAirwaySupp,
max(HospBreathStatus) HospBreathStatus, max(HospAirwayStatus) HospAirwayStatus

into #ribsagg
from #ribsdataset
left join #AISbody on AISid = SubmissionID
left join(	select caseid, 
			datediff(minute, min(arvdt) , min(AnlgDT)) TimetoAnalgesia,
			datediff(minute, min(arvdt), min(opdt))TimetoRibFixation
			from #ribsdataset
			group by caseid
		) Timeto on Timeto.caseid = #ribsdataset.caseid
left join(	select submissionid, PrehospBreathSupp PHBS,PrehospAirwaySupp PHAS, PrehospBreathStatus PHBSt, prehospAirwayStatus PHASt
			from #ribsdataset
			where crank =1 
		)  PH on Ph.SubmissionID = #ribsdataset.SubmissionID
group by #ribsdataset.caseid

select * from #ribsagg

/************************************************
*****************Analysis tables*****************
************************************************/

--combined analgesia
select
flail,
sternumfracture,
ribfixation,
--ScapulaFracture,
sum(NoAnalgesia) NoAnalgesia,
sum(Intravenousopioid) Intravenousopioid,
sum(IntravenousParacetamol) IntravenousParacetamol,
sum(Entonox) Entonox,
sum(Ketamine) Ketamine,
sum(Epidural) Epidural,
sum(Other) Other
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


-----------------------------------------------------------
------------------Rib Fixation LOS-------------------------
-----------------------------------------------------------
--LOS Median
select 
Ribfixation,
count(*)n,
case
	when elig % 2 = 1 then mediodd
	else (mediodd+medieven)/2
	end mediLOS,
iqrLwr,
iqrUpr
from #ribsagg
left join (select medID, count(*)elig,
					  max(case when hemi = 2 then val else null end)mediodd,
					  min(case when hemi = 3 then val else null end)medieven,
					  min(case when hemi = 2 then val else null end)iqrLwr,
					  max(case when hemi = 3 then val else null end)iqrUpr
			   from (select RIBfixation medID, los val,
							ntile(4) over(partition by RIBfixation order by los)hemi
					 from #ribsagg
					 where LOS is not null)x
			group by medID) LOSmedian
			on medid = RIBfixation
group by RIBfixation, elig, mediodd, medieven, iqrupr, iqrlwr
order by 1 asc

--LOSCC median 
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
			   from (select RIBfixation medID, LOScc val,
							ntile(4) over(partition by RIBfixation order by losCC)hemi
					 from #ribsagg
					 where LOScc >0)x
			group by medID) LOSCCmedian
			on medid = RIBfixation
where LOscc >0
group by Ribfixation,elig, mediodd, medieven, iqrupr, iqrlwr
order by 1 asc

-----------------------------------------------------------
---------------------Flail LOS-----------------------------
-----------------------------------------------------------
--LOS Median
select 
Flail,
count(*)n,
case
	when elig % 2 = 1 then mediodd
	else (mediodd+medieven)/2
	end mediLOS,
iqrLwr,
iqrUpr
from #ribsagg
left join (select medID, count(*)elig,
					  max(case when hemi = 2 then val else null end)mediodd,
					  min(case when hemi = 3 then val else null end)medieven,
					  min(case when hemi = 2 then val else null end)iqrLwr,
					  max(case when hemi = 3 then val else null end)iqrUpr
			   from (select Flail medID, los val,
							ntile(4) over(partition by Flail order by los)hemi
					 from #ribsagg
					 where LOS is not null)x
			group by medID) LOSmedian
			on medid = Flail
group by Flail, elig, mediodd, medieven, iqrupr, iqrlwr
order by 1 asc

--LOSCC median  
select
Flail,
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
			   from (select Flail medID, LOScc val,
							ntile(4) over(partition by Flail order by losCC)hemi
					 from #ribsagg
					 where LOScc >0)x
			group by medID) LOSCCmedian
			on medid = Flail
where LOscc >0
group by Flail,elig, mediodd, medieven, iqrupr, iqrlwr
order by 1 asc
--*********************************************************
--*********************************************************
--*********************************************************
