/* 
Project: 			ABC and CARE CBA
This file:			Compare TE on life cycle parental income by # of siblings
Author:				Anna Ziff
Original date:		September 27, 2016
*/

// macros
global klmshare	:	env klmshare
global projects	:	env projects
global ate_dir 	= "${projects}/abc-treatmenteffects-finalseason/data/abccare/extensions/outcomes_ate"
global proj_dir = "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/income/rslt/projections/parental"
global output	= "${projects}/abc-treatmenteffects-finalseason/output"

local KEEP0				keep if male == 0
local KEEP1				keep if male == 1
local KEEP2

local NAME0				female
local NAME1				male
local NAME2				pooled

// construct discounted NPVS
cd $ate_dir
use outcomes_ate, clear

drop if R == 0 & RV == 1

keep id R male hh_sibs0y p_inc*

rename p_inc0y	 p_inc0
rename p_inc1y6m p_inc1
rename p_inc2y6m p_inc2
rename p_inc3y6m p_inc3
rename p_inc4y6m p_inc4
rename p_inc5y	 p_inc5
rename p_inc8y	 p_inc8
rename p_inc12y	 p_inc12
rename p_inc15y  p_inc15
rename p_inc21y  p_inc21

tempfile ate
save `ate'

cd $proj_dir
insheet using parental_labor_proj_pooled.csv, clear

rename v2 id
drop v50 v51

collapse v*, by(id)

forval i = 3/49 {
	local a = `i' - 3
	
	rename v`i' v`a'
}

merge 1:1 id using `ate', nogen

local ages 0 1 2 3 4 5 8 12 15 21
foreach a in `ages'{
	replace v`a' = p_inc`a' if v`a' == .
}
drop p_inc*

forval a = 0/46 {
	replace v`a' = v`a'/(1.03)^`a'
}

egen pinc_npv = rowtotal(v*)
replace pinc_npv = pinc_npv/1000
gen anysibs = (hh_sibs0y > 0)

// treatment effects

forval sex = 0/2 {
	preserve
		`KEEP`sex''
		
		forval sib = 0/1 {
		
			reg pinc_npv R if anysibs == `sib'
			mat TAB`sib'_`sex' = r(table)
			local TE`sib'_`sex' = TAB`sib'_`sex'[1,1]
			local P`sib'_`sex' = TAB`sib'_`sex'[4,1]
		}
		matrix results = [`TE0_`sex'', `P1_`sex'' \ `TE1_`sex'', `P0_`sex'']
		clear
		svmat results
	
		rename results1 TE
		rename results2 P
		gen sibs = _n
		gen base = 0
	
		// graph
		local no_sibs 	color(gs8) barwidth(.9)
		local sibs		color(gs4) barwidth(.9)
		local ppoint	msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(large)
		
		local region	graphregion(color(white))
		local legend	legend(cols(3) order(1 "No Siblings at Baseline" 2 "> 0 Siblings at Baseline" 3 "p-value {&le} .10") size(small))
		local yaxis		ytitle("Treatment Effect on Parental Income (1000s of 2014 USD)", size(small))  ylabel(0[20]100, angle(h) glcolor(gs14))
		local xaxis 	xlabel(1 " " 2 " ", angle(45) noticks grid glcolor(gs14) labsize(small)) xtitle("")
		
		twoway (rbar base TE sibs if sibs == 1, `no_sibs') ///
				(rbar base TE sibs if sibs == 2, `sibs') ///
				(scatter TE sibs if P <= 0.10, `ppoint'), ///
				`region' `legend' `xaxis' `yaxis'
		graph export ${output}/abccare_pinc_npv_`NAME`sex''.eps, replace
	
	restore
}



