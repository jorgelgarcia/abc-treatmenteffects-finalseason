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
insheet using ../rslt/sensitivity/irr_factors.csv, names clear

rename v1 sex

gen stat = mean

sort sex part rate

* fix cases where IRR exhibits extreme values

gen errors = 0

replace errors = 1 if rate < 0.5 & part == "costs" & inlist(sex, "m", "f")
replace errors = 1 if stat > ub & !missing(stat)
replace errors = 1 if stat < lb & !missing(lb)
replace errors = 1 if stat > 1
replace errors = 1 if stat < -1

replace stat = . if errors == 1
replace ub = . if errors == 1
replace lb = . if errors == 1

// prepare alternate CI and point estimate
gen alt_stat = stat if rate == 1
gen tmp1 = ub if rate == 1
gen tmp2 = lb if rate == 1
bysort sex part: egen alt_ub = mean(tmp1)
bysort sex part: egen alt_lb = mean(tmp2)
drop tmp1 tmp2

* label variables
label var sex "Sex"
label var rate "Factor"
label var stat "Internal Rate of Return (%)"
label var lb "Lower bound (bootstrap 10th percentile)"
label var ub "Upper bound (bootstrap 90th percentile)"

// Plot

// x,y labels
global y1label Alternative Estimate
global y2label C.I. (80%) of Estimate
global y3label Estimate
global  xlabel Factor
global	ylabel Internal Rate of Return


/*
qaly -0.1 to 0.15
inc_trans_pub 0 to 0.15
inc_parent	0 to 4
inc_labor 	0 to 0.15
health		-0.05 to 0.15
edu 0 to 0.15
*/

// GRAPHS WITH MALES AND FEMALES SEPARATE, WITH CONFIDENCE INTERVALS for RATE == 1 

levelsof part, local(parts)
foreach sex in m f {
	foreach p in `parts' {
		local axis_range ylabel(-0.1 "-10%" 0 "0%" 0.10 "10%" 0.20 "20%" 0.30 "30%" 0.40 "40%") yscale(r(-0.1, 0.40))
		/*
		if "`p'" == "inc_parent" | "`p'" == "cc" {
			local axis_range ylabel(0 "0%" 0.2 "20%" 0.4 "40%" 0.6 "40%" 0.8 "80%") yscale(r(0, 0.8))
		}
		if "`p'" == "costs" {
			local axis_range ylabel(-0.1 "-10%" 0 "0%" 0.1 "10%" 0.2 "20%" 0.3 "30%" 0.4 "40%") yscale(r(0, 0.4))
		}
		*/
		/*local axis_range
		if "`p'" != "inc_parent" & "`p'" != "costs" {
			local axis_range ylabel(-0.1 -0.05 0 0.05 0.10 0.15 0.20) yscale(r(-0.1, 0.2))
		}
		if "`p'" == "costs" {
			local axis_range ylabel(0 0.10 0.20 0.30 0.40) yscale(r(0, 0.40))
		}
		if "`p'" == "inc_parent" {
			local axis_range ylabel(0 0.2 0.4 0.6 0.8 1) yscale(r(0, 1))
		}
		*/

		#delimit
		twoway 	(scatter stat rate if sex == "`sex'" & part == "`p'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0))
				(line alt_ub alt_lb rate if sex == "`sex'" & part == "`p'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
				(scatter alt_stat rate if sex == "`sex'" & part == "`p'", msymbol(circle) mfcolor(white) mlcolor(maroon) msize(medlarge))
				, 
				  legend(label(1 $y1label) label(2 $y2label) label(4 $y3label) order(4 1 2) size(small) rows(1))
				  xlabel(, nogrid glcolor(gs14)) ylabel(, angle(h) nogrid glcolor(gs14))
				  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
				  `axis_range'
				  graphregion(color(white)) plotregion(fcolor(white))
				  name(irrf_`p'_`sex', replace);
		#delimit cr
		graph export "$relpath/irrf_`p'_`sex'1.eps", replace
	}
}

