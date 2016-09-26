version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC
Description:    plot estimates conditional on IQ
*This version:  April 18, 2016
*This .do file: Jorge L. Garcia
*This project : All except Seong, B. and CC. 
*/

// set environment variables (server)
global erc: env erc
global projects: env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// set general locations
// do files
global scripts     = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global allresults  = "$klmmexico/abccare/irr_ratios/current"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"


// get all baseline types
foreach num of numlist 1(1)11 {
	foreach par in irr ratio {
		cd $allresults/type`num'
		foreach stat in mean se pval {
			insheet using `par'_`stat'.csv, clear
			foreach sex in m f p {
				summ v2 if v1 == "`sex'"
				local `par'_`stat'_type`num'_`sex' = r(mean)
			}
		}
	}
}

// drop murders and rapes from 
foreach num of numlist 2 {
	foreach par in irr ratio {
		cd $allresults/type`num'_nm
		foreach stat in mean se pval {
			insheet using `par'_mean.csv, clear
			foreach sex in m f p {
				summ v2 if v1 == "`sex'"
				local `par'_`stat'_type`num'_nm_`sex' = r(mean)
			}
		}
	}
}


// deadweight-loss cases
cd $allresults/sensitivity
foreach par in bc irr {
	insheet using `par'_dwl.csv, clear
	keep if rate == 0 | rate == 1
	foreach var of varlist mean se pval {
		foreach rate of numlist 0 1 {
			foreach sex in f m p {
				summ `var' if v1 == "`sex'" & rate == `rate'
				local `par'_`var'_rate`rate'_`sex' = r(mean)
			}
		}
	}
}

// discount
cd $allresults/sensitivity
insheet using bc_discount.csv, clear
replace rate = rate*100
keep if rate == 0 | rate == 7
foreach var of varlist mean se pval {
	foreach rate of numlist 0 7 {
		foreach sex in f m  p {
			summ `var' if v1 == "`sex'" & rate == `rate'
			local bc_`var'_discount`rate'_`sex' = r(mean)
		}
	}
}


// up to age x
cd $allresults/sensitivity
foreach par in ratios irr {
	insheet using `par'_age_type2.csv, clear
	keep if age == 21 | age == 30
	foreach var of varlist mean se pval {
		foreach age in 21 30 {
			foreach sex in f m p {
				summ `var' if sex == "`sex'" & age == `age'
				local `par'_`var'_age`age'_`sex' = r(mean)
			}
		}
	}
}

// 1.25 parental income (approximate Mincer-type)
cd $allresults/sensitivity
foreach par in bc irr {
	insheet using `par'_factors.csv, clear
	keep if part == "inc_parent" & rate == 1.25
	foreach var of varlist mean se pval {
		foreach sex in f m p {
			summ `var' if v1 == "`sex'" 
			local `par'_`var'_mincer_`sex' = r(mean)
		}
	}
}

// half crime costs 
cd $allresults/sensitivity
foreach par in bc irr {
	insheet using `par'_factors.csv, clear
	keep if part == "crime" & rate == .5
	foreach var of varlist mean se pval {
		foreach sex in f m p {
			summ `var' if v1 == "`sex'" 
			local `par'_`var'_crimhalf_`sex' = r(mean)
		}
	}
}

// wage growth and decline
cd $allresults/sensitivity
foreach par in bc irr {
	insheet using `par'_factors.csv, clear
	keep if part == "inc_labor" & (rate == .75 | 1.25)
	replace rate = 7  if rate == .75
	replace rate = 12 if rate == 1.25
	foreach var of varlist mean se pval {
		foreach sex in f m p {
			foreach num of numlist 7 12 {
				summ `var' if v1 == "`sex'" & rate == `num'
				local `par'_`var'_incgrowth`num'_`sex' = r(mean)
			}
		}
	}
}

// double value of life 
cd $allresults/sensitivity
foreach par in bc irr {
	insheet using `par'_factors.csv, clear
	keep if part == "qaly" & (rate == 2 | rate == 0)
	foreach var of varlist mean se pval {
		foreach sex in f m p {
			foreach num of numlist 0 2 {
				summ `var' if v1 == "`sex'" & rate == `num'
				local `par'_`var'_valife`num'_`sex' = r(mean)
			}
		}
	}
}

// arrange matrix
// bc/ratio
matrix baselinebc        = [`ratio_mean_type2_f',`ratio_se_type2_f',`ratio_mean_type2_m',`ratio_se_type2_m',`ratio_mean_type2_p',`ratio_se_type2_p']
matrix specification   = [[`ratio_mean_type9_f' \ `ratio_se_type9_f' \ `ratio_pval_type9_f'], [`ratio_mean_type1_f' \ `ratio_se_type1_f' \ `ratio_pval_type1_f' ],  [`ratio_mean_type9_m' \ `ratio_se_type9_m' \ `ratio_pval_type9_m'], [`ratio_mean_type1_m' \ `ratio_se_type1_m' \ `ratio_pval_type1_m'], [`ratio_mean_type9_p' \ `ratio_se_type9_p' \ `ratio_pval_type9_p'],  [`ratio_mean_type1_p' \ `ratio_se_type1_p' \ `ratio_pval_type1_p']]
matrix predictiontime  = [[`ratios_mean_age21_f' \ `ratios_se_age21_f' \ `ratios_pval_age21_f'], [`ratios_mean_age30_f' \ `ratios_se_age30_f' \ `ratios_pval_age30_f'], [`ratios_mean_age21_m' \ `ratios_se_age21_m' \ `ratios_pval_age21_m'], [`ratios_mean_age30_m' \ `ratios_se_age30_m' \ `ratios_pval_age30_m'], [`ratios_mean_age21_p' \ `ratios_se_age21_p' \ `ratios_pval_age21_p'], [`ratios_mean_age30_p' \ `ratios_se_age30_p' \ `ratios_pval_age30_p']] 
matrix counterfactual  = [[`ratio_mean_type5_f' \ `ratio_se_type5_f' \ `ratio_pval_type5_f' ],[`ratio_mean_type8_f' \ `ratio_se_type8_f' \ `ratio_pval_type8_f' ],  [`ratio_mean_type5_m' \ `ratio_se_type5_m' \ `ratio_pval_type5_m'], [`ratio_mean_type8_m' \ `ratio_se_type8_m' \ `ratio_pval_type8_m'], [`ratio_mean_type5_p' \ `ratio_se_type5_p' \ `ratio_pval_type5_p'],  [`ratio_mean_type8_p' \ `ratio_se_type8_p' \ `ratio_pval_type8_p']]
matrix dwl             = [[`bc_mean_rate0_f' \ `bc_se_rate0_f' \ `bc_pval_rate0_f'], [`bc_mean_rate1_f' \ `bc_se_rate1_f' \ `bc_pval_rate1_f'], [`bc_mean_rate0_m' \ `bc_se_rate0_m' \ `bc_pval_rate0_m'], [`bc_mean_rate1_m' \ `bc_se_rate1_m' \ `bc_pval_rate1_m'],  [`bc_mean_rate0_p' \ `bc_se_rate0_p' \ `bc_pval_rate0_p'], [`bc_mean_rate1_p' \ `bc_se_rate1_p' \ `bc_pval_rate1_p']]
matrix discount        = [[`bc_mean_discount0_f' \ `bc_se_discount0_f' \ `bc_pval_discount0_f'], [`bc_mean_discount7_f' \ `bc_se_discount7_f' \ `bc_pval_discount7_f'], [`bc_mean_discount0_m' \ `bc_se_discount0_m' \ `bc_pval_discount0_m'], [`bc_mean_discount7_m' \ `bc_se_discount7_m' \ `bc_pval_discount7_m'],  [`bc_mean_discount0_p' \ `bc_se_discount0_p' \ `bc_pval_discount0_p'], [`bc_mean_discount7_p' \ `bc_se_discount7_p' \ `bc_pval_discount7_p']]
matrix parental        = [[`bc_mean_mincer_f' \ `bc_se_mincer_f' \ `bc_pval_mincer_f'], [. \ . \ .] , [`bc_mean_mincer_m' \ `bc_se_mincer_m' \ `bc_pval_mincer_m'], [. \ . \ .] , [`bc_mean_mincer_p' \ `bc_se_mincer_p' \ `bc_pval_mincer_p'], [. \ . \ .]]
matrix lincome         = [[`bc_mean_incgrowth7_f' \ `bc_se_incgrowth7_f' \ `bc_pval_incgrowth7_f'], [`bc_mean_incgrowth12_f' \ `bc_se_incgrowth12_f' \ `bc_pval_incgrowth12_f'],[`bc_mean_incgrowth7_m' \ `bc_se_incgrowth7_m' \ `bc_pval_incgrowth7_m'], [`bc_mean_incgrowth12_m' \ `bc_se_incgrowth12_m' \ `bc_pval_incgrowth12_m'], [`bc_mean_incgrowth7_p' \ `bc_se_incgrowth7_p' \ `bc_pval_incgrowth7_p'], [`bc_mean_incgrowth12_p' \ `bc_se_incgrowth12_p' \ `bc_pval_incgrowth12_p']] 
matrix crime           = [[`ratio_mean_type2_nm_f' \ `ratio_se_type2_nm_f' \ `ratio_pval_type2_nm_f'], [`bc_mean_crimhalf_f' \ `bc_se_crimhalf_f' \ `bc_pval_crimhalf_f'], [`ratio_mean_type2_nm_m' \ `ratio_se_type2_nm_m' \ `ratio_pval_type2_nm_m'], [`bc_mean_crimhalf_m' \ `bc_se_crimhalf_m' \ `bc_pval_crimhalf_m'], [`ratio_mean_type2_nm_p' \ `ratio_se_type2_nm_p' \  `ratio_pval_type2_nm_p'], [`bc_mean_crimhalf_p' \ `bc_se_crimhalf_p' \ `bc_pval_crimhalf_p']]
matrix health          = [[`bc_mean_valife0_f' \ `bc_se_valife0_f' \ `bc_pval_valife0_f'], [`bc_mean_valife2_f' \ `bc_se_valife2_f' \ `bc_pval_valife2_f'], [`bc_mean_valife0_m' \ `bc_se_valife0_m' \ `bc_pval_valife0_m'], [`bc_mean_valife2_m' \ `bc_se_valife2_m' \ `bc_pval_valife2_m'], [`bc_mean_valife0_p' \ `bc_se_valife0_p' \ `bc_pval_valife0_p'], [`bc_mean_valife2_p' \ `bc_se_valife2_p' \ `bc_pval_valife2_p']]

matrix allbc = [baselinebc \ specification \ predictiontime \ counterfactual \ dwl \ discount \ parental \ lincome \ crime \ health]
matrix rownames allbc = baseline specification "." "." predictiontime "." "." counterfactual "." "." dwl "." "." discount "." "." parental "." "." lincome "." "." crime "." "." health "." "."
matrix allbc = [allbc[1...,5..6],allbc[1...,3..4],allbc[1...,1..2]]

/*
// irr
matrix baselineirr      = [`irr_mean_type2_f',`irr_se_type2_f',`irr_mean_type2_m',`irr_se_type2_m',`irr_mean_type2_p',`irr_se_type2_p']
matrix specification   = [[`irr_mean_type9_f' \ `irr_se_type9_f' \ `irr_pval_type9_f'], [`irr_mean_type1_f' \ `irr_se_type1_f' \ `irr_pval_type1_f' ],  [`irr_mean_type9_m' \ `irr_se_type9_m' \ `irr_pval_type9_m'], [`irr_mean_type1_m' \ `irr_se_type1_m' \ `irr_pval_type1_m'], [`irr_mean_type9_p' \ `irr_se_type9_p' \ `irr_pval_type9_p'],  [`irr_mean_type1_p' \ `irr_se_type1_p' \ `irr_pval_type1_p']]
matrix predictiontime  = [[`irr_mean_age21_f' \ `irr_se_age21_f' \ `irr_pval_age21_f'], [`irr_mean_age30_f' \ `irr_se_age30_f' \ `irr_pval_age30_f'], [`irr_mean_age21_m' \ `irr_se_age21_m' \ `irr_pval_age21_m'], [`irr_mean_age30_m' \ `irr_se_age30_m' \ `irr_pval_age30_m'], [`irr_mean_age21_p' \ `irr_se_age21_p' \ `irr_pval_age21_p'], [`irr_mean_age30_p' \ `irr_se_age30_p' \ `irr_pval_age30_p']] 
matrix counterfactual  = [[`irr_mean_type5_f' \ `irr_se_type5_f' \ `irr_pval_type5_f' ],[`irr_mean_type8_f' \ `irr_se_type8_f' \ `irr_pval_type8_f' ],  [`irr_mean_type5_m' \ `irr_se_type5_m' \ `irr_pval_type5_m'], [`irr_mean_type8_m' \ `irr_se_type8_m' \ `irr_pval_type8_m'], [`irr_mean_type5_p' \ `irr_se_type5_p' \ `irr_pval_type5_p'],  [`irr_mean_type8_p' \ `irr_se_type8_p' \ `irr_pval_type8_p']]
matrix dwl             = [[`irr_mean_rate0_f' \ `irr_se_rate0_f' \ `irr_pval_rate0_f'], [`irr_mean_rate1_f' \ `irr_se_rate1_f' \ `irr_pval_rate1_f'], [`irr_mean_rate0_m' \ `irr_se_rate0_m' \ `irr_pval_rate0_m'], [`irr_mean_rate1_m' \ `irr_se_rate1_m' \ `irr_pval_rate1_m'],  [`irr_mean_rate0_p' \ `irr_se_rate0_p' \ `irr_pval_rate0_p'], [`irr_mean_rate1_p' \ `irr_se_rate1_p' \ `irr_pval_rate1_p']]
matrix parental        = [[`irr_mean_mincer_f' \ `irr_se_mincer_f' \ `irr_pval_mincer_f'], [. \ . \ .] , [`irr_mean_mincer_m' \ `irr_se_mincer_m' \ `irr_pval_mincer_m'], [. \ . \ .] , [`irr_mean_mincer_p' \ `irr_se_mincer_p' \ `irr_pval_mincer_p'], [. \ . \ .]]
matrix lincome         = [[`irr_mean_incgrowth7_f' \ `irr_se_incgrowth7_f' \ `irr_pval_incgrowth7_f'], [`irr_mean_incgrowth12_f' \ `irr_se_incgrowth12_f' \ `irr_pval_incgrowth12_f'],[`irr_mean_incgrowth7_m' \ `irr_se_incgrowth7_m' \ `irr_pval_incgrowth7_m'], [`irr_mean_incgrowth12_m' \ `irr_se_incgrowth12_m' \ `irr_pval_incgrowth12_m'], [`irr_mean_incgrowth7_p' \ `irr_se_incgrowth7_p' \ `irr_pval_incgrowth7_p'], [`irr_mean_incgrowth12_p' \ `irr_se_incgrowth12_p' \ `irr_pval_incgrowth12_p']] 
matrix crime           = [[`irr_mean_type2_nm_f' \ `irr_se_type2_nm_f' \ `irr_pval_type2_nm_f'], [`irr_mean_crimhalf_f' \ `irr_se_crimhalf_f' \ `irr_pval_crimhalf_f'], [`irr_mean_type2_nm_m' \ `irr_se_type2_nm_m' \ `irr_pval_type2_nm_m'], [`irr_mean_crimhalf_m' \ `irr_se_crimhalf_m' \ `irr_pval_crimhalf_m'], [`irr_mean_type2_nm_p' \ `irr_se_type2_nm_p' \  `irr_pval_type2_nm_p'], [`irr_mean_crimhalf_p' \ `irr_se_crimhalf_p' \ `irr_pval_crimhalf_p']]
matrix health          = [[`irr_mean_valife0_f' \ `irr_se_valife0_f' \ `irr_pval_valife0_f'], [`irr_mean_valife2_f' \ `irr_se_valife2_f' \ `irr_pval_valife2_f'], [`irr_mean_valife0_m' \ `irr_se_valife0_m' \ `irr_pval_valife0_m'], [`irr_mean_valife2_m' \ `irr_se_valife2_m' \ `irr_pval_valife2_m'], [`irr_mean_valife0_p' \ `irr_se_valife0_p' \ `irr_pval_valife0_p'], [`irr_mean_valife2_p' \ `irr_se_valife2_p' \ `irr_pval_valife2_p']]

matrix allirr = [baselineirr \ specification \ predictiontime \ counterfactual \ dwl \ parental \ lincome \ crime \ health]
matrix rownames allirr = baseline specification "." "." predictiontime "." "." counterfactual "." "." dwl "." "." parental "." "." lincome "." "." crime "." "." health "." "."
matrix colnames allirr = pooled pooled males males females females
matrix allirr = [allirr[1...,5..6],allirr[1...,1..4]]

cd $output
putexcel A1 = matrix(allbc)  using allbc_sens, replace
putexcel A1 = matrix(allirr) using allirr_sens, replace
