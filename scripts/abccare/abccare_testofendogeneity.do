version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC CVA
Description:    Test of endogeneity of prediction function, labor income, ABC and CARE samples control only
*This version:  April 18, 2016
*This .do file: Jorge L. Garcia
*This project : CBA Team
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
global datacnlsyp   = "$klmshare/Data_Central/data-repos/nlsy/primary/cnlsy/base/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global dataabcres   = "$klmmexico/abccare/income_projections"
global dataweights  = "$klmmexico/abccare/as_weights/"
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

global cog    iq2y iq3y iq4y iq5y iq7y iq8y
global ncog   bsi_tsom bsi_thos bsi_tdep bsi_tgsi

global treat   if D == 1
global cont if D == 0
global pool 

foreach treat in treat cont pool {
	foreach varyy of varlist si30y_inc_labor si30y_inc_trans_pub si34y_bmi {
		matrix allests`varyy' = J(12,1,.)
		matrix rownames allests`varyy' = m_ed0y piatmath years_30y si21y_inc_labor cogfactor noncogfactor cons F R2 N FF pFF
		foreach b of numlist 1(1)$bootstraps {
			preserve
			bsample

			// construct factors
			// cognitive
			factor  $cog
			predict cogfactor

			// non-cognitive
			factor $ncog
			predict noncogfactor
			
			// treatment regressions with factor
			reg `varyy' m_ed0y cogfactor noncogfactor ${`treat'}, robust
			matrix t1f = e(b)
			matrix   F = e(F)
			matrix  r2 = e(r2)
			matrix   N = e(N)
			test (cogfactor = 0) (noncogfactor = 0)
			matrix  DW = r(F)
			matrix pDW = r(p)
			matrix t1fcomplete`b' = [t1f[1,1..1],J(1,3,.),t1f[1,2...],F[1,1],r2[1,1],N[1,1],DW[1,1],pDW[1,1]]'
			matrix rownames t1fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_labor cogfactor noncogfactor cons F R2 N FF pFF
			matrix colnames t1fcomplete`b' = t1fcomplete`b'
			mat_capp allests`varyy' : allests`varyy' t1fcomplete`b'

			
			reg `varyy' m_ed0y piatmath years_30y si21y_inc_labor cogfactor noncogfactor ${`treat'}, robust
			matrix t2f = e(b)
			matrix   F = e(F)
			matrix  r2 = e(r2)
			matrix   N = e(N)
			test (cogfactor = 0) (noncogfactor = 0)
			matrix  DW = r(F)
			
			matrix t2fcomplete`b' = [t2f[1,1...],e(F),e(r2),e(N),DW[1,1],pDW[1,1]]'
			
			matrix rownames t2fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_labor cogfactor noncogfactor cons F R2 N FF pFF
			matrix colnames t2fcomplete`b' = t2fcomplete`b'
			mat_capp allests`varyy' : allests`varyy' t2fcomplete`b'

			
			// treatment regressions with no factor
			reg `varyy' m_ed0y ${`treat'}, robust
			matrix t1 = e(b)
			matrix t1complete`b' = [t1[1,1..1],J(1,5,.),t1[1,2],e(F),e(r2),e(N),.,.]'
			matrix rownames t1complete`b' = m_ed0y piatmath years_30y si21y_inc_labor cogfactor noncogfactor cons F R2 N FF pFF
			matrix colnames t1complete`b' = t1complete`b'
			mat_capp allests`varyy' : allests`varyy' t1complete`b'
			
			reg `varyy' m_ed0y piatmath years_30y si21y_inc_labor ${`treat'}, robust
			matrix t2 = e(b)
			matrix t2complete`b' = [t2[1,1..4],J(1,2,.),t2[1,5],e(F),e(r2),e(N),.,.]'
			matrix rownames t2complete`b' = m_ed0y piatmath years_30y si21y_inc_labor cogfactor noncogfactor cons F R2 N FF pFF
			matrix colnames t2complete`b' = t2complete`b'
			mat_capp allests`varyy' : allests`varyy' t2complete`b'
			restore
		}
		matrix allests`varyy' = allests`varyy'[1...,2...]

		preserve
		clear
		svmat allests`varyy', names(col)

		# delimit
		global estimates 1complete 1fcomplete 2complete 2fcomplete;
		# delimit cr
		aorder

		foreach var in $estimates {	

			foreach vary in t {
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
			foreach vary in t {
			replace `vary'`var'pvalue = `vary'`var'pvalue/2 if `vary'`var'mean > 0
			replace `vary'`var'pvalue = (1 - `vary'`var'pvalue/2) if `vary'`var'mean < 0
			}
		}	

		// arrange to output to a matrix
		# delimit
		order t1completemean t1completepvalue t1fcompletemean t1fcompletepvalue
		      t2completemean t2completepvalue t2fcompletemean t2fcompletepvalue;
		# delimit cr

		mkmat *, matrix(all`varyy'_s`treat')
		
		matrix all`varyy'_s`treat'p1 = all`varyy'_s`treat'[1..7,1...]
		matrix all`varyy'_s`treat'p2 = [[all`varyy'_s`treat'[8..9,1] \ round(all`varyy'_s`treat'[10,1],1) \ [all`varyy'_s`treat'[11..12,1]]], J(5,1,.),[all`varyy'_s`treat'[8..9,3] \ round(all`varyy'_s`treat'[10,3],1) \ [all`varyy'_s`treat'[11..12,3]]], J(5,1,.),[all`varyy'_s`treat'[8..9,5] \ round(all`varyy'_s`treat'[10,1],5) \ [all`varyy'_s`treat'[11..12,5]]], J(5,1,.),[all`varyy'_s`treat'[8..9,7] \ round(all`varyy'_s`treat'[10,1],7) \ [all`varyy'_s`treat'[11..12,7]]], J(5,1,.)]
		
		matrix all`varyy'_s`treat' = [all`varyy'_s`treat'p1 \ all`varyy'_s`treat'p2]		
		matrix rownames all`varyy'_s`treat' = "Mother'sEducation" "PIAT(5-7)" "Education(30)" "LaborIncome(21)" Cognitive NonCognitive Constant "F-stat" "R2" Observations "DWH" "pDWH"

		cd $output
		outtable using abccare_endogdurb_`varyy'_s`treat', mat(all`varyy'_s`treat') replace nobox center f(%12.2fc)
		restore 
	}
}
