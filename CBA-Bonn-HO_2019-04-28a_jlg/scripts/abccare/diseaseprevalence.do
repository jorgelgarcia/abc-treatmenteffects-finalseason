version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Predicted QALYs and Total Medical Costs
Description:    
*This version:  July 22, 2016
*This .do file: Jorge L. Garcia
*/

// set environment variables (server)
global erc: env erc
global projects: env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// set general locations
// do files
global scripts     = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datafam     = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/fam-merge/mergefiles/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"


cd $datafam
use health_projections_0720.dta, clear

replace mcrep = 0 if mcrep == .
drop if (bsrep == 0) & (mcrep > 1)
keep if bsrep == 0 & mcrep == 1
drop *_surv*
sort id

// id's file
preserve
# delimit 
keep id;
# delimit cr
tempfile ids
save   "`ids'", replace
restore

# delimit
global ToReshape cancre40-cancre65 diabe40-diabe65 hearte40-hearte65 
                 hibpe40-hibpe65 lunge40-lunge65 stroke40-stroke65 died40-died65;
# delimit cr

keep id $ToReshape 
reshape long cancre diabe hearte hibpe lunge stroke died, i(id) j(age)

tempfile health
save "`health'", replace

cd $dataabccare
use append-abccare_iv.dta, clear
keep id R male
tempfile IDMales
save "`IDMales'", replace

use "`health'", clear
merge m:1 id using "`IDMales'"
keep if _merge == 3
drop _merge

collapse (mean) cancre diabe hearte hibpe lunge stroke, by(male R)
mkmat *, matrix(famdiseases)
matrix famdiseases = famdiseases'

cd $output
#delimit
outtable using famdiseases, 
mat(famdiseases) replace nobox center f(%9.3f);
#delimit cr
