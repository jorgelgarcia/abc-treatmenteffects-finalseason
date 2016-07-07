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
insheet using bc_factors_mp.csv, names clear

replace point = "" if point == "-inf"
replace point = "" if point == "inf"
replace lb = "" if lb=="-inf"
replace ub = "" if ub=="-inf"
replace lb = "" if lb=="inf"
replace ub = "" if ub=="inf"
destring point lb ub, replace

sort sex part rate

* fix cases where IRR exhibits extreme values
gen errors = 0

replace errors = 1 if rate < 0.6 & part == "costs" & inlist(sex, "m", "f")
replace errors = 1 if point > ub & !missing(point)
replace errors = 1 if point < lb & !missing(lb)

replace point = . if errors == 1
replace ub = . if errors == 1
replace lb = . if errors == 1

// prepare alternate CI and point estimate
gen alt_point = point if rate == 1
gen tmp1 = ub if rate == 1
gen tmp2 = lb if rate == 1
bysort sex: egen alt_ub = mean(tmp1)
bysort sex: egen alt_lb = mean(tmp2)
drop tmp1 tmp2

* label variables
label var sex "Sex"
label var rate "Factor"
label var point "Benefit-Cost Ratio"
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
		twoway 	(scatter point rate if sex == "`sex'" & part == "`p'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(solid)))
				(line alt_ub alt_lb rate if sex == "`sex'" & part == "`p'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
				(scatter alt_point rate if sex == "`sex'" & part == "`p'", msymbol(circle) mfcolor(white) mlcolor(maroon) msize(medlarge))
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




/*
inc_parent	0 to 8
inc_trans	0 to 5+
qaly		0 to 6
labor		0 to 8
health		0 to 6
edu			0 to 6
crime		0 to 11
costs 		0 to 25+
cc			0 to 5+
*/

// GRAPHS FOR M, F TOGETHER WITH CONF INT for USC

/*
// x,y labels
global y1label Point Estimate
global y2label C.I. (80%)
global  xlabel Factor
global	ylabel Benefit-Cost Ratio

levelsof part, local(parts)
foreach sex in m f {
	foreach p in `parts' {
		if "`p'" == "qaly" | "`p'" == "health" | "`p'" == "inc_parent" | "`p'" == "cc" {
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
		}

		#delimit
		twoway 	(scatter point rate if sex == "`sex'" & part == "`p'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(solid)))
				(line ub lb rate if sex == "`sex'" & part == "`p'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
				, 
				  legend(label(1 $y1label) label(2 $y2label) order(1 2) size(small))
				  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
				  `axis_range'
				  graphregion(color(white)) plotregion(fcolor(white))
				  name(bcrf_`p'_`sex', replace);
		#delimit cr	
		graph export bcrf_`p'_`sex'2.eps, replace
	}
}

*/
// GRAPHS FOR SEPARATE M F
/*
levelsof part, local(parts)
foreach p in `parts' {

	local axis_range
	if "`p'" != "crime" & "`p'" != "costs" {
		local axis_range ylabel(0 2 4 6 8) yscale(r(0 8.5))
	}
	if "`p'" == "crime" {
		local axis_range ylabel(0 2 4 6 8 10 12) yscale(r(0, 12))
	}
	if "`p'" == "costs" {
		local axis_range ylabel(0 2 4 6 8 10 12) yscale(r(0, 12))
	}
	#delimit
	twoway 	(scatter point rate if sex == "m" & part == "`p'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(dash)))
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
	graph export bcrf_`p'.eps, replace
}


*/
