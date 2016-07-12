*=======================================================
* Function to perform estimates
*=======================================================

capture program drop ittestimate
program define ittestimate, eclass

version 12
syntax ,  [draw(integer -999) ddraw(integer -999) bygender yglobal(string) controls(varlist) p(integer -1) lipw quietly nobsample] 

tempfile origfile
save `origfile'

* determine if we need to loop through genders, or just pooled
if "`bygender'" != "" local gender_loop male female pooled  
else local gender_loop pooled 

* bootstrap resample if necessary 
*if !(`draw' == 0 & (`ddraw' == 0 | `ddraw' == -999)) bsample, strata(male) cluster(family)
if "`nobsample'" == "" {
	if !(`ddraw' == 0 | `ddraw' == -999) bsample, strata(male) cluster(family)
}

* estimate factors
if $factors == 1 {
	di as input "Bootstrap `draw': estimating factors"
	run factors.do
}

tempfile preprobit
save `preprobit'

* generate IPW weights using the command we wrote
di as input "Bootstrap `draw': estimating IPW weights"
if "`lipw'" == "" ipwweights, iprefix("_i_") varsglobal("ipwvars") 
if "`lipw'" != "" {
	lipwweights, iprefix("_i_") varsglobal("ipwvars") 
	local lipw_warning " with Linear IPW"
}

* limit to P=1 or P=0 as required
if `p' == 1 keep if P == 1 | R == 1
if `p' == 0 keep if P == 0 | R == 1

tempfile allsex
save `allsex', replace

foreach sex in `gender_loop' {
	use `allsex', clear
	if "`sex'" == "male" keep if male == 1
	if "`sex'" == "female" keep if male == 0

	tempfile allP
	save `allP', replace
	
	foreach p in 10 0 1 {
		* limit to P=1 or P=0 as required
		use `allP', clear
		if `p' == 1 keep if P == 1 | R == 1
		if `p' == 0 keep if P == 0 | R == 1

		* determine if headers need to be written in output, depending on draw() option
		if `draw' == 0  & (`ddraw' == 0 | `ddraw' == -999) local header_switch header 
		else local header_switch 	

		foreach y in `"${`yglobal'}"' {
					
			* ITT without controls or weights
			capture reg `y' R
			if _rc continue
			mat r = r(table)
			local itt_noctrl = r[1,1]
			local itt_noctrl_p = r[4,1] // TWO-SIDED
			local itt_noctrl_N = e(N)
			
			* ITT with controls
			capture reg `y' R `controls'
			if _rc continue
			mat r = r(table)
			local itt_ctrl = r[1,1]
			local itt_ctrl_p = r[4,1] // TWO-SIDED
			local itt_ctrl_N = e(N)
			
			* ITT with controls and weights
			capture confirm variable _i_`y'
			if !_rc local weight [w = _i_`y']
			else local weight

			capture reg `y' R `controls' `weight'
			if _rc continue
			mat r = r(table)
			local itt_wctrl = r[1,1]
			local itt_wctrl_p = r[4,1] // TWO-SIDED
			local itt_wctrl_N = e(N)
			
			* output results
			mat itt = [`itt_noctrl', `itt_noctrl_p', `itt_noctrl_N', `itt_ctrl', `itt_ctrl_p', `itt_ctrl_N', `itt_wctrl', `itt_wctrl_p', `itt_wctrl_N']
			mat colname itt = itt_noctrl itt_noctrl_p itt_noctrl_N itt_ctrl itt_ctrl_p itt_ctrl_N itt_wctrl itt_wctrl_p itt_wctrl_N

			* deal with double bootstrap
			if `ddraw' != -999 {
				mat ddraw = [`ddraw']
				mat colname ddraw = ddraw
				mat itt = [ddraw, itt]
			}
					
			writematrix, output(itt_`sex'_P`p') rowname("`y'") matrix(itt) write_draw(`draw') `header_switch'
			local header_switch 
			
			if "`quietly'" == "" {
				if `ddraw' == -999 di as input "Estimated ITT for (Draw `draw', `sex', `y')"
				else di as input "Estimated ITT`lipw_warning' for (Draw (`draw', `ddraw'), `sex', `y')"
			}
		}
	}
}

use `origfile', clear

end

