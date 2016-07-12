
*=======================================================
* Function to perform estimates
*=======================================================

capture program drop mestimate
program define mestimate, eclass

version 12
syntax ,  [draw(integer -999) ddraw(integer -999) bygender yglobal(string) controls(varlist) lipw quietly nobsample] //mprefix(string) iprefix(string)

tempfile origfile
save `origfile'

* bootstrap resample if necessary 
*if !(`draw' == 0 & (`ddraw' == 0 | `ddraw' == -999)) bsample, strata(male) cluster(family)
if "`nobsample'" == "" {
	if !(`ddraw' == 0 | `ddraw' == -999) bsample, strata(male) cluster(family)
}

* determine if we need to loop through genders, or just pooled
if "`bygender'" != "" local gender_loop male female pooled  
else local gender_loop pooled 

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

* generate Epanechnikov weights
di as input "Bootstrap `draw': estimating Epanechnikov weights"
capture epanechnikov, mprefix("_e_") controls(`controls') bandwidth(20)
if !_rc {
	tempfile allsex
	save `allsex', replace

	foreach sex in `gender_loop' {
		use `allsex', clear
		if "`sex'" == "male" keep if male == 1
		if "`sex'" == "female" keep if male == 0
		
		tempfile allP
		save `allP', replace
	
		foreach p in 0 1 {
			* limit to P=1 or P=0 as required
			use `allP', clear
			if `p' == 1 keep if P == 1 | R == 1
			if `p' == 0 keep if P == 0 | R == 1

			* determine if headers need to be written in output, depending on draw() option
			if `draw' == 0  & (`ddraw' == 0 | `ddraw' == -999) local header_switch header 
			else local header_switch 	

			foreach y in `"${`yglobal'}"' {
				* restrict the estimates to those who we can actually estimate effects for
				capture reg `y' `controls' R
				if _rc continue
				keep if e(sample) == 1

				* determine who is in treatment and who is in control
				levelsof id if R == 1 & e(sample) == 1, local(ids_R)
				levelsof id if R == 0 & e(sample) == 1, local(ids_control)

				* multiply matching weights with IPW weights
				foreach id in `ids_control' `ids_R' {
					capture confirm variable _i_`y'
					if !_rc {
						local weight [w = _i_`y']
						gen _ie_`y'`id' = _e_`id' * _i_`y'
					}
					else {
						local weight
						gen _ie_`y'`id' = _e_`id'
					}
				}
				
				* Do not match treated with P = 1 to treatment with P = 0
				levelsof id if R == 0 & P == 0, local(control_noP)
				foreach id in `control_noP' {
					capture replace _ie_`y'`id' = . if R == 1 & P == 1
				}	

				* Do not match control with P = 0 to treatment with P = 1
				levelsof id if R == 1 & P == 1, local(R_P)
				foreach id in `R_P' {
					capture replace _ie_`y'`id' = . if R == 0 & P == 0
				}
				
				* generate counterfactuals
				capture drop _counter0
				capture drop _counter1
				capture drop _TE
				gen _counter0 = .
				gen _counter1 = .
				
				replace _counter0 = `y' if R == 0
				replace _counter1 = `y' if R == 1
				
				foreach id in `ids_control' `ids_R' {
					capture sum `y' [w = _ie_`y'`id']
					if _rc continue
					replace _counter0 = r(mean) if R == 1 & id == `id'
					replace _counter1 = r(mean) if R == 0 & id == `id'	
				}
				
				* estimate treatment effects
				gen _TE = _counter1 - _counter0
				capture sum _TE `weight'
				if _rc continue
				
				* output results
				mat ate = [r(mean), r(N)]
				mat colname ate = epan_ipw epan_N
				
				* deal with double bootstrap
				if `ddraw' != -999 {
					mat ddraw = [`ddraw']
					mat colname ddraw = ddraw
					mat ate = [ddraw, ate]
				}
				
				writematrix, output(matching_`sex'_P`p') rowname("`y'") matrix(ate) write_draw(`draw') `header_switch'
				local header_switch 
				
				if "`quietly'" == "" {
					if `ddraw' == -999 di as input "Estimated ATE for (Draw `draw', `sex', `y')"
					else di as input "Estimated ATE`lipw_warning' for (Draw (`draw', `ddraw'), `sex', `y')"
				}
				
				* drop y-specific variables
				drop _ie_`y'*
				drop _counter0 _counter1
				drop _TE
			}
		}
	}
}

use `origfile', clear

end
