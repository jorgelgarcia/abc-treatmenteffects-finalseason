version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       CARE AND ABC
Description:    this .do file plots the ABC and CARE HRIs
*This version:  January 21, 2015
*This .do file: Jorge L. Garcia
*This project : HRI 
*/

// set environment variables (server)
global erc: env erc
global projects: env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// filepaths
global data	   	= "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global scripts    	= "$projects/abc-treatmenteffects-finalseason/scripts/"
global output      	= "$projects/abc-treatmenteffects-finalseason/output/"

// data
cd $data
use append-abccare_iv, clear
drop if R == 0 & RV == 1
keep if R == 0

factor  m_age_base m_ed_base m_iq_base hh_sibs_base m_married_base f_home_base
predict factorbase

// compare boys to girls
summ    factorbase, det
foreach num of numlist 0 1 {
	gen     factorbase`num' =.
	replace factorbase`num' = 1 if factorbase <= r(p25)                            & male == `num'
	replace factorbase`num' = 2 if factorbase  > r(p25) & factorbase <= r(p75)     & male == `num'
	replace factorbase`num' = 3 if factorbase  > r(p75) & factorbase <=.           & male == `num'
}

# delimit
twoway (histogram factorbase0 ,  discrete start(1) fraction  color(gs10) barwidth(.75))
       (histogram factorbase1 ,  discrete start(1) fraction fcolor(none) barwidth(.75) lcolor(black)),
	   legend(label(1 Girls) label(2 Boys))
	   xtitle("Percentiles in the Overall Distribution") ytitle(Fraction)
	   xlabel(1 "1-25" 2 "26-75" 3 "76-100", grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
	   graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
cd $output
graph export factorbase_girlsboyscompare.eps, replace

// compare girls home vs girls alternative
gen     alt = Q > 0 
replace alt = . if Q ==.
summ    factorbase if male == 1, det
foreach num of numlist 0 1 {
	gen     factorbasealtm`num' =.
	replace factorbasealtm`num' = 1 if factorbase <= r(p25)                            & male == 1 & alt == `num'
	replace factorbasealtm`num' = 2 if factorbase  > r(p25) & factorbase <= r(p75)     & male == 1 & alt == `num'
	replace factorbasealtm`num' = 3 if factorbase  > r(p75) & factorbase <=.           & male == 1 & alt == `num'
}

# delimit
twoway (histogram factorbasealtm0 ,  discrete start(1) fraction  color(gs10) barwidth(.75))
       (histogram factorbasealtm1 ,  discrete start(1) fraction fcolor(none) barwidth(.75) lcolor(black)),
	   legend(label(1 Home) label(2 Alternative))
	   xtitle("Percentiles in the Boys Distribution of (Non) Disadvantage") ytitle(Fraction)
	   xlabel(1 "1-25" 2 "26-75" 3 "76-100", grid glcolor(gs14)) ylabel(0[.2].6, angle(h) glcolor(gs14))
	   graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
cd $output
graph export factorbase_wboyscompare.eps, replace


// compare boys home vs boys alterntive
summ    factorbase if male == 0, det
foreach num of numlist 0 1 {
	gen     factorbasealtf`num' =.
	replace factorbasealtf`num' = 1 if factorbase <= r(p25)                            & male == 0 & alt == `num'
	replace factorbasealtf`num' = 2 if factorbase  > r(p25) & factorbase <= r(p75)     & male == 0 & alt == `num'
	replace factorbasealtf`num' = 3 if factorbase  > r(p75) & factorbase <=.           & male == 0 & alt == `num'
}

# delimit
twoway (histogram factorbasealtf0 ,  discrete start(1) fraction  color(gs10) barwidth(.75))
       (histogram factorbasealtf1 ,  discrete start(1) fraction fcolor(none) barwidth(.75) lcolor(black)),
	   legend(label(1 Home) label(2 Alternative))
	   xtitle("Percentiles in the Girls Distribution of (Non) Disadvantage") ytitle(Fraction)
	   xlabel(1 "1-25" 2 "26-75" 3 "76-100", grid glcolor(gs14)) ylabel(0[.2].6, angle(h) glcolor(gs14))
	   graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
cd $output
graph export factorbase_wgirlscompare.eps, replace

cd $dataabccare
use append-abccare_iv.dta, clear
keep if random == 0

replace Q = 0 if dc_mo_pre == 2 & random == 3
replace P = 0 if dc_mo_pre == 2 & random == 3
summ P if random == 3
summ P if random == 0
sort    Q
replace Q = Q/60
cumul   Q if random  == 0 & male == 1, gen(cdf_Q_pre_male)
cumul   Q if random  == 0 & male == 0, gen(cdf_Q_pre_female)


#delimit
twoway (line cdf_Q_pre_female    Q , lwidth(vthick) lcolor(gs0))
       (line cdf_Q_pre_male  Q , lwidth(vthick) lpattern(dash) lcolor(gs0))
      , 
		  legend(label(1 "Girls") label(2 "Boys"))
		  xlabel(, grid glcolor(gs14)) ylabel(0[.2]1, angle(h) glcolor(gs14))
		  xtitle("Proportion of Months in Alternatives, Control Group") ytitle(Cumulative Density Function)
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
cd $output
graph export abccare_controlcontamination_boysgirls.eps, replace
