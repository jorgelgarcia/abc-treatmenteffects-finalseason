* --------------------------------------------------------------------------- *
* ABC Attrition Plot with Reason for Attrition
* Author: Anna Ziff using information collected by Andrés Hojman
* Original: 	12/5/15
* Updated: 		1/7/16
* --------------------------------------------------------------------------- *

global klmshare: env klmshare
global projects: env projects

* Directory where information on attrition is held
cd ${klmshare}
cd ziff/abc-cba/abc-attrition

* --------------------------------------------------------------------------- *
* Define locals to create data

local stages orig /*base*/ start /*end*/ a21 a30 crime health

local orig_num					1
//local base_num				
local start_num					2
//local end_num					
local a21_num					3
local a30_num					4
local health_num				6
local crime_num					5

local issues left wd adopted sick highrisk refused died oth

local categories withdrawn not_followed death other

local withdrawn_list 			adopted left
local not_followed_list			sick highrisk refused
local death_list				died
local other_list				oth

local withdrawn_num				1
local not_followed_num			2
local death_num					3
local other_num					4
local interviewed_num			5


* --------------------------------------------------------------------------- *
* Prepare the data

import excel using "attrition.xlsx", clear firstrow

rename orig data_orig
gen orig = ""

local vars_to_collapse

foreach s of local stages {

	gen interviewed``s'_num' = 0
	replace interviewed``s'_num' = 1 if `s' == ""
	
	foreach i of local issues {
		gen `i'``s'_num' = 0
		replace `i'``s'_num' = 1 if `s' == "`i'"
	}
	
	foreach c of local categories {
		
		local vars_to_collapse `vars_to_collapse' `c'``s'_num'
		
		local to_sum
		
		foreach t of local `c'_list {
			local to_sum `to_sum' `t'``s'_num'
		}
		
		egen `c'``s'_num' = rowtotal(`to_sum')
		
	}
	
}

keep id group `vars_to_collapse' interviewed*

reshape long `categories' interviewed, i(id) j(stage) 

gen reason = .
foreach c in interviewed withdrawn not_followed death other{
	replace reason = ``c'_num' if `c' == 1
}

* --------------------------------------------------------------------------- *
* Locals for graph

local barwidth		barwidth(0.5)

local yline			yline(0, lcol(black) lstyle(yxline))

local region		graphregion(color(white))
local legend		legend(symy(3) symx(7) size(small) rows(3) cols(3) holes(3 4 7) order(1 - "Attrition reason:" 2 3 4 5)label(1 Interviewed) label(2 Withdrawn) label(3 Not Followed) label(4 Death) label(5 Other))

local xlabel 		xlabel(1 "Original" 2 "Baseline" 3 "Age 21" 4 "Age 30" 5 "Crime" 6 "Health")
local xtitle		xtitle("")

local ylabel		ylabel(none)
local ytitle		ytitle("Control           Treatment")	

local int_col		color(gs10) 
local oth_col		color(purple)
local nf_col		color(blue)
local wd_col		color(red)
local d_col			color(green)

* --------------------------------------------------------------------------- *
* Additional variables for graph

collapse (sum) `categories' interviewed, by(stage group)

gen label_num = interviewed
foreach c in withdrawn not_followed death other interviewed {
	replace `c' = -`c' if group == 0
}

gen label_place = 39
replace label_place = -39 if group == 0


gen tot = .
replace tot = -57 if group == 0
replace tot = 65 if group == 1

gen zero = 0
gen axis = 0.1
//replace withdrawn = 0 if withdrawn == -1
gen nf = withdrawn + not_followed
gen de = withdrawn + not_followed + death
gen oth = withdrawn + not_followed + death + other

* --------------------------------------------------------------------------- *
cd "$projects/abc-treatmenteffects-finalseason/output/"

#delimit ;

graph twoway (rbar tot zero stage, `barwidth' `ytitle' `ylabel' `region' `int_col')
			(rbar withdrawn zero stage, `barwidth' `wd_col')
			(rbar nf withdrawn stage, `barwidth' `xtitle' `xlabel' `nf_col')
			(rbar de nf stage, `barwidth' `xtitle' `xlabel' `d_col')
			(rbar oth de stage, `barwidth' `oth_col' `legend')
			(rbar axis zero stage, color(black))
			(scatter label_place stage, mlabel(label_num) mlabcolor(black) msymb(i) mlabpos(0) mlabsize(medium));
			
			graph export abc_attrition.eps, replace;
			
