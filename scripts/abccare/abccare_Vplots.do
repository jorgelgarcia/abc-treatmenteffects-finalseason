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
global datapsid    = "$klmshare/Data_Central/data-repos/psid/base/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// open merged data
cd $dataabccare
use append-abccare_iv.dta, clear
cd $output

// abc sample
drop if random == 3
drop if R != 0
keep if P == 1

// binned density
egen Qbinned = cut(Q), group (8)
replace Qbinned = (Qbinned + 1)/8

#delimit
twoway (kdensity Qbinned, lwidth(medthick) lpattern(solid) lcolor(gs0) bwidth(.15))
        , 
		  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
		  xtitle("Proportion of Months in Alternative Preschool from Ages 0 to 5") ytitle(Density, size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export abccare_Vdensity.eps, replace

drop if dc_mo_pre != Q

// use per age
matrix pdc = J(1,3,.)
matrix colnames pdc = age p dc
foreach num of numlist 1(1)5 {
	gen p_mo_pre`num' = . if dc_mo_pre`num' !=.
	replace p_mo_pre`num' = 0 if dc_mo_pre`num' == 0
	replace p_mo_pre`num' = 1 if dc_mo_pre`num'  > 0 & dc_mo_pre`num' !=.
	summ p_mo_pre`num'
	local p`num'  = r(mean)
	summ dc_mo_pre`num' if dc_mo_pre`num' > 0
	local dc`num' = r(mean)  
	matrix pdc`num' = [`num',`p`num'',`dc`num'']
	matrix colnames pdc`num' = age p dc
	mat_rapp pdc : pdc pdc`num'
}
matrix pdc = pdc[2...,1...]

preserve
clear
svmat pdc`num', names(col)

#delimit
twoway (scatter p  age, msymbol(circle) mfcolor (gs4) mlcolor(gs4) connect(l) lwidth(thick) lpattern(solid) lcolor(gs4) yaxis(1))
       (scatter dc age, msymbol(square) mfcolor (gs8) mlcolor(gs8) connect(l) lwidth(thick) lpattern(dash)  lcolor(gs8) yaxis(2))
        , 
		  legend(label(1 "Fraction Enrolled | Enrollment > 0") label(2 "Average Months| Enrollment > 0") size(small))
		  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle(Enrollment, axis(1)) ytitle("Avg. Months | Enrollment > 0", axis(2))
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export abccare_Valtenrollment.eps, replace
restore

// percentage of time usage
// preserve
keep id p_mo_pre1 p_mo_pre2 p_mo_pre3 p_mo_pre4 p_mo_pre5 
reshape long p_mo_pre, i(id) j(age)
xtset id age

bysort id : egen p_mo_mean = mean(p_mo_pre)
duplicates drop id, force

summ p_mo_pre
local total = r(N)

egen p_mo_cat = cut(p_mo_mean), group(6)
tab p_mo_cat, gen(p_mo_cat_)

matrix cats = [.]
foreach var of varlist p_mo_cat_* { 
	summ `var'
	matrix cats = [cats \ r(mean)]
}
matrix cats = cats[2...,1...]
clear
svmat cats

gen prop = _n
replace prop = prop/5

#delimit
twoway (bar cats prop, color(gs0) lwidth(medthick) barw(.1))
        , 
		  xlabel(, grid glcolor(gs14)) ylabel(0[.1].4, angle(h) glcolor(gs14))
		  xtitle("Proportion of Months in Alternative Preschool from Ages 0 to 5") ytitle(Fraction, size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export abccare_Vfractimes.eps, replace

// open merged data
cd $dataabccare
use append-abccare_iv.dta, clear
cd $output

// abc sample
drop if random == 3
drop if R != 0

foreach num of numlist 1(1)5 {
	gen p_mo_pre`num' = . if dc_mo_pre`num' !=.
	replace p_mo_pre`num' = 0 if dc_mo_pre`num' == 0
	replace p_mo_pre`num' = 1 if dc_mo_pre`num'  > 0 & dc_mo_pre`num' !=.
}

matrix bage = [.,.]
matrix colnames bage = age prob
foreach num of numlist 1(1)4 {
	local num1 = `num' + 1
	reg p_mo_pre`num1' p_mo_pre`num', nocons
	matrix b = e(b)
	matrix b = b[1,1]
	matrix bage`num' = [`num1',b[1,1]]
	matrix colnames bage = age prob
	matrix bage = [bage \ bage`num']
}
matrix bage = bage[2...,1...]

preserve
clear
svmat bage, names(col)

cd $output
#delimit
twoway (bar prob age, color(gs0) lwidth(medthick) barw(.5))
        , 
		  xlabel(, grid glcolor(gs14)) ylabel(.5[.1]1, angle(h) glcolor(gs14))
		  xtitle("Age") ytitle(Fraction Enrolled | Enrolled Previous Year, size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export abccare_Vprobs.eps, replace
restore
