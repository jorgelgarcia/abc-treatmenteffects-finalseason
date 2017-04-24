/*
Project: 	Treatment effects
Date:		April 24, 2017
*/

clear all
set more off

// parameters
set seed 1
global bootstraps 5
global quantiles 30

// macros
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico

// filepaths
global data	   	= "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global scripts    	= "$projects/abccare-cba/scripts/"
global output      	= "$projects/abccare-cba/output/"

// variables
# delimit ;
global home		home0y6m home1y6m home2y6m home3y6m home4y6m home8y;
global cog		iq2y iq3y iq5y iq8y;
global ncog		ibr_sociab0y6m ibr_sociab1y ibr_sociab1y6m ibr_task0y6m ibr_task1y ibr_task1y6m cbi_ta6y cbi_ta8y;
global ach		math5y6m math8y math12y 	
			read5y6m read8y read12y;

global varstofactor	home cog ncog ach;
global varstocompare	homefactor cogfactor ncogfactor achfactor;
global allvars		$home $cog $ncog $ach ;

local numcats : word count $varstocompare ;
local numvars : word count $allvars ;

# delimit cr

// data
cd $data
use append-abccare_iv, clear

drop if R == 0 & RV == 1

// bootstrap
forvalues b = 0/$bootstraps {

	preserve
	
		if `b' > 0 {
			bsample
		}
		
		// create factors 
		foreach c in $varstofactor { 
			qui factor  ${`c'} 
			qui predict `c'factor_tmp 
			qui sum `c'factor_tmp 
			qui replace `c'factor_tmp = (`c'factor_tmp - r(mean))/r(sd) 
			xtile `c'factor = `c'factor_tmp, nquantiles($quantiles)
			qui drop `c'factor_tmp
			
			// standardized variables
			foreach v in ${`c'} {
				qui sum `v'
				qui gen `v'_tmp = (`v' - r(mean))/r(sd)
				drop `v'
				xtile `v' = `v'_tmp, nquantiles($quantiles)
				qui drop `v'_tmp
			}
		}
		
		// calculate gender differences
		foreach c in $varstofactor {
			foreach v in ${`c'} `c'factor {
				forvalues s = 0/1 {
					qui sum `v' if male == `s'
					matrix `v'`s'_`b' = r(mean)
				
					matrix `v'`s' = (nullmat(`v'`s') \ `v'`s'_`b')
					matrix colnames `v'`s' = `v'`s'
				}
			}
		}
	
	restore
}

// bring to data
local mattoappend
local i = 0

forvalues s = 0/1 {
	foreach c in $varstofactor {
		foreach v in ${`c'} `c'factor {
			di "`v'"
		
			local i = `i' + 1
		
			if `i' < 2 * `numvars' + 2 * `numcats' {
				local mattoappend `mattoappend' `v'`s',
			}
			else {	
				local mattoappend `mattoappend' `v'`s'
			}
		}
	}
}
di "`mattoappend'"
mat allmeans = (`mattoappend')
clear
svmat allmeans, names(col)
qui gen b = _n

// inference and organize graph

local baroptions0 barwidth(0.2) bcol(white) blcol(black) lwidth(thick)
local baroptions1 barwidth(0.2) bcol(gs8) blcol(gs8) lwidth(thick)


foreach c in $varstofactor {
	
	local `c'graph
	local j = 0
	
	local numx : word count ${`c'}
	local numx = `numx' + 1
	forvalues i = 1/`numx' {
		gen n`i'_0 = `i' - 0.125
		gen n`i'_1 = `i' + 0.125
	}
	
	foreach v in ${`c'} `c'factor {
	
		local j = `j' + 1
		
		forvalues s = 0/1 {
			local `c'graph ``c'graph' (bar m`v'`s' n`j'_`s', `baroptions`s'')
			local `c'graph ``c'graph' (rcap u`v'`s' l`v'`s' n`j'_`s', lcol(black))
			local `c'graph ``c'graph' (scatter m`v'`s' n`j'_`s' if pupper`v' <= 0.1 | plower`v' <= 0.1, mcol(black))
		
			// point estimate
			qui sum `v'`s' if b == 1
			qui gen point`v'`s' = r(mean)
		
			// empirical mean
			qui sum `v'`s' if b > 1
			qui gen m`v'`s' = r(mean)
		
			// standard errors
			qui sum `v'`s' if b > 1
			qui gen se`v'`s' = r(sd)
			qui gen u`v'`s' = m`v'`s' + se`v'`s'
			qui gen l`v'`s' = m`v'`s' - se`v'`s'
		}
	
		// male - female
		qui gen gd`v' = `v'1 - `v'0
	
		// point estimate of male - female
		qui gen gdpoint`v' = point`v'1 - point`v'0
	
		// empirical mean of male - female
		qui sum gd`v' if b > 1 & !missing(gd`v'`s')
		qui gen mgd`v' = r(mean)
		
		// demean
		qui gen dgd`v' = gd`v' - mgd`v' if b > 1
		
		// p-values
		qui gen dlower`v' = (dgd`v' < gdpoint`v') 		if !missing(dgd`v')
		qui gen dupper`v' = (dgd`v' > gdpoint`v') 		if !missing(dgd`v')
		qui gen dtwo`v'   = (abs(dgd`v') >= abs(gdpoint`v')) 	if !missing(dgd`v')
		
		foreach p in lower upper two {
			qui sum d`p'`v'
			qui gen p`p'`v' = r(mean)
		}		
	}

	// graph

	# delimit ;
		twoway 	``c'graph'
			,
		ylabel(0(2)16, angle(0) glcol(gs13))
		graphregion(color(white))
		legend(rows(1) order(1 4 2 3) size(small) label(1 "Female") label(4 "Male") label(2 "+/- s.e.") label(3 "p-value {&le} 0.10"))
		name(`c', replace)
		;
	# delimit cr
	graph export "${results}/abccare-gdiff-`c'.eps", replace
	
	drop n?_0 n?_1
}


/*
# delimit ;
		twoway 	(bar mhomefactor0 n1_0, barwidth(0.2) bcol(white) blcol(black) lwidth(thick))
			(bar mhomefactor1 n1_1, barwidth(0.2) bcol(gs8) blcol(gs8) lwidth(thick))
			(bar mcogfactor0 n2_0, barwidth(0.2) bcol(white) blcol(black) lwidth(thick))
			(bar mcogfactor1 n2_1, barwidth(0.2) bcol(gs8) blcol(gs8) lwidth(thick))
			(bar mncogfactor0 n3_0, barwidth(0.2) bcol(white) blcol(black) lwidth(thick))
			(bar mncogfactor1 n3_1, barwidth(0.2) bcol(gs8) blcol(gs8) lwidth(thick))
			(bar machfactor0 n4_0, barwidth(0.2) bcol(white) blcol(black) lwidth(thick))
			(bar machfactor1 n4_1, barwidth(0.2) bcol(gs8) blcol(gs8) lwidth(thick))
			,
			
			xlabel(1 "Parenting" 2 "Cognitive" 3 "Non-cognitive" 4 "Achievement")
			ylabel(0(2)16, angle(0) glcol(gs13))
			graphregion(color(white))
			legend(rows(1) order(1 2) label(1 "Female") label(2 "Male"))
		;
	# delimit cr
