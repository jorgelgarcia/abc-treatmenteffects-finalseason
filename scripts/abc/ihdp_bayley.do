version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC treatment effects
Description:    this .do file prepares treatment effects on the Bayley MDI
*This version:  April 18, 2015
*This .do file: Jorge L. Garcia
*This project : Seong Moon has the ingredients for success
*/

// set environment variables
global erc: env erc
global projects: env projects
global klmshare: env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive
global resources: env resources

// set general locations
// do files
global scripts    = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datapsid    = "$klmshare/Data_Central/data-repos/psid/base/"
global dataihdp    = "$klmmexico/TimeWithMom/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"


cd $dataihdp
use ihdp-analysis.dta, clear

// make groups of cluster (state + llbw) 
egen z = group(state llbw)

// bayley mdi 1 
reg bayley_mdi1 treat, vce(cluster z)
est sto bmdi1

// bayley mdi 2
reg bayley_mdi2 treat, vce(cluster z)
est sto bmdi2

cd $output
# delimit
	outreg2 [bmdi1  bmdi2]
			using ihdp_bayley, replace                                  
			tex alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 nocons label noni nonotes ;
# delimit cr
