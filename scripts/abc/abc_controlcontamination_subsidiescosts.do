version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC CBA
Description:    this .do file plots control contamination intensity by subsidiy status, ABC sample
*This version:  December 29, 2015
*This .do file: Jorge L. Garcia
*This project : ABC CBA 
*/

// set environment variables (server)
global erc: env erc
global projects: env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// set general locations
// do files
global scripts    = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datapsid    = "$klmshare/Data_Central/data-repos/psid/base/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

// open merged data
cd $dataabccare
use append-abccare_iv.dta, clear

cd $output

*--------------------------------*
* Chart: Preschool Participation *
*--------------------------------*
preserve
gen col_none=.
gen col_subsidized=.
gen col_other=.

drop aux*
expand=2, gen (aux1)
expand=2 if aux1==0, gen(aux2)
expand=2 if aux1==0&aux2==0, gen(aux3)
expand=2 if aux1==0&aux2==0&aux3==0, gen(aux4)

gen Age=""
replace Age="Age 1" 	if aux1==1
replace Age="Age 2" 	if aux2==1
replace Age="Age 3" 	if aux3==1
replace Age="Age 4" 	if aux4==1
replace Age="Age 5" 	if Age==""

*Variables: subs_1 subs_2 ... each containing number of months

foreach y in 1 2 3 4 5{
replace col_none		=dc_none`y'  	if Age=="Age `y'"
replace col_subsidized	=dc_subs`y'		if Age=="Age `y'"
replace col_other		=dc_other`y'	if Age=="Age `y'"
}

#delimit
graph bar col_none col_subsidized col_other if id>=900&id<=955 & abc == 1, 
		over(Age, label(labsize(small)) gap(*0.2) )
		stack bar(1,color(gs)) bar(2,color(gs6)) bar(3,color(gs12))
		legend( label(1 "No Preschool Alternative") label(2 "Subsidized") label(3 "Non-Subsidized")
		size(small) cols(3) rowgap(*.5) keygap(*.5) symysize(*.5) symxsize(*.5))
		ylabel(0(2)12, angle(h) glcolor(gs14)) 
		graphregion(color(white)) 
		plotregion(fcolor(white));
#delimit cr

graph export "blackwhite_CCnumber.eps", as(eps) replace
restore
