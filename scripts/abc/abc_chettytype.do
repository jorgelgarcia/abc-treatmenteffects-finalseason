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
global datanlsy    = "klmmexico/BPSeason2/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// open merged data
cd $dataabccare
use append-abccare_iv.dta, clear
cd $output
drop if random == 3 

// abc sample
// keep if program == "abc"
keep if wppsi5y != .

// children in control and treatment
summ R if R == 0
local controlN = r(N)
summ R if R == 1
local   treatN = r(N)

// treatment effect on IQ
reg wppsi5y R
matrix b = e(b)
matrix b = b[1,1]
matrix b = b/15

// discounted income at age 12, 2014 USD 
local inc2014  = 566717.69

// vary the return to iq
// discount to age 6 
local inc2014d = (`inc2014')/((1 + .03)^7)

clear
set obs 1000
generate uir = rnormal(.13,.10)
sort uir
drop if uir < 0

// generate cost-benefit cost ratio
gen     bc = (1 + uir*b[1,1])*(474617.143359)*`treatN' - (474617.143359)*`controlN'
// note bringing costs to age 5 and netting them 

replace bc = bc/((92570*`treatN' - 3057*`controlN')*(1 + .03)^5)

cd $output
#delimit
twoway (lowess bc uir, lwidth(thick) lpattern(solid) lcolor(gs0) xline(.131, lcolor(black) lpattern(dash))), 
		  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
		  xtitle("Earnings Return to 1 S.D. of Kindergarten IQ")  ytitle(Benefit Cost Rario, size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export abc_chettytype_return.eps, replace 

// vary present value of earnings
// vary the return to iq
// discount to age 6 

clear
set obs 1000
generate pv = rnormal(1000000,100000)
sort pv
drop if pv < 0

// generate cost-benefit cost ratio
gen     bc = (1 + .131*b[1,1])*pv*`treatN' - pv*`controlN'
// note bringing costs to age 5
di ((92570*`treatN' - 3057*`controlN')*(1 + .03)^5)

replace bc = bc/((96417*`treatN' - 1395*`controlN')*(1 + .03)^5)
replace pv = pv/100000

#delimit
twoway (lowess bc pv, lwidth(thick) lpattern(solid) lcolor(gs0)), 
		  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
		  xtitle("Present Value of Earnings in 100,000s")  ytitle(Benefit Cost Rario, size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export abc_chettytype_pv.eps, replace
