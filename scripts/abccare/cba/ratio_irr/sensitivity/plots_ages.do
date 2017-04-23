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
insheet using "../rslt/sensitivity/current/irr_age_type2.csv", names clear

gen stat = mean

drop if age == 108

label var sex "Sex"
label var age "Age"
label var stat "IRR"

gen upper = stat + se
gen lower = stat - se

// Plot

// GRAPHS WITH M, F TOGETHER

// x,y labels
global  xlabel Age
global	ylabel Internal Rate of Return

#delimit
twoway 	(scatter stat age if sex == "m" & pval <= 0.10, msymbol(circle) mfcolor(black) msize(large) mlcolor(black) yline(0.03, lpattern(dash) lcolor(black)))
	(scatter stat age if sex == "f" & pval <= 0.10, msymbol(triangle) mfcolor(black) msize(large) mlcolor(black))
        (scatter stat age if sex == "p" & pval <= 0.10, msymbol(square) mfcolor(gs8) msize(large) mlcolor(gs8))
	(scatter stat age if sex == "m" & pval > 0.10, msymbol(Oh) msize(large) mlcolor(black))
	(scatter stat age if sex == "f" & pval > 0.10, msymbol(Th) msize(large) mlcolor(black))
        (scatter stat age if sex == "p" & pval > 0.10, msymbol(Sh) msize(large) mlcolor(gs8))
	(line stat age if sex == "m",  lwidth(thick) lpattern(solid) lcolor(black))
	(line stat age if sex == "f", lwidth(thick) lpattern(solid) lcolor(black))
	(line stat age if sex == "p", lwidth(thick) lpattern(dash) lcolor(gs8))
	, 
		  legend(label(1 p-value {&le} 0.10) label(2 p-value {&le} 0.10) label(3 p-value {&le} 0.10)
		  label(4 p-value > 0.10) label(5 p-value > 0.10) label(6 p-value > 0.10) order(- "Male:" 1 4 - "Female:" 2 5 - "Pooled:" 3 6) rows(3) size(small))
		  xlabel(0 5 8 15 21 30 79, grid glcolor(gs14)) ylabel(0(0.05)0.2, angle(h) glcolor(gs14)) yscale(r(0,0.2))
		  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
		  graphregion(color(white)) plotregion(fcolor(white)) name(irr, replace);
#delimit cr 
graph export "$relpath/irr_age.eps", replace

*---------------------------------------
* B/C ratio
*---------------------------------------

// Bring in data
insheet using "../rslt/sensitivity/current/ratios_age_type2.csv", names clear

gen stat = mean

drop if age == 108

label var sex "Sex"
label var age "Age"
label var stat "Benefit-Cost Ratio"

// Plot

// GRAPHS WITH M, F TOGETHER

// x,y labels
global  xlabel Age
global	ylabel Benefit-Cost Ratio

#delimit
twoway 	(scatter stat age if sex == "m" & pval <= 0.10, msymbol(circle) mfcolor(black) msize(large) mlcolor(black) yline(0.03, lpattern(dash) lcolor(black)))
	(scatter stat age if sex == "f" & pval <= 0.10, msymbol(triangle) mfcolor(black) msize(large) mlcolor(black))
        (scatter stat age if sex == "p" & pval <= 0.10, msymbol(square) mfcolor(gs8) msize(large) mlcolor(gs8))
	(scatter stat age if sex == "m" & pval > 0.10, msymbol(Oh) msize(large) mlcolor(black))
	(scatter stat age if sex == "f" & pval > 0.10, msymbol(Th) msize(large) mlcolor(black))
        (scatter stat age if sex == "p" & pval > 0.10, msymbol(Sh) msize(large) mlcolor(gs8))
	(line stat age if sex == "m",  lwidth(thick) lpattern(solid) lcolor(black))
	(line stat age if sex == "f", lwidth(thick) lpattern(solid) lcolor(black))
	(line stat age if sex == "p", lwidth(thick) lpattern(dash) lcolor(gs8))
	,
		  legend(label(1 p-value {&le} 0.10) label(2 p-value {&le} 0.10) label(3 p-value {&le} 0.10)
		  label(4 p-value > 0.10) label(5 p-value > 0.10) label(6 p-value > 0.10) order(- "Male:" 1 4 - "Female:" 2 5 - "Pooled:" 3 6) rows(3) size(small))
		  xlabel(0 5 8 15 21 30 79, grid glcolor(gs14)) ylabel(0 2 4 6 8 10, angle(h) glcolor(gs14)) yscale(r(0, 10))
		  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
		  graphregion(color(white)) plotregion(fcolor(white)) name(bcr, replace);
#delimit cr 
graph export "$relpath/bcr_age.eps", replace