// GRAPHS WITH MALES AND FEMALES SEPARATE, WITH CONFIDENCE INTERVALS
/*

global y1label Point Estimate
global y2label C.I. (80%)
global  xlabel Factor
global	ylabel IRR

levelsof part, local(parts)
foreach sex in m f {
	foreach p in `parts' {
		local axis_range
		if "`p'" != "inc_parent" & "`p'" != "costs" {
			local axis_range ylabel(-0.1 -0.05 0 0.05 0.10 0.15 0.20) yscale(r(-0.1, 0.2))
		}
		if "`p'" == "costs" {
			local axis_range ylabel(0 0.10 0.20 0.30 0.40) yscale(r(0, 0.40))
		}
		if "`p'" == "inc_parent" {
			local axis_range ylabel(0 1 2 3 4) yscale(r(0, 4))
		}

		#delimit
		twoway 	(scatter point rate if sex == "`sex'" & part == "`p'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0))
				(line ub lb rate if sex == "`sex'" & part == "`p'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
				
				, 
				  legend(label(1 $y1label) label(2 $y2label) order(1 2) size(small))
				  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
				  `axis_range'
				  graphregion(color(white)) plotregion(fcolor(white))
				  name(irrf_`p'_`sex', replace);
		#delimit cr
		graph export irrf_`p'_`sex'2.eps, replace
	}
}
*/
/*

// GRAPHS WITH MALES AND FEMALES SEPARATE, WITH CONFIDENCE INTERVALS

levelsof part, local(parts)
foreach sex in m f {
	foreach p in `parts' {
		local axis_range
		if "`p'" != "inc_parent" & "`p'" != "costs" {
			local axis_range ylabel(-0.1 -0.05 0 0.05 0.10 0.15 0.20) yscale(r(-0.1, 0.2))
		}
		if "`p'" == "costs" {
			local axis_range ylabel(0 0.10 0.20 0.30 0.40) yscale(r(0, 0.40))
		}
		if "`p'" == "inc_parent" {
			local axis_range ylabel(0 1 2 3 4) yscale(r(0, 4))
		}

		#delimit
		twoway 	(scatter point rate if sex == "`sex'" & part == "`p'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0))
				(line ub lb rate if sex == "`sex'" & part == "`p'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
				
				, 
				  legend(label(1 $y1label) label(2 $y2label) order(1 2) size(small))
				  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
				  `axis_range'
				  graphregion(color(white)) plotregion(fcolor(white))
				  name(irrf_`p'_`sex', replace);
		#delimit cr
		graph export irrf_`p'_`sex'2.eps, replace
	}
}
*/
// GRAPHS WITH MALES AND FEMALES TOGETHER
/*
levelsof part, local(parts)
foreach p in `parts' {
	local axis_range
	if "`p'" != "inc_parent" & "`p'" != "costs" {
		local axis_range ylabel(-0.1 -0.05 0 0.05 0.10 0.15 0.20) yscale(r(-0.1, 0.2))
	}
	if "`p'" == "costs" {
		local axis_range ylabel(0 0.10 0.20 0.30 0.40) yscale(r(0, 0.40))
	}
	if "`p'" == "inc_parent" {
		local axis_range ylabel(0 1 2 3 4) yscale(r(0, 4))
	}


	#delimit
	twoway 	(scatter point rate if sex == "m" & part == "`p'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0))
			(scatter point rate if sex == "f" & part == "`p'", msymbol(triangle) mfcolor(gs8) mlcolor(gs8) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs8))
			/*(line ub lb rate if sex == "m" & part == "`p'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
			(line ub lb rate if sex == "f" & part == "`p'", lwidth(thin thin) lpattern(dash dash) lcolor(gs8 gs8))*/
			, 
			  legend(label(1 $y1label) label(2 $y2label) order(1 2) size(small))
			  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
			  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
			  `axis_range'
			  graphregion(color(white)) plotregion(fcolor(white))
			  name(bcrf_`p', replace);
	#delimit cr
	graph export irrf_`p'.eps, replace

}
*/

