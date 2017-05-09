version 12.0
set seed 1234
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
global scripts     = "$projects/abccare-cba/scripts/"
// ready data
global dataqalys   = "$klmmexico/abccare/NPV/current"
global datapsid    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global datafam     = "$klmmexico/abccare/health_plots"
global datainterextra = "$klmmexico/abccare/psid"
// output
global output      = "$projects/abccare-cba/output/"

// bring weights from psid file
cd $datapsid
use psid-abc-match.dta, clear
keep id wtabc_allids
tempfile weights 
save "`weights'", replace

// bring gender from data file for psid inter/extrapolation
cd $datainterextra
use psid_interextra.dta, clear 
tempfile psids
save "`psids'", replace

cd $datafam
use psid_qaly_imputed_abcsel.dta, clear
merge 1:1 id year using "`psids'"
keep if _merge == 3
drop _merge

merge m:1 id using "`weights'"
keep if _merge != 2
drop _merge

keep if black == 1
keep if age >=34 & age <= 108
replace qaly = qaly*.15

matrix est = J(1,2,.)
matrix colnames est = female male
foreach b of numlist 1(1)200 {
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

tab id if male == 0
local sample5_n = r(r)
tab id if male == 1
local sample1_n = r(r)

clear
svmat est, names(col)
collapse (mean) psidestfem=female psidestmale=male (sd) psidsefem=female psidsemale=male
mkmat *, matrix(psidqalys)
matrix psidqalys = [[psidqalys[1,1],psidqalys[1,3]] \ [psidqalys[1,2],psidqalys[1,4]]]
matrix psidqalys = [[1 \ 4], psidqalys]
matrix colnames psidqalys = sample qaly qalyse

cd $dataqalys
use qaly_r-male-draw.dta, clear
egen    npvqaly = rowtotal(qaly*), missing
replace npvqaly = npvqaly/1000000
keep npvqaly r male

collapse (mean) qaly = npvqaly (sd) qalyse = npvqaly, by(male r)
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

local sample2_n = 39
local sample3_n = 38
local sample6_n = 40
local sample7_n = 37

gen sample0 = .
replace sample0 = 1 if sample == 3
replace sample0 = 2 if sample == 2
replace sample0 = 3 if sample == 1

replace sample0 = 7 if sample == 5
replace sample0 = 6 if sample == 6
replace sample0 = 5 if sample == 7

drop sample
rename sample0 sample

// t-tests
sum qaly if sample == 1
local sample1_mean = r(mean)
sum qalyse if sample == 1
local sample1_sd = r(mean) * sqrt(`sample1_n')

forvalues j = 2/3 {
	sum qaly if sample == `j'
	local sample`j'_mean = r(mean)
	sum qalyse if sample == `j'
	local sample`j'_sd = r(mean) * sqrt(`sample`j'_n')
	ttesti `sample`j'_n' `sample`j'_mean' `sample`j'_sd' `sample1_n' `sample1_mean' `sample1_sd', unequal welch
}

sum qaly if sample == 5
local sample5_mean = r(mean)
sum qalyse if sample == 5
local sample5_sd = r(mean)

forvalues j = 6/7 {
	sum qaly if sample == `j'
	local sample`j'_mean = r(mean)
	sum qalyse if sample == `j'
	local sample`j'_sd = r(mean) * sqrt(`sample`j'_n')
	ttesti `sample`j'_n' `sample`j'_mean' `sample`j'_sd' `sample5_n' `sample5_mean' `sample5_sd', unequal welch
}


cd $output
# delimit
twoway (bar qaly sample if sample == 1, color(gs0) barw(.98))
       (bar qaly sample if sample == 2, color(gs4) barw(.98))
       (bar qaly sample if sample == 3, color(gs8) barw(.98))
       (bar qaly sample if sample == 5, color(black) barw(.98))
       (bar qaly sample if sample == 6, color(gs4) barw(.98))
       (bar qaly sample if sample == 7, color(gs8) barw(.98))
       (scatter qaly sample if sample != 2, mcol(black) msize(large)),
       legend(cols(3) size(vsmall) order(1 "PSID, Disadvantaged" 2 "Control (Predicted)" 3 "Treatment (Predicted)" 7 "p-value {&le} 0.10"))
		  xlabel(2 "Males" 6 " Females", labsize(small) noticks grid glcolor(white)) 
		  ylabel(5[.1]5.4, angle(h) glcolor(gs14))
		  xtitle(" ", size(small)) 
		  ytitle("QALYs (100,000s 2014 USD)", size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
# delimit cr
graph export qalyexppsid.eps, replace
