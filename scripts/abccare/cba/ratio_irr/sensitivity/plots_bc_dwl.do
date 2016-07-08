set more off

/* TEMP FILE PATH FOR JOSH*/
cd "/home/jkcshea/Documents/cehd/projects/abc-cba/analysis/cba/plots"

// Check file path
local filedir: pwd
if strpos("`filedir'", "plots")==0 {
	di as error "ERROR: Must run file from its directory."
	exit 101
}

// output file path
global relpath ../../../abc-cba-draft/AppOutput/Sensitivity

// Bring in data
insheet using bc_dwl.csv, names clear

* fix cases where IRR exhibits extreme values
gen errors = 0

replace errors = 1 if point > ub & !missing(point)
replace errors = 1 if point < lb & !missing(lb)

replace point = . if errors == 1
replace ub = . if errors == 1
replace lb = . if errors == 1

// prepare alternate CI and point estimate
gen rate_s = string(rate)

gen alt_point = point if rate_s == ".5"
gen tmp1 = ub if rate_s == ".5"
gen tmp2 = lb if rate_s == ".5"
bysort sex: egen alt_ub = mean(tmp1)
bysort sex: egen alt_lb = mean(tmp2)
drop tmp1 tmp2

sort sex rate


label var sex "Sex"
label var rate "Marginal Cost of Welfare"
label var point "Benefit-Cost Ratio"
label var lb "Lower bound (bootstrap 10th percentile)"
label var ub "Upper bound (bootstrap 90th percentile)"

// Plot

// PLOTS WITH M, F, SEPARATE, FIXED CI FOR TRUE POINT ESTIMATE

global y1label Alternative Estimate
global y2label C.I. (80%) of Estimate
global y3label Estimate 
global  xlabel Marginal Cost of Welfare
global	ylabel Benefit-Cost Ratio

foreach sex in m f {
	local axis_range ylabel(0 5 10 15 20) yscale(r(0, 20))
	#delimit
		twoway 	(scatter point rate if sex == "`sex'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(solid)))
				(line alt_ub alt_lb rate if sex == "`sex'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
				(scatter alt_point rate if sex == "`sex'", msymbol(circle) mfcolor(white) mlcolor(maroon) msize(medlarge))
				, 
				  legend(label(1 $y1label) label(2 $y2label) label(4 $y3label) order(4 1 2) size(small) rows(1))
				  xlabel(0 "0" 1 "100%" 2 "200%" 3 "300%", nogrid glcolor(gs14)) ylabel(, nogrid angle(h) glcolor(gs14))
				  `axis_range'
				  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
				  graphregion(color(white)) plotregion(fcolor(white)) 
				  name(bcr_dwl_`sex', replace);
	#delimit cr 
	graph export "$relpath/bcr_dwl_`sex'1.eps", replace
}

/*
// GRAPHS WITH CI; M, F combined for USC

global y1label Point Estimate
global y2label C.I. (80%)
global  xlabel Marginal Cost of Welfare (%)
global	ylabel Benfit-Cost Ratio

foreach sex in m f {
	#delimit
		twoway 	(scatter point rate if sex == "`sex'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(solid)))
				(line ub lb rate if sex == "`sex'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
				
				, 
				  legend(label(1 $y1label) label(2 $y2label) order(1 2) size(small))
				  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
				  graphregion(color(white)) plotregion(fcolor(white)) 
				  name(bcr_dwl_`sex', replace);
	#delimit cr 
	graph export bcr_dwl_`sex'2.eps, replace
}

*/

// GRAPHS COMINING SEX
#delimit
	twoway 	(scatter point rate if sex == "m", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(dash)))
			(scatter point rate if sex == "f", msymbol(triangle) mfcolor(gs8) mlcolor(gs8) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs8))
			/*(line ub lb rate if sex == "m", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
			(line ub lb rate if sex == "f", lwidth(thin thin) lpattern(dash dash) lcolor(gs8 gs8))*/
			, 
			  legend(label(1 Male) label(2 Female) order(1 2) size(small))
			  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
			  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export "$relpath/bcr_dwl.eps", replace
