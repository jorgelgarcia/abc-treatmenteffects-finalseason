version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC CBA
Description:    Qalys, ABC vs. PSID
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
global datafam     = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/fam-merge/mergefiles/current"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

cd $datafam
use health_projections_combined.dta, clear
keep id died* year*

gen diedage = 0
foreach num of numlist 32(1)122 {
	replace diedage = `num' if died`num' == 1
}

keep id diedage
tempfile diedage
save "`diedage'", replace

cd $dataabccare
use append-abccare_iv.dta, clear 
keep id D male
tempfile treat
save "`treat'", replace

use "`diedage'", clear
merge m:1 id using "`treat'"
keep if _merge !=  2
drop if D == .

// drop if diedage <= 50
collapse (mean) diedage (semean) sediedage = diedage, by(D male)
mkmat *, matrix(abccare)


// black in the usa
local males   = 60
local females = 74




/*

// bring weights from psid file
cd $datapsid
use psid-abc-match.dta, clear
keep id wtabc_allids
tempfile weights 
save "`weights'", replace

// bring gender from data file for psid inter/extrapolation
cd $output 
use psid_interextra.dta, clear 
tempfile psids
save "`psids'", replace

cd $datafam
use psid_qaly_imputed_abcsel.dta, clear
merge 1:1 id year using "`psids'"
keep if _merge == 3
drop _merge

merge m:1 id using "`weights'"`
keep if _merge != 2
drop _merge

keep if black == 1
keep if age >=35 & age <=75
replace qaly = qaly*.150

matrix est = J(1,2,.)
matrix colnames est = female male
foreach b of numlist 1(1)4 {
	preserve
	bsample
	collapse (mean) qaly, by(male age)
	collapse (sum)  qaly, by(male)
	mkmat qaly, matrix(est`b')
	matrix est`b' = est`b''
	matrix colnames est = female male
	matrix est = [est \ est`b']
	restore
}
matrix est = est[2...,1...]

clear
svmat est, names(col)
collapse (mean) psidestfem=female psidestmale=male (semean) psidsefem=female psidsemale=male
mkmat *, matrix(psidqalys)
matrix psidqalys = [[psidqalys[1,1],psidqalys[1,3]] \ [psidqalys[1,2],psidqalys[1,4]]]
matrix psidqalys = [[1 \ 4], psidqalys]
matrix colnames psidqalys = sample qaly qalyse

cd $dataqalys
use qaly_r-male-draw.dta, clear
egen    npvqaly = rowtotal(qaly*), missing
replace npvqaly = npvqaly/1000000
keep npvqaly r male

collapse (mean) qaly = npvqaly (semean) qalyse = npvqaly, by(male r)
gen sample = .
replace sample = 2 if male == 0 & r == 0
replace sample = 3 if male == 0 & r == 1

replace sample = 5 if male == 1 & r == 0
replace sample = 6 if male == 1 & r == 1

drop r male
mkmat sample qaly qalyse, matrix(expqalys)
matrix qalys = [psidqalys \ expqalys]
clear 
svmat qalys, names(col)
sort sample
gen maxqalys = qaly + qalyse 
gen minqalys = qaly - qalyse
gsort -sample
drop sample
gen sample = _n
replace sample = sample + 1 if sample > 3 

gen sample0 = .
replace sample0 = 1 if sample == 3
replace sample0 = 2 if sample == 2
replace sample0 = 3 if sample == 1

replace sample0 = 7 if sample == 5
replace sample0 = 6 if sample == 6
replace sample0 = 5 if sample == 7

drop sample
rename sample0 sample

cd $output
# delimit
twoway (bar qaly sample if sample == 1, color(gs0) barw(.98))
       (bar qaly sample if sample == 2, color(gs4) barw(.98))
       (bar qaly sample if sample == 3, color(gs8) barw(.98))
       (bar qaly sample if sample == 5, color(black) barw(.98))
       (bar qaly sample if sample == 6, color(gs4) barw(.98))
       (bar qaly sample if sample == 7, color(gs8) barw(.98))
       (rcap maxqaly minqaly sample, lcolor(gs0)),
       legend(cols(3) size(vsmall) order(1 "PSID, Disadvantaged" 2 "Control (Predicted)" 3 "Treatment (Predicted)" 7 "+/- s.e."))
		  xlabel(2 "Males" 6 " Females", labsize(small) noticks grid glcolor(white)) 
		  ylabel(4.8[.1]5.1, angle(h) glcolor(gs14))
		  xtitle(" ", size(small)) 
		  ytitle("QALYs (100,000s 2014 USD)", size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
# delimit cr
graph export qalyexppsid.eps, replace
