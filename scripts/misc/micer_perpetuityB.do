version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC
Description:    plot estimates conditional on IQ
*This version:  April 18, 2016
*This .do file: Jorge L. Garcia
*This project : All except Seong, B. and CC. 
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
global datanpvs    = "$klmmexico/abccare/NPV/"
global collapseprj  = "$klmmexico/abccare/income_projections/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// open merged data
cd $dataabccare
use append-abccare_iv.dta, clear
summ R
local N = r(N)

// get predicted at age 30
cd $datanpvs
use  labor_r-male-draw.dta, clear
egen labor30 = rowmean(labor_c28 labor_c29 labor_c31 labor_c32)
replace labor30 = labor30/1000
keep adraw r male labor30
gen  perp30 = labor30/.03

foreach num of numlist 0 1{
foreach var in labor perp {

	summ   `var'30 if r   == `num'
	local  `var'30_`num'm  = r(mean)
	local  `var'30_`num'sd = r(sd)
	local  `var'30_`num'se = ``var'30_`num'sd'/(sqrt(`N'))
	
	matrix `var'30_`num'  = [``var'30_`num'm' \ ``var'30_`num'se'] 
}
	matrix lper30_`num'   = [labor30_`num',perp30_`num']
}

// get actuals
cd $datanpvs
use labor_r-male-draw.dta, clear
egen labor_tot = rowtotal(labor_c22-labor_c67), missing
replace labor_tot = labor_tot/1000
keep labor_tot r
collapse (mean) m = labor_tot (sd) sd = labor_tot, by(r)
drop if r == .
drop r
replace sd = sd/`N'
mkmat *, matrix(npv)
matrix npv30_0 = [npv[1,1...]']
matrix npv30_1 = [npv[2,1...]']

foreach num of numlist 0 1 {
	matrix lpernpv30_`num' = [lper30_`num',npv30_`num']
}

matrix lpernpv = [lpernpv30_0 \ lpernpv30_1]

cd $output
#delimit
outtable using mincerpred, 
mat(lpernpv) replace nobox center norowlab f(%9.3f);
#delimit cr
