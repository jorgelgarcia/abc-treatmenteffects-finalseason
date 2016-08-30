/*

Project:		ABC CBA
Script:			Graph Income Forecasts
Author:			Anna Ziff (aziff@uchicago.edu)
Original date:	August 29, 2016

*/

// macros
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
global data_dir      = "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/income/rslt/projections"
global incomeresults = "${klmmexico}/abccare/income_projections/aug-30/"
global output        = "${projects}/abc-treatmenteffects-finalseason/output/"

// prepare data for graphing

cd $dataabccare
use append-abccare_iv.dta, clear

drop if R == 0 & RV == 1
keep id R male

tempfile abccare_data
save `abccare_data'


foreach source in labor /*transfer*/ {

	cd $incomeresults
	insheet using "`source'_proj_pooled.csv", clear

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
		drop if age < 25 | age > 60
		foreach v in mean_age semean_age plus minus {
			replace `v' = `v'/1000
		}
		
	// graph
	cd $output
	forval sex = 0/1 {
	
	preserve

		`drop`sex''
	
		local graphregion		graphregion(color(white))
		local yaxis				ytitle("``source'_name' Income (1000s 2014 USD)") ylabel(#6, format(%9.0gc) glcol(gs15))
		local xaxis				xtitle("Age") xlabel(25[5]60, grid glcol(gs15))
		local legend			legend(rows(1) order(2 1) label(1 "Control") label(2 "Treatment") label(3 "+/- s.e.") label(4 "+/- s.e."))
	
		local t_mean			lcol(gs9) lwidth(1.2)
		local c_mean			lcol(black) lwidth(1.2)
		local t_se				lcol(gs9) lpattern(dash)
		local c_se				lcol(black) lpattern(dash)
	
		# delimit ;
		twoway (line mean_age age if R == 0, `c_mean')
				(line mean_age age if R == 1, `t_mean')
				(line plus age if R == 0, `c_se')
				(line plus age if R == 1, `t_se')
				(line minus age if R == 0, `c_se')
				(line minus age if R == 1, `t_se'),
				`graphregion'
				`xaxis'
				`yaxis'
				`legend';
		graph export "`source'_25-60_`name`sex''.eps", replace;
		# delimit cr
		
	restore
	
	}
}
