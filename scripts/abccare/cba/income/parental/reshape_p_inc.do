/*
Convert p_inc projections from maternal age to subject age
*/

global projects : env projects
global klmshare : env klmshare
global data_dir = "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/income/rslt/projections/parental"
global abc_dir 	= "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"

local sexes pooled male female

foreach sex in `sexes' {
	cd $data_dir
	insheet using parental_labor_proj_`sex'.csv, clear
	
	rename v2 id
	drop v50 v51
	
	forval i = 3/49 {
		local a = `i' + 18
		rename v`i' proj_`a'
	
	}
	
	cd $abc_dir
	merge m:1 id using append-abccare_iv
	
	keep adraw id proj_* m_age0y
	
	forval a = 21/67 {
		gen child_age`a' = `a' - m_age0y
		levelsof child_age`a', local(child`a')
	}
	forval a = 21/67 {
		foreach child_age in `child`a'' {
			cap gen c`child_age' = .
		}
	}
	
	forval m_a = 21/67 {
		forval c_a = 0/54 {
			replace c`c_a' = proj_`m_a' if child_age`m_a' == `c_a'
		}
	}
	
	replace id = 9999 if id == .x
	
	keep id adraw c? c??
	sort id adraw
	
	cd $data_dir
	export delim using p_inc_proj_`sex'.csv, replace
	
}
