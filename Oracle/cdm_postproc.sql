/* Post-processing tasks against the CDM
*/

/* Copy providerid from encounter table to diagnosis, procedures tables.
CDM specification says:
  "Please note: This is a field replicated from the ENCOUNTER table."
*/
merge into diagnosis d
using encounter e
   on (d.encounterid = e.encounterid)
when matched then update set d.providerid = e.providerid;

merge into procedures p
using encounter e
   on (p.encounterid = e.encounterid)
when matched then update set p.providerid = e.providerid;

merge into prescribing p
using encounter e
   on (p.encounterid = e.encounterid)
when matched then update set p.rx_providerid = e.providerid;

/* Currently in HERON, we have hight in cm and weight in kg - the CDM wants
height in inches and weight in pounds. */
update vital v set v.ht = v.ht / 2.54;
--update vital v set v.wt = v.wt * 2.20462; -- convert from kg to lbs
update vital v set v.wt = v.wt * 0.0625 -- UTHSCSA: convert from oz to lbs
/* Populate death table.  Eventually, we expect this to be added to the upstream
transform code.
Ref: https://github.com/SCILHS/i2p-transform/issues/3
*/
insert into death
select 
  pd.patient_num, pd.death_date, 'N' death_date_impute, 
  'UN' death_source, -- TODO: We have SSMDF and EMR sources at least
  'E' death_match_confidence 
from "&&i2b2_data_schema".patient_dimension pd
where pd.vital_status_cd = 'y';
