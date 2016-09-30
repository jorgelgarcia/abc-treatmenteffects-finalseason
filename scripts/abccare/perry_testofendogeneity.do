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
global dataperry   = "$klmshare/Data_Central/data-repos/perry/base/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// bootstraps 
global bootstraps 100
set seed 0

// Perry
cd $dataperry
use perry-base.dta, clear

global cognitive          sb7 sb8 sb9
global externalizing      yrs_emo6 yrs_emo7 yrs_emo8 yrs_emo9   yrs_soc6 yrs_soc7 yrs_soc8 yrs_soc9 pbi_cond6 pbi_cond7 pbi_cond8 pbi_cond9 pbi_emo6 pbi_emo7 pbi_emo8 pbi_emo9
global academicmotivation pbi_acad6 pbi_acad7 pbi_acad8 pbi_acad9 yrs_acad6 yrs_acad7 yrs_acad8 yrs_acad9 yrs_vrb6 yrs_vrb7 yrs_vrb8 yrs_vrb9


foreach varyy of varlist inc40 hs40 idle40 {
matrix allests`varyy' = J(13,1,.)

matrix rownames allests`varyy' = treatment m_ed_base childIQ years30 inc27 healthy40 cognitive externalizing academicmotivation cons F R2 N
	foreach b of numlist 1(1)$bootstraps {
		preserve
		bsample

		// construct factor
		factor  $cognitive
		predict cogfactor

		// externalizing factor
		factor $externalizing
		predict extfactor
		
		// academic motivation factor
		factor $academicmotivation
		predict academicfactor
		
		// treatment regressions with factor
		reg `varyy' treatment m_ed_base cogfactor extfactor academicfactor, robust
		matrix t1f = e(b)
		matrix t1fcomplete`b' = [t1f[1,1..2],J(1,4,.),t1f[1,3...],e(F),e(r2),e(N)]'
		matrix rownames t1fcomplete`b' = treatment m_ed_base childIQ years30 inc27 healthy40 cognitive externalizing academicmotivation cons F R2 N
		matrix colnames t1fcomplete`b' = t1fcomplete`b'
		mat_capp allests`varyy' : allests`varyy' t1fcomplete`b'

		
		reg `varyy' treatment m_ed_base childIQ years30 inc27 cogfactor extfactor academicfactor, robust
		matrix t2f = e(b)
		matrix t2fcomplete`b' = [t2f[1,1..5],J(1,1,.),t2f[1,6...],e(F),e(r2),e(N)]'
		matrix rownames t2fcomplete`b' = treatment m_ed_base childIQ years30 inc27 healthy40 cognitive externalizing academicmotivation cons F R2 N
		matrix colnames t2fcomplete`b' = t2fcomplete`b'
		mat_capp allests`varyy' : allests`varyy' t2fcomplete`b'
		

		reg `varyy' treatment m_ed_base childIQ years30 inc27 healthy40 cogfactor extfactor academicfactor, robust
		matrix t3f = e(b)
		matrix t3fcomplete`b' = [t3f[1,1...],e(F),e(r2),e(N)]'
		matrix rownames t3fcomplete`b' = treatment m_ed_base childIQ years30 inc27 healthy40 cognitive externalizing academicmotivation cons F R2 N
		matrix colnames t3fcomplete`b' = t3fcomplete`b'
		mat_capp allests`varyy' : allests`varyy' t3fcomplete`b'

		
		// treatment regressions with no factor
		reg `varyy' treatment m_ed_base, robust
		matrix t1 = e(b)
		matrix t1complete`b' = [t1[1,1..2],J(1,7,.),t1[1,3],e(F),e(r2),e(N)]'
		matrix rownames t1complete`b' = treatment m_ed_base childIQ years30 inc27 healthy40 cognitive externalizing academicmotivation cons F R2 N
		matrix colnames t1complete`b' = t1complete`b'
		mat_capp allests`varyy' : allests`varyy' t1complete`b'
		
		reg `varyy' treatment m_ed_base childIQ years30 inc27, robust
		matrix t2 = e(b)
		matrix t2complete`b' = [t2[1,1..5],J(1,4,.),t2[1,6],e(F),e(r2),e(N)]'
		matrix rownames t2complete`b' = treatment m_ed_base childIQ years30 inc27 healthy40 cognitive externalizing academicmotivation cons F R2 N
		matrix colnames t2complete`b' = t2complete`b'
		mat_capp allests`varyy' : allests`varyy' t2complete`b'

		reg `varyy' treatment m_ed_base childIQ years30 inc27 healthy40, robust
		matrix t3 = e(b)
		matrix t3complete`b' = [t3[1,1..6],J(1,3,.),t3[1,7],e(F),e(r2),e(N)]'
		matrix rownames t3complete`b' = treatment m_ed_base childIQ years30 inc27 healthy40 cognitive externalizing academicmotivation cons F R2 N
		matrix colnames t3complete`b' = t3complete`b'
		mat_capp allests`varyy' : allests`varyy' t3complete`b'
		restore
	}
	matrix allests`varyy' = allests`varyy'[1...,2...]

	preserve
	clear
	svmat allests`varyy', names(col)

	# delimit
	global estimates 1complete 1fcomplete 2complete 2fcomplete 3complete 3fcomplete;
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
	      t2completemean t2completepvalue t2fcompletemean t2fcompletepvalue
	      t3completemean t3completepvalue t3fcompletemean t3fcompletepvalue;
	# delimit cr

	mkmat *, matrix(all`varyy')

	cd $output
	outtable using perry_endog_`varyy', mat(all`varyy') replace nobox center f(%9.3f)
	restore 
}
