/*

Project:		ABC CBA
Script:			Graph Income Forecasts
Author:			Anna Ziff (aziff@uchicago.edu)
Original date:	August 29, 2016

*/

// macros
local file_specs	pset1_mset3
/*
Matching control sets (mset)
	1. Baseline controls only (W)
	2. Non-baseline controls only (X)
	3. Full set of controls (W,X)
Projection control sets (pset)
	1. lag, W, X
	2. X, W (not produced yet)
	3. lag, W
	4. W (not produced yet)
	5. X (not produced yet)
	6. lag, X
*/
local transfer_name "Transfer"
local labor_name	"Labor"

local drop0 keep if male == 0
local drop1 keep if male == 1
local drop2

local name0 female
local name1 male
local name2 pooled

global projects : env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico

global dataabccare   = "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global data_dir      = "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/income/rslt/projections/`file_specs'"
global incomeresults = "${klmmexico}/abccare/income_projections/"
global output        = "${projects}/abc-treatmenteffects-finalseason/output/"

// prepare data for graphing

cd $dataabccare
use append-abccare_iv.dta, clear

drop if R == 0 & RV == 1
keep id R male

tempfile abccare_data
save `abccare_data'


foreach source in labor /*transfer*/ {

	cd $data_dir
	insheet using "`source'_proj_combined_`file_specs'_pooled.csv", clear

	local varlist
	local ages
	local se_varlist
	
	forval i = 3/47 {
		capture confirm var v`i'
		if !_rc {
			local vl`i' : variable label v`i'
			qui rename v`i' age`vl`i''
		
			local varlist `varlist' mean_age`vl`i''
			local ages `ages' `vl`i''
			local se_varlist `varlist' seage`vl`i''=mean_age`vl`i''
			
			
			qui gen mean_age`vl`i'' = .
		}
	}

	sort id adraw
	levelsof id, local(ids)


	foreach id in `ids' {
		foreach age in `ages' {
			qui sum age`age' if id == `id'
			local age`age'id`id' = r(mean)
		
			qui replace mean_age`age' = `age`age'id`id'' if id == `id'
		}
	}

	drop age*
	drop if adraw > 0
	
	merge 1:1 id using `abccare_data', nogen
	drop if id == 9999
	drop adraw
	
	
	
		foreach stat in mean semean {
			preserve
				collapse (`stat') `varlist', by(R male)
				foreach age in `ages' {
					qui rename mean_age`age' `stat'_age`age'
				}
			
				tempfile `stat'_collapse
				save ``stat'_collapse'
			restore
		}
		use `mean_collapse', clear
		merge m:m R male using `semean_collapse', nogen
	
		drop if R == .
		gen N = _n
		reshape long mean_age semean_age, i(N) j(age)
	
		gen plus = mean_age + semean_age
		gen minus = mean_age - semean_age
		
		
		
		// limit to 25-60 and scale income
		drop if age < 25 | age > 65
		foreach v in mean_age semean_age plus minus {
			replace `v' = `v'/1000
		}
		
		cd $incomeresults
		save `source'_income_collapsed_`file_specs', replace
		
	// graph
	cd $output
	global y0  0[10]50
	global y1 10[10]80
	local bwidth1 = .65
	local bwidth0 = .65  
	forval sex = 0/1 {
	
	preserve

		`drop`sex''
	
		local graphregion		graphregion(color(white))
		local yaxis				ytitle("``source'_name' Income (1000s 2014 USD)") ylabel(${y`sex'}, angle(h) glcol(gs14))
		local xaxis				xtitle("Age") xlabel(25[5]65, grid glcol(gs14))
		local legend			legend(rows(1) order(2 1 3) label(1 "Control") label(2 "Treatment") label(3 "+/- s.e.") size(small))
	
		local t_mean			lcol(gs9) lwidth(1.2)
		local c_mean			lcol(black) lwidth(1.2)
		local t_se				lcol(gs9) lpattern(dash)
		local c_se				lcol(black) lpattern(dash)
	
		# delimit ;
		twoway (lowess mean_age age if R == 0, bwidth(`bwidth`sex'') `c_mean')
				(lowess mean_age age if R == 1, bwidth(`bwidth`sex'') `t_mean')
				(lowess plus age if R == 0, bwidth(`bwidth`sex'') `c_se')
				(lowess plus age if R == 1, bwidth(`bwidth`sex'') `t_se')
				(lowess minus age if R == 0, bwidth(`bwidth`sex'') `c_se')
				(lowess minus age if R == 1, bwidth(`bwidth`sex'') `t_se'),
				`graphregion'
				`xaxis'
				`yaxis'
				`legend';
		graph export "`source'_25-65_`file_specs'_`name`sex''.eps", replace;
		# delimit cr
		
	restore
	
	}
}
