/* ----------------------------------------------------------------------- *
* Calculating the effect sizes of ABC-CARE outcomes
* Author:	Jessica Yu Kyung Koh
* Date:		03/15/2017
* Note: 	This do file generates the effect size of ABC-CARE outcomes
			An effect size is an quantitative measure of the difference between
			two groups. Effect sizes are calculated based on the `standardized
			mean difference' between two groups in a trial.
			Effect size = ((mean of experimental group) - (mean of control group))/(standard deviation)
			The effects are based on the observation of BIC-selected control variables (apgar1, apgar5, hrabc_index)
			if apgar1 < . & apgar5 < . & hrabc_index < . 
* ------------------------------------------------------------------------- */
clear all

* ------------------------------------------------------ *
* Preparation
* ------------------------------------------------------ *
* Set macro
global klmshare 	: env klmshare
global git_abccba  : env git_abccba 
global abc_data		= "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global scripts		= "${git_abccba}/scripts/abccare"


* ------------------------------------------------------ *
* Collect outcomes
* ------------------------------------------------------ *
* collect variable names to estimate effects for
cd "$scripts"
cd outcomes
insheet using "outcomes_cba_effectsize.csv", comma clear names

levelsof variable, local(yvars)
global outcomes `yvars'


* ------------------------------------------------------ *
* Calculate an effect size for each outcome
* ------------------------------------------------------ *
* Bring in data
cd "$abc_data"
use append-abccare_iv, clear

* Drop CARE home visit people
drop if RV == 1 & R == 0 

* Define local for gender
global p
global m		& male == 1
global f		& male == 0

* Calculate effect size for each outcome
foreach gender in p m f {
	foreach var in `"$outcomes"' {

		di "For outcome: `var'"
		
		* Calculate the standard error of the pulled sample
		summ `var' if apgar1 < . & apgar5 < . & hrabc_index < . ${`gender'}
		di "summ `var' if apgar1 < . & apgar5 < . & hrabc_index < . ${`gender'}"
		
		local sd_`var'_`gender' = r(sd)
		
		* Calculate the mean of the treatment group
		summ `var' if R == 1 & apgar1 < . & apgar5 < . & hrabc_index < . ${`gender'}
		local Tmean_`var'_`gender' = r(mean)
		
		* Calculate the mean of the control group
		summ `var' if R == 0 & apgar1 < . & apgar5 < . & hrabc_index < . ${`gender'}
		local Cmean_`var'_`gender' = r(mean)	
		
		* Calculate the effect size 
		local es_`var'_`gender' = (`Tmean_`var'_`gender'' - `Cmean_`var'_`gender'')/(`sd_`var'_`gender'')
		
	}
}

* ------------------------------------------------------ *
* Store values into a CSV output
* ------------------------------------------------------ *
* Open a CSV that we are writing in
file open effectsize using "${scripts}/treatmenteffects/effect-size/output/abccare-effectsize.csv", write replace

* Write the header
file write effectsize "variable, effect_size_pooled, effect_size_male, effect_size_female" _n

* Write the effect size
foreach var in `"$outcomes"' {
	file write effectsize "`var', `es_`var'_p', `es_`var'_m', `es_`var'_f'" _n
}

* Close the CSV file
file close effectsize


* ------------------------------------------------------ *
* Mearge effect-size csv and description of variable
* ------------------------------------------------------ *	
clear all

insheet using "${scripts}/treatmenteffects/effect-size/output/abccare-effectsize.csv", comma clear names
tempfile effectsize_temp
save "`effectsize_temp'"
		
insheet using "${scripts}/outcomes/outcomes_cba_effectsize.csv", comma clear names
keep variable age label

merge 1:1 variable using `effectsize_temp'
drop _merge

export delimited using "${scripts}/treatmenteffects/effect-size/output/abccare-effectsize.csv", replace

