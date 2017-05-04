/*
Project:		ABC CBA
Script:			Graph Parental Income Forecasts
Author:			Anna Ziff (aziff@uchicago.edu)
Original date:	September 26, 12016
*/

// macros

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
global data_dir      = "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/income/rslt/projections/parental"
global incomeresults = "${klmmexico}/abccare/income_projections/current"
global output        = "${projects}/abc-treatmenteffects-finalseason/output"

// prepare data for graphing

cd $dataabccare
use append-abccare_iv.dta, clear

drop if R == 0 & RV == 1
keep id R male 

tempfile abccare_data
save `abccare_data'

cd $incomeresults
insheet using "parental_labor_proj_pooled.csv", clear

local varlist
local ages
local se_varlist

rename v2 id

forval i = 3/49 {
	capture confirm var v`i'
	if !_rc {
		local a = `i' + 18
		
		rename v`i' c`a'
		
		local ages `ages' c`a'
	}
}	

merge m:1 id using `abccare_data', nogen
	
sort id adraw

collapse (mean) `ages', by(id)
	
drop if id == 9999

foreach stat in mean semean {
	preserve
		collapse (`stat') `ages', by(R male)
		rename c* `stat'*
			
		tempfile `stat'_collapse
		save ``stat'_collapse'
	restore
}

use `mean_collapse', clear
merge m:m R male using `semean_collapse', nogen
	asd
drop if R == .
gen N = _n
reshape long mean_age semean_age, i(N) j(age)
	
gen plus = mean_age + semean_age
gen minus = mean_age - semean_age
		
		
		
// limit to 25-60 and scale income
drop if age > 65  //age < 25 |
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
	local xaxis				xtitle("Age") xlabel(20[5]65, grid glcol(gs14))
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
		graph export "`source'_25-65_`file_specs'_`name`sex''_parental.eps", replace;
		# delimit cr
		
	restore
	
	}
}
