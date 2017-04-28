/*
Project: 	Treatment effects
Date:		April 27, 2017
*/

clear all
set more off

// parameters
set seed 1
global bootstraps 100
global quantiles 30

// macros
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico

// filepaths
global data	   	= "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global scripts    	= "$projects/abccare-cba/scripts/"
global output      	= "$projects/abccare-cba/output/"

// data
cd $data
use append-abccare_iv 

drop if R == 0 & RV == 1


// social emotional


forvalues b = 0/$bootstraps {

	preserve
	
	if `b' > 0 {
		bsample
	}
	
	gen indfactor = .
	forvalues s = 0/1 {
		qui factor cbi_id5y6m cbi_id6y cbi_id6y6m cbi_id7y cbi_id7y6m cbi_id8y 
		qui predict indfactor`s' if male == `s'
		qui sum indfactor`s' if male == `s'
		qui replace indfactor`s' = (indfactor`s' - r(mean))/r(sd)
		xtile indfactor`s'_tmp = indfactor`s', nquantiles($quantiles)
		qui replace indfactor = indfactor`s'_tmp if male == `s'
	}


	forvalues s = 0/1 {
		forvalues r = 0/1 {
			qui sum indfactor if male == `s' & R == `r'
			matrix mean_male`s'R`r'_`b' = r(mean)
			matrix mean_male`s'R`r' = (nullmat(mean_male`s'R`r') \ mean_male`s'R`r'_`b')
			matrix colnames mean_male`s'R`r' = mean_male`s'R`r'
		}
	}
	
	restore
}

clear
mat all = mean_male0R0, mean_male0R1, mean_male1R0, mean_male1R1
svmat all, names(col)

gen n = _n
foreach v in mean_male0R0 mean_male0R1 mean_male1R0 mean_male1R1 {
	sum `v' if n == 1
	gen point_`v' = r(mean)
	
	sum `v' if n > 1
	gen emp_`v' = r(mean)
	
	sum `v' if n > 1
	gen se_`v' = r(sd)
	
	gen u_`v' = point_`v' + se_`v'
	gen l_`v' = point_`v' - se_`v'
	
	gen de_`v' = `v' - emp_`v' if n > 1
	
	gen diff_`v' = (abs(de_`v') >= abs(point_`v')) if n > 1
	sum diff_`v'
	gen p_`v' = r(mean)
	
}


forvalues i = 0/1 {
	gen n`i'0 = `i'
	gen n`i'1 = `i' + 0.25
}

# delimit ;
twoway (bar point_mean_male0R0 n00 , barwidth(0.25) blcol(black) blwidth(thick) bfcol(white)) 
	(bar point_mean_male0R1 n01 , barwidth(0.25) blcol(gs8) blwidth(thick) bfcol(gs8))
	(bar point_mean_male1R0 n10 , barwidth(0.25) blcol(black) blwidth(thick) bfcol(white))
	(bar point_mean_male1R1 n11 , barwidth(0.25) blcol(gs8) blwidth(thick) bfcol(gs8))
	(scatter point_mean_male0R0 n00 if p_mean_male0R0 <= 0.1, mcol(black) msize(medium))
	(scatter point_mean_male0R1 n01 if p_mean_male0R1 <= 0.1, mcol(black) msize(medium))
	(scatter point_mean_male1R0 n10 if p_mean_male1R0 <= 0.1, mcol(black) msize(medium))
	(scatter point_mean_male1R1 n11 if p_mean_male1R1 <= 0.1, mcol(black) msize(medium))
	,
	
	graphregion(color(white))
	xlabel(0.123 "Female" 1.125 "Male")
	legend(order(1 2) label(1 "Control") label(2 "Treatment"))
;

# delimit cr


