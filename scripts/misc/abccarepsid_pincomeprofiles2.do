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
global scripts      = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global collapseprj  = "$klmmexico/abccare/income_projections/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global datacnlsyw   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global datanlsyw    = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/"
global datapsidp    = "$klmshare/Data_Central/data-repos/psid/base"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global weights      = "$klmmexico/abccare/as_weights"
// output
global output       = "$projects/abc-treatmenteffects-finalseason/output/"

// ABC/CARE
// get parental income profile
cd $dataabccare
use append-abccare_iv.dta, clear
keep if random != 3

replace m_ed4y6m = m_ed0y if m_ed4y6m == .
# delimit 
keep id birthyear hh_sibs4y6m m_ed4y6m R male m_age0y p_inc0y p_inc1y6m p_inc2y6m p_inc3y6m p_inc4y6m
	f_home0y f_home1y6m f_home2y6m f_home3y6m f_home4y6m f_home5y
	m_work0y m_work1y6m m_work2y6m m_work3y6m m_work4y6m m_work5y;
# delimit cr

rename hh_sibs4y6m hhchildren
gen m_birthyear = birthyear - m_age0y
drop birthyear
rename m_ed4y6m m_ed
rename p_inc0y    p_inc1
rename p_inc1y6m  p_inc2
rename p_inc2y6m  p_inc3
rename p_inc3y6m  p_inc4 
rename p_inc4y6m  p_inc5 

rename f_home0y f_home1
rename f_home1y6m f_home2 
rename f_home2y6m f_home3 
rename f_home3y6m f_home4 
rename f_home4y6m f_home5 

rename m_work0y   m_work1
rename m_work1y6m m_work2 
rename m_work2y6m m_work3 
rename m_work3y6m m_work4 
rename m_work4y6m m_work5 

// split income in two if father at home and mother works (~10% of sample)
reshape long p_inc f_home m_work, i(id) j(age)
replace p_inc = p_inc/2 if m_work == 1 & f_home == 1
gen m_age = m_age0y + age
gen m_experience  = m_age - m_ed - 6
gen m_experience2 = (m_experience)^2

// micer regression in the ABC/CARE sample
gen logp_inc = log(p_inc + 1)

// age, income, and education ranges
foreach var of varlist p_inc m_ed m_age hhchildren {
	summ `var'
	local min`var' = r(min)
	summ `var'
	local max`var' = r(max)
}
gen abccare = 1
tempfile abccare_pincome
save   "`abccare_pincome'"

// PSID
cd $datapsidp
use psid-base.dta, clear
keep if male == 0 & black == 1
keep id birthyear f_home* edu inc_labor* works* married* hhchildren*
reshape long f_home inc_labor works married hhchildren, i(id) j(year)
rename edu m_ed
rename works m_work
rename inc_labor p_inc
rename birthyear m_birthyear
rename married m_married
keep if m_married == 0

gen m_age = year - m_birthyear
gen m_experience  = m_age - m_ed - 6
gen m_experience2 = (m_experience)^2


// truncate to ABC/CARE ranges
foreach var of varlist p_inc m_ed m_age hhchildren {
	keep if `var' >= `min`var'' & `var' <= `max`var'' 
}
gen logp_inc = log(p_inc + 1)
gen abccare = 0

// append abc care 
append using "`abccare_pincome'"
drop if p_inc == 0
summ p_inc if abccare == 0, d
drop if p_inc >= r(p75) & abccare == 0

tempfile psidabc
save   "`psidabc'", replace

/*
// mincer equations
foreach num of numlist 0 1 {
	reg lp_inc m_ed if abccare == `num', robust
	matrix          ed`num'       = e(b)
	matrix colnames ed`num'       = b1_m_ed_abccare`num' b1_cons_abccare`num'
	est sto         ed`num'
	
	reg lp_inc m_ed m_experience m_experience2 if abccare == `num', robust
	est sto         edexp`num'
	matrix          edexp`num'    = e(b)
	matrix colnames edexp`num'    = b2_m_ed_abccare`num' b2_m_experience_abccare`num' b2_m_experience2_abccare`num' b2_cons_abccare`num'
	
	reg lp_inc m_ed m_experience m_experience2 m_birthyear hhchildren if abccare == `num'
	est sto         edexpsib`num'
	matrix          edexpsib`num' = e(b)
	matrix colnames edexpsib`num' = b3_m_ed_abccare`num' b3_m_experience_abccare`num' b3_m_experience2_abccare`num' b3_m_birthyear`num' b3_hhchildren_abccare`num' b3_cons_abccare`num'
	
}

cd $output
outreg2 [ed0 ed1 edexp0 edexp1 edexpsib0 edexpsib1] using abccarepsid_mincerests, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(4) par(se) r2 nonotes

// bootstrap starts here. 
// construct matrix to then calculate treatment effects based on parameters
matrix psid_parameters = [ed0,edexp0,edexpsib0]
use "`abccare'", clear

// generate each of the three NPV estimates
gen predyearsworked = 65 - m_age0y
gen predyearsworkedfactor = 1/2*predyearsworked*(predyearsworked + 1)


collapse (mean) m_ed predyearsworkedfactor m_birthyear hhchildren, by(R male)
svmat psid_parameters, names(col)

// parametrize vectors
foreach var of varlist b1_* b2_* b3_* {
	summ `var'
	gen  `var'_r = r(mean)
	drop `var' 
	rename `var'_r `var'
}


# delimit
gen NPV1 = b1_m_ed_abccare0*m_ed + b1_cons_abccare0; 
gen NPV2 = b2_m_ed_abccare0*m_ed + b2_m_experience_abccare0*predyearsworked + b2_m_experience2_abccare0*predyearsworked + b2_cons_abccare0; 
gen NPV3 = b3_m_ed_abccare0*m_ed + b3_m_experience_abccare0*predyearsworked + b3_m_experience2_abccare0*predyearsworked + b3_m_birthyear0*m_birthyear + b3_hhchildren_abccare0*hhchildren + b3_cons_abccare0;
# delimit cr

/*
// plot profiles 
replace R = 2 if R == .
egen m_experiencegroup = cut(m_experience), group(5)
collapse (mean) p_inc (semean) p_incse = p_inc, by(m_experiencegroup R)
sort m_experiencegroup R
gen p_incplus  = p_inc + p_incse 
gen p_incminus = p_inc - p_incse

#delimit
twoway (line p_inc m_experiencegroup if R == 2, lwidth(medthick) lpattern(solid) lcolor(gs0))
       (line p_inc m_experiencegroup if R == 0, lwidth(medthick) lpattern(dash)  lcolor(gs0))
       (line p_inc m_experiencegroup if R == 0, lwidth(medthick) lpattern(solid)   lcolor(gs9))
        , 
		  legend(order(1 2 3 4) label(1 "ABC/CARE Eligible ({bf:B} {&isin} {bf:{it:{&Beta}}}{sub:0})") 
		         label(2 "ABC/CARE Control") label(3 "ABC/CARE Treatment") size(small))
		  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
		  xtitle($xlabel) ytitle(, size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 	
		
