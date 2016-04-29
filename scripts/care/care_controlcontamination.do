global erc: env  erc
global projects: env projects
global klmshare: env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// set general locations
// data
global data = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
// do files
global scripts    = "$projects/abc-care-treatmenteffects/Scripts/"
// ready data
global datapsid   = "$klmshare/Data_Central/data-repos/psid/base/"
// output
global output     = "$projects/abc-care-treatmenteffects/output"
* global output  = "${projects}/abc-care-treatmenteffects/output/care/description"

cd $data
use append-abccare_iv.dta, clear
drop aux*
preserve
keep if abc == 0

foreach y in 1 2 3 4 5{
gen T_pre`y'=.
replace T_pre`y'=dc_mo_pre`y' if random==2
gen C_pre`y'=.
replace C_pre`y'=dc_mo_pre`y' if random==0
gen V_pre`y'=.
replace V_pre`y'=dc_mo_pre`y' if random==3
}

label define random 0 "Control"  2 "Center+Fam. Educ" 3 "Fam. Educ" 
label values random random

gen Tcol_pre=.
gen Ccol_pre=.
gen Vcol_pre=.

expand=2, gen (aux1)
expand=2 if aux1==0, gen(aux2)
expand=2 if aux1==0 & aux2==0, gen(aux3)
expand=2 if aux1==0 & aux2==0 & aux3==0, gen(aux4)

gen Age=""
replace Age="Age 1" 	if aux1==1
replace Age="Age 2" 	if aux2==1
replace Age="Age 3" 	if aux3==1
replace Age="Age 4" 	if aux4==1
replace Age="Age 5" 	if Age==""

*Variables: subs_1 subs_2 ... each containing number of months

foreach y in 1 2 3 4 5{
replace Tcol_pre		=T_pre`y'  	if Age=="Age `y'"
replace Ccol_pre		=C_pre`y'  	if Age=="Age `y'"
replace Vcol_pre		=V_pre`y'  	if Age=="Age `y'"
}

*col_none col_subsidized col_other
/*
#delimit
graph bar Ccol_pre  Vcol_pre Tcol_pre     if program==0, 
	over(random, label(nolabels) gap(*0.1) )
	over(Age, label(labsize(small)) gap(*0.4) )
	stack bar(1,color(black)) bar(2,color(gs6)) bar(3,color(gs12))
		legend( order(1 "Control"  3 "Center and Family Education" 2 "Family Education")
		size(small) cols(3) rowgap(*.5) keygap(*.5) symysize(*.5) symxsize(*.5))
		ylabel(0(2)12,   angle(h) glcolor(gs14))  ytitle(Months in Alternative Centers)
		graphregion(color(white)) 
		plotregion(fcolor(white));
#delimit cr
graph export "${output}/CC_CARE.eps", as(eps) replace
restore
*/
*------------------------------------------------------------------------------*

*--------------------------------*
* Chart: Preschool Participation *
*--------------------------------*
gen col_none=.
gen col_subsidized=.
gen col_other=.


*Variables: subs_1 subs_2 ... each containing number of months

foreach y in 1 2 3 4 5{
replace col_none		=dc_none`y'  	if Age=="Age `y'"
replace col_subsidized	=dc_subs`y'		if Age=="Age `y'"
replace col_other		=dc_other`y'	if Age=="Age `y'"
}

#delimit
graph bar col_none col_subsidized col_other if random == 3 | random == 0, 
		over(Age, label(labsize(small)) gap(*0.2) )
		stack bar(1,color(gs)) bar(2,color(gs6)) bar(3,color(gs12))
		legend( label(1 "No Preschool Alternative") label(2 "Subsidized") label(3 "Non-Subsidized")
		size(small) cols(3) rowgap(*.5) keygap(*.5) symysize(*.5) symxsize(*.5))
		ylabel(0(2)12, angle(h) glcolor(gs14)) 
		graphregion(color(white)) 
		plotregion(fcolor(white));
#delimit cr

graph export "${output}/care/controlcontamination/blackwhite_CCnumber_care.eps", as(eps) replace

* Check if the plot looks right
foreach y in 1 2 3 4 5 {
		summ dc_none`y'
		summ dc_subs`y'
		summ dc_other`y'
}

restore


