tempfile fulldata
save `fulldata'

foreach sex in male female pooled {
	use `fulldata', clear
	if "`sex'" == "male" keep if male == 1
	if "`sex'" == "female" keep if male == 0

	* determine file names by P_switch
	foreach P_switch in 10 0 1 {	
		if `P_switch' == 0 local P_suffix _P0
		else if `P_switch' == 1 local P_suffix _P1
		else local P_suffix 
		file open itt_pooled_P`P_switch' using "${results}/itt/${component}_`sex'`P_suffix'.csv", write replace
	}

	* bootstrap estimates
	
	* keep the IDs of the original sample to perform ABC bootstraps
	tempfile bsid_orig
	preserve
	keep if adraw == 0
	keep id male family
	save `bsid_orig', replace
	restore
	
	* prepare tempfiles for the loops below
	tempfile bsid_draw
	tempfile preaux
	forvalues brep = 0/$breps {
		if `brep' != 0 {
			* perform the ABC bootstrap
			preserve
			use `bsid_orig', clear
			bsample, strata(male) cluster(family)
			save `bsid_draw', replace
			restore
		}
		preserve
		save `preaux', replace
		forvalues arep = 0/$areps {
			* now perform the auxiliary 'bootstrap'; note you are not truly resampling,
			* hence the 'nobsample' option; instead, you're looping through the 'adraw' values
			use `preaux', clear
			keep if adraw == `arep'
			if `brep' != 0 merge 1:m id male family using `bsid_draw', keep(3)
			ittestimate, draw(`brep') ddraw(`arep') yglobal("yvars") controls(${controls}) lipw nobsample
		}
		restore
	}

	* close files
	foreach P_switch in 10 0 1 {
		file close itt_pooled_P`P_switch'
	}
}




cd "${dofiles}"
