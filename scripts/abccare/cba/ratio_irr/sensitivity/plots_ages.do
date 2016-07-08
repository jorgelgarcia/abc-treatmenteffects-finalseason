	set more off

// Check file path
local filedir: pwd
if strpos("`filedir'", "ratio_irr")==0 | strpos("`filedir'", "sensitivity")==0  {
	di as error "ERROR: Must run file from its directory."
	exit 101
}

// output file path
global relpath ../../../../../AppOutput/Sensitivity


*---------------------------------------
* IRR
*---------------------------------------

// Bring in data
insheet using "../rslt/sensitivity/irr_age_type2.csv", names clear

label var sex "Sex"
label var age "Age"
label var point "IRR"

// Plot

// GRAPHS WITH M, F TOGETHER

// x,y labels
global  xlabel Age
global	ylabel Internal Rate of Return

#delimit
twoway 	(scatter point age if sex == "m", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(dash)))
	(scatter point age if sex == "f", msymbol(triangle) mfcolor(gs8) mlcolor(gs8) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs8) cmissing(no))
        , 
		  legend(label(1 Male) label(2 Female) order(1 2) size(small))
		  xlabel(, grid glcolor(gs14)) ylabel(-0.2 -0.1 0 0.1 0.2, angle(h) glcolor(gs14)) yscale(r(-0.2,0.2))
		  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
		  graphregion(color(white)) plotregion(fcolor(white)) name(irr, replace);
#delimit cr 
graph export "$relpath/irr_age.eps", replace

*---------------------------------------
* B/C ratio
*---------------------------------------

// Bring in data
insheet using "../rslt/tables/ratios_age_type2.csv", names clear

label var sex "Sex"
label var age "Age"
label var point "Benefit-Cost Ratio"

// Plot

// GRAPHS WITH M, F TOGETHER

// x,y labels
global  xlabel Age
global	ylabel Benefit-Cost Ratio

#delimit
twoway 	(scatter point age if sex == "m", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(dash)))
	(scatter point age if sex == "f", msymbol(triangle) mfcolor(gs8) mlcolor(gs8) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs8) cmissing(no))
        , 
		  legend(label(1 Male) label(2 Female) order(1 2) size(small))
		  xlabel(, grid glcolor(gs14)) ylabel(0 2 4 6 8 10, angle(h) glcolor(gs14)) yscale(r(0, 10))
		  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
		  graphregion(color(white)) plotregion(fcolor(white)) name(bcr, replace);
#delimit cr 
graph export "$relpath/bcr_age.eps", replace

