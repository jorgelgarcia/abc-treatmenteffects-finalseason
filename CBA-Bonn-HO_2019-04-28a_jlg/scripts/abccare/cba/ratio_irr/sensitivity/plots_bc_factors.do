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
insheet using ../rslt/sensitivity/bc_factors.csv, names clear

rename v1 sex

* make this statistic ofn interest (can change to point)
gen stat = mean

foreach v in stat lb ub {
	capture confirm string `v'
	if !_rc {
		replace `v' = "" if `v' == "-inf" | `v' == "inf"
		destring `v', replace
	}
}



sort sex part rate

* fix cases where IRR exhibits extreme values
gen errors = 0

replace errors = 1 if rate < 0.6 & part == "costs" & inlist(sex, "m", "f")
replace errors = 1 if stat > ub & !missing(stat)
replace errors = 1 if stat < lb & !missing(lb)

replace stat = . if errors == 1
replace ub = . if errors == 1
replace lb = . if errors == 1

// prepare alternate CI and point estimate
gen alt_stat = stat if rate == 1
gen tmp1 = ub if rate == 1
gen tmp2 = lb if rate == 1
bysort sex: egen alt_ub = mean(tmp1)
bysort sex: egen alt_lb = mean(tmp2)
drop tmp1 tmp2

* label variables
label var sex "Sex"
label var rate "Factor"
label var stat "Benefit-Cost Ratio"
label var lb "Lower bound (bootstrap 10th percentile)"
label var ub "Upper bound (bootstrap 90th percentile)"

// Plot
// GRAPHS FOR M, F TOGETHER WITH CONF INT for USC


// x,y labels
global y1label Alternative Estimate
global y2label C.I. (80%) of Estimate
global y3label Estimate 
global  xlabel Factor
global	ylabel Benefit-Cost Ratio

levelsof part, local(parts)
foreach sex in m f {
	foreach p in `parts' {
	
		if "`sex'" == "m" local axis_range ylabel(0 5 10 15 20) yscale(r(0, 20))
		else local axis_range ylabel(0 2 4 6 8) yscale(r(0, 8))
	
		/*if "`p'" == "qaly" | "`p'" == "health" | "`p'" == "inc_parent" | "`p'" == "cc" {
			local axis_range ylabel(0 2 4 6 8 10 12) yscale(r(0, 12))
		}
		else if "`p'" == "inc_trans_pub" | "`p'" == "edu" {
			local axis_range ylabel(0 2 4 6 8 10 12) yscale(r(0, 12))
		}
		else if "`p'" == "crime" {
			local axis_range ylabel(0 5 10 15 20 25) yscale(r(0, 25))
		}
		else if "`p'" == "costs"  | "`p'" == "inc_labor" {
			local axis_range ylabel(0 5 10 15) yscale(r(0, 17))
		}
		else {
			local axis_range ylabel(0 2 4 6 8) yscale(r(0 8.5))
		}*/

		#delimit
		twoway 	(scatter stat rate if sex == "`sex'" & part == "`p'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(solid)))
				(line alt_ub alt_lb rate if sex == "`sex'" & part == "`p'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
				(scatter alt_stat rate if sex == "`sex'" & part == "`p'", msymbol(circle) mfcolor(white) mlcolor(maroon) msize(medlarge))
				, 
				  legend(label(1 $y1label) label(2 $y2label) label(4 $y3label) order(4 1 2) size(small) rows(1))
				  xlabel(, nogrid glcolor(gs14)) ylabel(, nogrid angle(h) glcolor(gs14))
				  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
				  `axis_range'
				  graphregion(color(white)) plotregion(fcolor(white))
				  name(bcrf_`p'_`sex', replace);
		#delimit cr	
		graph export "$relpath/bcrf_`p'_`sex'1.eps", replace
	}
}

