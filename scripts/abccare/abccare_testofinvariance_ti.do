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
global datapsid     = "$klmshare/Data_Central/data-repos/psid/base/"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global datanlsyw    = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/"
global datacnlsyw   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global dataabcres   = "$klmmexico/abccare/income_projections"
global dataweights  = "$klmmexico/abccare/as_weights/"
global nlsyother    = "$klmmexico/BPSeason2"
global collapseprj  = "$klmmexico/abccare/income_projections/"

// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// bootstraps 
global bootstraps 100
set seed 0

// ABC
cd $dataabccare
use append-abccare_iv.dta, clear
drop if random == 3

egen piatabc  = rowmean(piat5y6m piat6y piat6y6m piat7y)   if program == "abc"
egen piatcare = rowmean(wj_math5y6m wj_math6y wj_math7y6m) if program == "care"
gen     piatmath = piatabc  if program == "abc"
replace piatmath = piatcare if program == "care" 

matrix allests = J(8,1,.)
matrix rownames allests = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
foreach b of numlist 1(1)$bootstraps {
	preserve
	bsample

	// construct ipw
	reg si30y_inc_trans_pub m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi
	gen respall = e(sample)
	reg respall years_30y prem_birth drug_pct
	predict resppred, xb
	gen ipw = 1/resppred

	// construct factors
	// cognitive
	factor  iq2y iq3y iq4y iq5y iq7y iq8y
	predict cogfactor

	// non-cognitive
	factor bsi_tsom bsi_thos bsi_tdep bsi_tgsi
	predict noncogfactor
	
	// treatment regressions with factor
	reg si30y_inc_trans_pub m_ed0y cogfactor noncogfactor [aw=ipw] if R == 1, robust
	matrix t1f = e(b)
	matrix t1fcomplete`b' = [t1f[1,1],J(1,4,.),t1f[1,2..4]]'
	matrix rownames t1fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames t1fcomplete`b' = t1fcomplete`b'
	mat_capp allests : allests t1fcomplete`b'

	
	reg si30y_inc_trans_pub m_ed0y piatmath years_30y si21y_inc_trans_pub cogfactor noncogfactor [aw=ipw] if R == 1, robust
	matrix t2f = e(b)
	matrix t2fcomplete`b' = [t2f[1,1..4],J(1,1,.),t2f[1,2..4]]'
	matrix rownames t2fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames t2fcomplete`b' = t2fcomplete`b'
	mat_capp allests : allests t2fcomplete`b'
	

	reg si30y_inc_trans_pub m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor [aw=ipw] if R == 1, robust
	matrix t3f = e(b)
	matrix t3fcomplete`b' = t3f[1,1..8]'
	matrix rownames t3fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames t3fcomplete`b' = t3fcomplete`b'
	mat_capp allests : allests t3fcomplete`b'

	
	// treatment regressions with no factor
	reg si30y_inc_trans_pub m_ed0y [aw=ipw] if R == 1, robust
	matrix t1 = e(b)
	matrix t1complete`b' = [t1[1,1],J(1,6,.),t1[1,2]]'
	matrix rownames t1complete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames t1complete`b' = t1complete`b'
	mat_capp allests : allests t1complete`b'
	
	reg si30y_inc_trans_pub m_ed0y piatmath years_30y si21y_inc_trans_pub [aw=ipw] if R == 1, robust
	matrix t2 = e(b)
	matrix t2complete`b' = [t2[1,1..4],J(1,3,.),t2[1,2]]'
	matrix rownames t2complete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames t2complete`b' = t2complete`b'
	mat_capp allests : allests t2complete`b'

	reg si30y_inc_trans_pub m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi [aw=ipw] if R == 1, robust
	matrix t3 = e(b)
	matrix t3complete`b' = [t3[1,1..5],J(1,2,.),t3[1,6]]'
	matrix rownames t3complete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames t3complete`b' = t3complete`b'
	mat_capp allests : allests t3complete`b'
	
	// control regressions with factor
	reg si30y_inc_trans_pub m_ed0y cogfactor noncogfactor [aw=ipw] if R == 0, robust
	matrix c1f = e(b)
	matrix c1fcomplete`b' = [c1f[1,1],J(1,4,.),c1f[1,2..4]]'
	matrix rownames c1fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames c1fcomplete`b' = c1fcomplete`b'
	mat_capp allests : allests c1fcomplete`b'
	
	reg si30y_inc_trans_pub m_ed0y piatmath years_30y si21y_inc_trans_pub cogfactor noncogfactor [aw=ipw] if R == 0, robust
	matrix c2f = e(b)
	matrix c2fcomplete`b' = [c2f[1,1..4],J(1,1,.),c2f[1,2..4]]'
	matrix rownames c2fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames c2fcomplete`b' = c2fcomplete`b'
	mat_capp allests : allests c2fcomplete`b'

	reg si30y_inc_trans_pub m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor [aw=ipw] if R == 0, robust
	matrix c3f = e(b)
	matrix c3fcomplete`b' = c3f[1,1..8]'
	matrix rownames c3fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames c3fcomplete`b' = c3fcomplete`b'
	mat_capp allests : allests c3fcomplete`b'
	
	// control regressions with no factor
	reg si30y_inc_trans_pub m_ed0y [aw=ipw] if R == 0, robust
	matrix c1 = e(b)
	matrix c1complete`b' = [c1[1,1],J(1,6,.),c1[1,2]]'
	matrix rownames c1complete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames c1complete`b' = c1complete`b'
	mat_capp allests : allests c1complete`b'
	
	reg si30y_inc_trans_pub m_ed0y piatmath years_30y si21y_inc_trans_pub [aw=ipw] if R == 0, robust
	matrix c2 = e(b)
	matrix c2complete`b' = [c2[1,1..4],J(1,3,.),c2[1,2]]'
	matrix rownames c2complete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames c2complete`b' = c2complete`b'
	mat_capp allests : allests c2complete`b'

	reg si30y_inc_trans_pub m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi [aw=ipw] if R == 0, robust
	matrix c3 = e(b)
	matrix c3complete`b' = [c3[1,1..5],J(1,2,.),c3[1,6]]'
	matrix rownames c3complete`b' = m_ed0y piatmath years_30y si21y_inc_trans_pub si34y_bmi cogfactor noncogfactor cons
	matrix colnames c3complete`b' = c3complete`b'
	mat_capp allests : allests c3complete`b'
	
	restore
}
matrix allests = allests[1...,2...]

clear
svmat allests, names(col)

# delimit
global estimates 1complete 1fcomplete 2complete 2fcomplete 3complete 3fcomplete;
# delimit cr
aorder

foreach var in $estimates {	
	foreach num of numlist 1(1)$bootstraps {
		gen tc`var'`num' = t`var'`num' - c`var'`num'
	}

	foreach vary in c t tc {
		egen `vary'`var'mean = rowmean(`vary'`var'1-`vary'`var'${bootstraps})
	
		// demean distribution
		foreach num of numlist 1(1)$bootstraps {
			replace `vary'`var'`num' = `vary'`var'`num' - `vary'`var'mean
			gen     `vary'`var'ind`num' = 0 
			replace `vary'`var'ind`num' = 1 if abs(`vary'`var'`num') >= abs(`vary'`var'mean)
		}
		
		// generate p-value
		egen    `vary'`var'pvalue  = rowmean(`vary'`var'ind`num'1-`vary'`var'ind`num'${bootstraps})
		replace `vary'`var'pvalue  = . if `vary'`var'mean == .
	}
}
aorder
keep *mean *pvalue

// adjust to one sided p-value
foreach var in $estimates {
	foreach vary in c t tc {
	replace `vary'`var'pvalue = `vary'`var'pvalue/2 if `vary'`var'mean > 0
	replace `vary'`var'pvalue = (1 - `vary'`var'pvalue/2) if `vary'`var'mean < 0
	}
}	

// arrange to output to a matrix
# delimit
order c1completemean c1completepvalue t1completemean t1completepvalue tc1completemean tc1completepvalue
      c1fcompletemean c1fcompletepvalue t1fcompletemean t1fcompletepvalue tc1fcompletemean tc1fcompletepvalue
      c2completemean c2completepvalue t2completemean t2completepvalue tc2completemean tc2completepvalue
      c2fcompletemean c2fcompletepvalue t2fcompletemean t2fcompletepvalue tc2fcompletemean tc2fcompletepvalue
      c3completemean c3completepvalue t3completemean t3completepvalue tc3completemean tc3completepvalue
      c3fcompletemean c3fcompletepvalue t3fcompletemean t3fcompletepvalue tc3fcompletemean tc3fcompletepvalue;
# delimit cr

mkmat *, matrix(allcoeffs)

matrix allcoefsc1 = allcoeffs[1...,1..12]
matrix allcoefsc2 = allcoeffs[1...,13..24]
matrix allcoefsc3 = allcoeffs[1...,25...]

cd $output
foreach num of numlist 1(1)3 {
	outtable using abccare_funcform`num'_ti, mat(allcoefsc`num') replace nobox center f(%9.3f)
}
