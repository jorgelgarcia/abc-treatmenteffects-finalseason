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

// get predicted at age 30
cd $collapseprj
use labor_income_collapsed_pset1_mset3.dta, clear
keep if age == 28 | age == 32

preserve
collapse (mean) mean_age, by(R)
gen per3mean_age = mean_age/.03
mkmat *, matrix(point)
tempfile point
save "`point'", replace
restore

preserve
collapse (mean) semean_age, by(R)
gen seper3mean_age = (1/(.03)^2)*semean_age
mkmat *, matrix(se)
restore

matrix all0 = [point[1,2...] \ se[1,2...]] 
matrix all1 = [point[2,2...] \ se[2,2...]] 
matrix all = [all0,all1]

// get actuals
cd $datanpvs
use labor_r-male-draw.dta, clear
egen labor_tot = rowtotal(labor_c22-labor_c67), missing
replace labor_tot = labor_tot/1000
keep labor_tot r
drop if labor_tot == . | r == .
collapse (mean) m=labor_tot (sd) se=labor_tot, by(r)
drop r 
mkmat *, matrix(real)


matrix rest = [[real[1,1] \ real[1,2]],[real[2,1] \ real[2,2]]]

matrix all = [all[1..2,1..2],rest[1..2,1],all[1..2,3..4],rest[1..2,2]]
matrix colnames all = pred30c perp30c npvc pred30t perp30t npvt
matrix rownames all = m se

cd $output
#delimit
outtable using mincerpred, 
mat(all) replace nobox center norowlab f(%9.3f);
#delimit cr
