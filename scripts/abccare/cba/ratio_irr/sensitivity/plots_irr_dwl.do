set more off

// Check file path
local filedir: pwd
if strpos("`filedir'", "ratio_irr")==0 | strpos("`filedir'", "sensitivity")==0  {
	di as error "ERROR: Must run file from its directory."
	exit 101
}

// output file path
global relpath ../../../../../AppOutput/Sensitivity

// Bring in data
insheet using ../rslt/sensitivity/irr_dwl.csv, names clear
rename v1 sex

* determine statistic of interest
gen stat = mean

/*
* rename
rename r1 	r100
rename r15	r150
rename r2	r200
rename r25	r250
rename r3	r300

local i = 0
foreach v of varlist r0-r300 {
	rename `v' r`i'
	local i = `i' + 25
}

local points
local p10
local p90
foreach i of numlist 0(25)300 {
	local points `points' point_r`i' = r`i'
	local p10 `p10' lb_r`i' = r`i'
	local p90 `p90' ub_r`i' = r`i'
	}

collapse (mean) `points' (p10) `p10' (p90) `p90', by(sex)
reshape long point_ lb_ ub_, i(sex) j(rate) string
rename point_ point
rename lb_ lb
rename ub_ ub
*/

* fix cases where IRR exhibits extreme values
gen errors = 0

replace errors = 1 if stat > ub & !missing(stat)
replace errors = 1 if stat < lb & !missing(lb)
replace errors = 1 if stat > 1
replace errors = 1 if stat < -1

replace stat = . if errors == 1
replace ub = . if errors == 1
replace lb = . if errors == 1

// prepare alternate CI and point estimate
gen rate_s = string(rate)
gen alt_stat = stat if rate_s == ".5"
gen tmp1 = ub if rate_s == ".5"
gen tmp2 = lb if rate_s == ".5"
bysort sex: egen alt_ub = mean(tmp1)
bysort sex: egen alt_lb = mean(tmp2)
drop tmp1 tmp2

sort sex rate


label var sex "Sex"
label var rate "Marginal Cost of Welfare"
label var stat "Internal Rate of Return (%)"
label var lb "Lower bound (bootstrap 10th percentile)"
label var ub "Upper bound (bootstrap 90th percentile)"

// Plot

// GRAPHS WITH SEPARATE M, F, AND CI FOR POITN ESTIMATE

// x,y labels
global y1label Alternative Estimate
global y2label C.I. (80%) of Estimate
global y3label Estimate 
global  xlabel Marginal Cost of Welfare
global	ylabel Internal Rate of Return

foreach sex in m f {
	local axis_range ylabel(-0.1 "-10%" 0 "0" 0.1 "10%" 0.2 "20%" 0.3 "30%") yscale(r(-0.10, 0.3))
	#delimit
	twoway 	(scatter stat rate if sex == "`sex'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0))
			(line alt_ub alt_lb rate if sex == "`sex'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
			(scatter alt_stat rate if sex == "`sex'", msymbol(circle) mfcolor(white) mlcolor(maroon) msize(medlarge))
			, 
			  legend(label(1 $y1label) label(2 $y2label) label(4 $y3label) order(4 1 2) size(small) rows(1))
			  xlabel(1 "100%" 2 "200%" 3 "300%", nogrid glcolor(gs14)) ylabel(, angle(h) nogrid glcolor(gs14))
			  `axis_range'
			  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
			  graphregion(color(white)) plotregion(fcolor(white))
			  name(irr_dwl_`sex', replace);
	#delimit cr 
	graph export "$relpath/irr_dwl_`sex'1.eps", replace
}


// GRAPHS WITH SEPARATE M, F, and with CI
/*
global y1label Point Estimate
global y2label C.I. (80%) 
global  xlabel Marginal Cost of Welfare (%)
global	ylabel IRR (%)

foreach sex in m f {
	local axis_range ylabel(-0.1 0 0.1 0.2 0.3) yscale(r(-0.15, 0.3))
	#delimit
	twoway 	(scatter point rate if sex == "`sex'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0))
			(line ub lb rate if sex == "`sex'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
			, 
			  legend(label(1 $y1label) label(2 $y2label) order(1 2) size(small))
			  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
			  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
			  `axis_range'
			  graphregion(color(white)) plotregion(fcolor(white))
			  name(irr_dwl_`sex', replace);
	#delimit cr 
	graph export irr_dwl_`sex'2.eps, replace
}
*/
// GRAPHS WITH COMBINED M, F



#delimit
twoway 	(scatter stat rate if sex == "m", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0))
		(scatter stat rate if sex == "f", msymbol(triangle) mfcolor(gs8) mlcolor(gs8) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs8))
		/*(line ub lb rate if sex == "m", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
		(line ub lb rate if sex == "f", lwidth(thin thin) lpattern(dash dash) lcolor(gs8 gs8))*/
        , 
		  legend(label(1 Male) label(2 Female) order(1 2) size(small))
		  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
		  ylabel(0 0.1 0.2 0.3) yscale(r(0, 0.30))
		  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export "$relpath/irr_dwl.eps", replace

