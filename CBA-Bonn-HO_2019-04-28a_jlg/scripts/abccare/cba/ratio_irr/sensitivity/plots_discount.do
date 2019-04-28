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
insheet using ../rslt/sensitivity/bc_discount.csv, names clear

* determine statistic of interest (mean or point)
gen stat = mean

rename v1 sex

* fix cases where IRR exhibits extreme values
gen errors = 0

replace errors = 1 if stat > ub & !missing(stat)
replace errors = 1 if stat < lb & !missing(lb)

replace stat = . if errors == 1
replace ub = . if errors == 1
replace lb = . if errors == 1

// prepare alternate CI and point estimate
gen rate_s = string(rate)

gen alt_stat = stat if rate_s == ".03"
gen tmp1 = ub if rate_s == ".03"
gen tmp2 = lb if rate_s == ".03"
bysort sex: egen alt_ub = mean(tmp1)
bysort sex: egen alt_lb = mean(tmp2)
drop tmp1 tmp2

sort sex rate


label var sex "Sex"
label var rate "Discount Rate (%)"
label var stat "Benefit-Cost Ratio"
label var lb "Lower bound (bootstrap 10th percentile)"
label var ub "Upper bound (bootstrap 90th percentile)"

// Plot

// GRAPHS WITH M, F, SEPARATE, WITH FIXED CI FOR POINT ESTIMATE

global y1label Alternative Estimate
global y2label C.I. (80%) of Estimate
global y3label Estimate
global  xlabel Discount Rate
global	ylabel Benefit-Cost Ratio


foreach sex in m f {
	local axis_range ylabel(0 5 10 15 20) yscale(r(0, 20))
	#delimit
	twoway 	(scatter stat rate if sex == "`sex'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(solid)))
			(line alt_ub alt_lb rate if sex == "`sex'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
			(scatter alt_stat rate if sex == "`sex'", msymbol(circle) mfcolor(white) mlcolor(maroon) msize(medlarge))
			, 
			  legend(label(1 $y1label) label(2 $y2label) label(4 $y3label) order(4 1 2) size(small) rows(1))
			  xlabel(0 "0" 0.05 "5%" 0.10 "10%" 0.15 "15%", nogrid glcolor(gs14)) ylabel(, nogrid angle(h) glcolor(gs14))
			  `axis_range'
			  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
			  graphregion(color(white)) plotregion(fcolor(white)) name(bcr_discount_`sex', replace);
	#delimit cr 
	graph export "$relpath/bcr_discount_`sex'1.eps", replace
}


// GRAPHS WITH M, F SEPARATE with CI for USC
/*
// x,y labels
global y1label Point Estimate
global y2label C.I. (80%)
global  xlabel Discount Rate    
    output['rate'] = d
    bc_dwl = pd.concat([bc_dwl, output], axis=0)
            
    print 'B/C Ratio for MCW {} calculated.'.format(d)
global	ylabel Benefit-Cost Ratio


foreach sex in m f {
	#delimit
	twoway 	(scatter point rate if sex == "`sex'", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(solid)))
			(line ub lb rate if sex == "`sex'", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
			, 
			  legend(label(1 $y1label) label(2 $y2label) order(1 2) size(small))
			  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
			  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
			  graphregion(color(white)) plotregion(fcolor(white)) name(bcr_discount_`sex', replace);
	#delimit cr 
	graph export bcr_discount_`sex'2.eps, replace
}
*/

// GRAPHS WITH M, F TOGETHER

#delimit
twoway 	(scatter stat rate if sex == "m", msymbol(circle) mfcolor(gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0) yline(1, lpattern(dash)))
		(scatter stat rate if sex == "f", msymbol(triangle) mfcolor(gs8) mlcolor(gs8) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs8))
		/*(line ub lb rate if sex == "m", lwidth(thin thin) lpattern(dash dash) lcolor(gs0 gs0))
		(line ub lb rate if sex == "f", lwidth(thin thin) lpattern(dash dash) lcolor(gs8 gs8))*/
        , 
		  legend(label(1 Male) label(2 Female) order(1 2) size(small))
		  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14)) yscale(r(0, 20))
		  xtitle($xlabel, size(small)) ytitle($ylabel, size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export "$relpath/bcr_discount.eps", replace

