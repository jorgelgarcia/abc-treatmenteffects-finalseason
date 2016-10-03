version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC CBA
Description:    plots of distributions of cognitive and non-cognitive skills for assumptions 4 and 5
*This version:  April 18, 2016
*This .do file: Jorge L. Garcia
*This project : CBA Team
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
global datapsid     = "$klmshare/Data_Central/data-repos/psid/base/"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global datanlsyw    = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/"
global datacnlsyw   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global dataabcres   = "$klmmexico/abccare/income_projections"
global dataweights  = "$klmmexico/abccare/as_weights/weights_09122016"
global nlsyother    = "$klmmexico/BPSeason2"
global collapseprj  = "$klmmexico/abccare/income_projections/"

// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// bootstraps 
global bootstraps 1000
set seed 0

// ABC
cd $dataabccare
use append-abccare_iv.dta, clear
drop if random == 3

// construct factors
// cognitive
factor  iq2y iq3y iq4y iq5y iq7y iq8y
predict c

// non-cognitive
factor bsi_tsom bsi_thos bsi_tdep bsi_tgsi
predict n

matrix b = [.,.]
foreach num of numlist 1(1)$bootstraps {
	preserve 
	bsample 
	// cognitive
	factor  iq2y iq3y iq4y iq5y iq7y iq8y
	predict cogfactorb
	summ cogfactorb
	replace cogfactorb = (cogfactorb - r(mean))/r(sd)

	// non-cognitive
	factor bsi_tsom bsi_thos bsi_tdep bsi_tgsi
	predict noncogfactorb
	summ noncogfactorb
	replace noncogfactorb = (noncogfactorb - r(mean))/r(sd)
	
	// treatment effects
	reg cogfactorb treat hrabc_index apgar1 apgar5
	matrix bc = e(b)
	matrix bc = bc[1,1]
	
	reg noncogfactorb treat hrabc_index apgar1 apgar5
	matrix bn = e(b)
	matrix bn = bn[1,1]
	
	matrix bb = [bc,bn]
	matrix b = [b \ bb]
	
	restore
}
mat colnames b = bc bn

preserve
clear 
svmat b, names(col)

foreach var in c n {
summ b`var'
local meanb`var' = r(mean)
local seb`var'   = round(r(sd)/sqrt(r(N)),.0001)
local meanb`var' = round(`meanb`var'',.0001)
}
restore

cd $output
// plot factors
foreach var in c n { 

#delimit
twoway (kdensity `var' if R == 0, lwidth(vthick) lpattern(solid) lcolor(gs0))
       (kdensity `var' if R == 1, lwidth(vthick) lpattern(solid) lcolor(gs8))
        , 
		  legend(label(1 Control) label(2 Treatment))
		  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
		  xtitle({&theta}{subscript:`var'}) ytitle(Density)
		  graphregion(color(white)) plotregion(fcolor(white))
		  note("Mean Treatment - Control: `meanb`var'' (`seb`var'').");
#delimit cr 
graph export abccare_`var'factor.eps, replace
}

