clear all
set maxvar 32000
set more off


global projects: env projects
global dofiles "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/ratio_irr/flows"
global income "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/income/rslt"
global health "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/health/rslt"
global batch "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/batch/rslt"

global output "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/ratio_irr/flows"

cd "$dofiles"
run converter

local smale m
local sfemale f
local spooled p

local sitt10
local sitt0 _P0 
local sitt1 _P1

/*
*---------------------------------
* Income
*---------------------------------

foreach component in labor transfer {
	foreach sex in male female pooled {
		foreach pre in 0 1 {
			* matching
			converter, csvin(${income}/matching/`component'_`sex'_P`pre') csvout(${output}/p`pre'_match/`component'_`s`sex'') ename(epan_ipw) prefix(c)
			* conditional ITT
			converter, csvin(${income}/itt/`component'_`sex'_P`pre') csvout(${output}/p`pre'_noctrl/`component'_`s`sex'') ename(itt_noctrl) prefix(c) 
			converter, csvin(${income}/itt/`component'_`sex'_P`pre') csvout(${output}/p`pre'_ctrl/`component'_`s`sex'') ename(itt_ctrl) prefix(c) 			
			converter, csvin(${income}/itt/`component'_`sex'_P`pre') csvout(${output}/p`pre'_wctrl/`component'_`s`sex'') ename(itt_wctrl) prefix(c) 			
		}
		* ITT
		converter, csvin(${income}/itt/`component'_`sex') csvout(${output}/ncc_noctrl/`component'_`s`sex'') ename(itt_noctrl) prefix(c) 
		converter, csvin(${income}/itt/`component'_`sex') csvout(${output}/ncc_ctrl/`component'_`s`sex'') ename(itt_ctrl) prefix(c) 			
		converter, csvin(${income}/itt/`component'_`sex') csvout(${output}/ncc_wctrl/`component'_`s`sex'') ename(itt_wctrl) prefix(c) 
	}
}


*---------------------------------
* Health
*---------------------------------

foreach component in  diclaim_surv ssiclaim_surv ssclaim_surv qaly_surv health_private health_public { /* */
	foreach sex in male female pooled {
		foreach pre in 0 1 {
			* matching
			converter, csvin(${health}/matching/`component'_`sex'_P`pre') csvout(${output}/p`pre'_match/`component'_`s`sex'') ename(epan_ipw) prefix(`component')
			* conditional ITT
			converter, csvin(${health}/itt/`component'_`sex'_P`pre') csvout(${output}/p`pre'_noctrl/`component'_`s`sex'') ename(itt_noctrl) prefix(`component') 
			converter, csvin(${health}/itt/`component'_`sex'_P`pre') csvout(${output}/p`pre'_ctrl/`component'_`s`sex'') ename(itt_ctrl) prefix(`component') 			
			converter, csvin(${health}/itt/`component'_`sex'_P`pre') csvout(${output}/p`pre'_wctrl/`component'_`s`sex'') ename(itt_wctrl) prefix(`component')			
		}
		* ITT
		converter, csvin(${health}/itt/`component'_`sex') csvout(${output}/ncc_noctrl/`component'_`s`sex'') ename(itt_noctrl) prefix(`component') 
		converter, csvin(${health}/itt/`component'_`sex') csvout(${output}/ncc_ctrl/`component'_`s`sex'') ename(itt_ctrl) prefix(`component') 			
		converter, csvin(${health}/itt/`component'_`sex') csvout(${output}/ncc_wctrl/`component'_`s`sex'') ename(itt_wctrl) prefix(`component')
	}
}

*/
*---------------------------------
* Batch
*---------------------------------

foreach component in private_crime public_crime { // p_inc educost progcost cccostprivate cccostpublic 
	foreach sex in male female pooled {
		foreach pre in 0 1 {
			* matching
			converter, csvin(${batch}/matching/`component'_`sex'_P`pre') csvout(${output}/p`pre'_match/`component'_`s`sex'') ename(epan_ipw) prefix(`component') 
			* conditional ITT
			converter, csvin(${batch}/itt/`component'_`sex'_P`pre') csvout(${output}/p`pre'_noctrl/`component'_`s`sex'') ename(itt_noctrl) prefix(`component') 
			converter, csvin(${batch}/itt/`component'_`sex'_P`pre') csvout(${output}/p`pre'_ctrl/`component'_`s`sex'') ename(itt_ctrl) prefix(`component') 			
			converter, csvin(${batch}/itt/`component'_`sex'_P`pre') csvout(${output}/p`pre'_wctrl/`component'_`s`sex'') ename(itt_wctrl) prefix(`component') 						
		}
		* ITT
		converter, csvin(${batch}/itt/`component'_`sex') csvout(${output}/ncc_noctrl/`component'_`s`sex'') ename(itt_noctrl) prefix(`component') 
		converter, csvin(${batch}/itt/`component'_`sex') csvout(${output}/ncc_ctrl/`component'_`s`sex'') ename(itt_ctrl) prefix(`component') 			
		converter, csvin(${batch}/itt/`component'_`sex') csvout(${output}/ncc_wctrl/`component'_`s`sex'') ename(itt_wctrl) prefix(`component') 		
		
	}
}

/*
/*
* special crimes, without murder
foreach component in private_crime public_crime {
	foreach sex in male female pooled {
		foreach pre in 0 1 {
			* matching
			converter, csvin(${batch}/matching/`component'_`sex'_P`pre'nm) csvout(${output}/p`pre'_match/`component'_`s`sex'') ename(epan_ipw) prefix(`component') 
			* conditional ITT
			converter, csvin(${batch}/itt/`component'_`sex'_P`pre'nm) csvout(${output}/p`pre'_noctrl/`component'_`s`sex'') ename(itt_noctrl) prefix(`component') 
			converter, csvin(${batch}/itt/`component'_`sex'_P`pre'nm) csvout(${output}/p`pre'_ctrl/`component'_`s`sex'') ename(itt_ctrl) prefix(`component') 			
			converter, csvin(${batch}/itt/`component'_`sex'_P`pre'nm) csvout(${output}/p`pre'_wctrl/`component'_`s`sex'') ename(itt_wctrl) prefix(`component') 						
		}
		* ITT
		converter, csvin(${batch}/itt/`component'_`sex'nm) csvout(${output}/ncc_noctrl/`component'_`s`sex'') ename(itt_noctrl) prefix(`component') 
		converter, csvin(${batch}/itt/`component'_`sex'nm) csvout(${output}/ncc_ctrl/`component'_`s`sex'') ename(itt_ctrl) prefix(`component') 			
		converter, csvin(${batch}/itt/`component'_`sex'nm) csvout(${output}/ncc_wctrl/`component'_`s`sex'') ename(itt_wctrl) prefix(`component') 		
		
	}
}
*/

*---------------------------------
* Parent Income
*---------------------------------


foreach sex in male female pooled {
	foreach pre in ncc p0 p1 {
		if "`pre'" == "ncc" local etype_loop ctrl noctrl wctrl 
		if "`pre'" != "ncc" local etype_loop ctrl noctrl wctrl match
		foreach etype in `etype_loop' {
			insheet using ${output}/`pre'_`etype'/p_inc_`s`sex''.csv, clear names
			* interpolate
			forvalues age = 5/7 {
				replace c`age' = (`age' - 4) * (c8 - c4)/4 + c4
			}
			forvalues age = 9/11 {
				replace c`age' = (`age' - 8) * (c12 - c8)/4 + c8
			}
			forvalues age = 13/14 {
				replace c`age' = (`age' - 12) * (c15 - c12)/3 + c12
			}
			forvalues age = 16/20 {
				replace c`age' = (`age' - 15) * (c21 - c15)/6 + c15
			}			
			outsheet using "${output}/`pre'_`etype'/p_inc_`s`sex''.csv", comma replace
			sum c1
		}
	}
}




*/
