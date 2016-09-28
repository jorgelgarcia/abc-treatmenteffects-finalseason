version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC CVA
Description:    Test of endogeneity of prediction function, labor income, CNLSY
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

// open and save measures of cognition and IQ in CNLSY
cd $datacnlsyp
use cnlsy-base.dta, clear

global cog  piatrrec1986 piatrcom1986 ppvt1986
global ncog bpi_scaleasoc1988 bpi_scaleanx1988 bpi_scalehstrong1988 bpi_scalehyp1988 bpi_scaledep1988 bpi_scalewithd1988
keep id $cog $ncog

tempfile cnlsyskills
save   "`cnlsyskills'", replace

cd $datacnlsyw
use cnlsy-abc-match.dta, clear
merge 1:1 id using "`cnlsyskills'"

matrix allests = J(10,1,.)
matrix rownames allests = m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi cogfactor noncogfactor cons R2 N 
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
	reg si30y_inc_labor m_ed0y cogfactor noncogfactor, robust
	matrix t1f = e(b)
	matrix t1fcomplete`b' = [t1f[1,1],J(1,4,.),t1f[1,2..4],e(r2),e(N)]'
	matrix rownames t1fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi cogfactor noncogfactor cons R2 N
	matrix colnames t1fcomplete`b' = t1fcomplete`b'
	mat_capp allests : allests t1fcomplete`b'

	
	reg si30y_inc_labor m_ed0y piatmath years_30y si21y_inc_labor cogfactor noncogfactor, robust
	matrix t2f = e(b)
	matrix t2fcomplete`b' = [t2f[1,1..4],J(1,1,.),t2f[1,2..4],e(r2),e(N)]'
	matrix rownames t2fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi cogfactor noncogfactor cons R2 N 
	matrix colnames t2fcomplete`b' = t2fcomplete`b'
	mat_capp allests : allests t2fcomplete`b'
	

	reg si30y_inc_labor m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi cogfactor noncogfactor, robust
	matrix t3f = e(b)
	matrix t3fcomplete`b' = [t3f[1,1..8],e(r2),e(N)]'
	matrix rownames t3fcomplete`b' = m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi cogfactor noncogfactor cons R2 N 
	matrix colnames t3fcomplete`b' = t3fcomplete`b'
	mat_capp allests : allests t3fcomplete`b'

	
	// treatment regressions with no factor
	reg si30y_inc_labor m_ed0y, robust
	matrix t1 = e(b)
	matrix t1complete`b' = [t1[1,1],J(1,6,.),t1[1,2],e(r2),e(N)]'
	matrix rownames t1complete`b' = m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi cogfactor noncogfactor cons R2 N 
	matrix colnames t1complete`b' = t1complete`b'
	mat_capp allests : allests t1complete`b'
	
	reg si30y_inc_labor m_ed0y piatmath years_30y si21y_inc_labor, robust
	matrix t2 = e(b)
	matrix t2complete`b' = [t2[1,1..4],J(1,3,.),t2[1,2],e(r2),e(N)]'
	matrix rownames t2complete`b' = m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi cogfactor noncogfactor cons R2 N 
	matrix colnames t2complete`b' = t2complete`b'
	mat_capp allests : allests t2complete`b'

	reg si30y_inc_labor m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi, robust
	matrix t3 = e(b)
	matrix t3complete`b' = [t3[1,1..5],J(1,2,.),t3[1,6],e(r2),e(N)]'
	matrix rownames t3complete`b' = m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi cogfactor noncogfactor cons R2 N 
	matrix colnames t3complete`b' = t3complete`b'
	mat_capp allests : allests t3complete`b'
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

mkmat *, matrix(allcoeffs)

cd $output
outtable using cnlsy_endog, mat(allcoeffs) replace nobox center f(%9.3f)
