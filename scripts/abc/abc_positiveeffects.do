version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC
Description:    this .do file makes the plots for combining functions, ABC sample only.
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
global dataresults = "$klmshare/JShea/forJLG/rslt-apr21"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// cd into abc itt results
cd $dataresults

insheet using outcomes_abc.csv, clear
keep variable hyp
rename variable rowname
sort rowname
tempfile revsheet
save "`revsheet'", replace

// abc
cd abc_ate/rslt_itt/
foreach var in male female pooled {
	insheet using itt_`var'.csv, clear
	keep if ddraw == 0 & draw == 0
	duplicates drop rowname, force
	keep rowname itt_noctrl
	sort rowname
	merge 1:1 rowname using "`revsheet'" 
	drop if _merge != 3
	replace itt_noctrl = - itt_noctrl if hyp == "-"
	gen itt_pos = 0
	replace itt_pos = 1 if itt_noctrl > 0 & itt_noctrl !=.
	summ itt_pos
	local itt_`var' = r(mean)
}
matrix abc = [1,`itt_female',`itt_male',`itt_pooled']
matrix colnames abc = program female male pooled

// care
cd $dataresults
cd care_ate/rslt_itt/
foreach var in male female pooled {
	insheet using itt_`var'.csv, clear
	keep if ddraw == 0 & draw == 0
	duplicates drop rowname, force
	keep rowname itt_noctrl
	sort rowname
	merge 1:1 rowname using "`revsheet'" 
	drop if _merge != 3
	replace itt_noctrl = - itt_noctrl if hyp == "-"
	gen itt_pos = 0
	replace itt_pos = 1 if itt_noctrl > 0 & itt_noctrl !=.
	summ itt_pos
	local itt_`var' = r(mean)
}
matrix care = [2,`itt_female',`itt_male',`itt_pooled']
matrix colnames care = program female male pooled

// abc + care
cd $dataresults
cd abccare_ate/rslt_itt/
foreach var in male female pooled {
	insheet using itt_`var'.csv, clear
	keep if ddraw == 0 & draw == 0
	duplicates drop rowname, force
	keep rowname itt_noctrl
	sort rowname
	merge 1:1 rowname using "`revsheet'" 
	drop if _merge != 3
	replace itt_noctrl = - itt_noctrl if hyp == "-"
	gen itt_pos = 0
	replace itt_pos = 1 if itt_noctrl > 0 & itt_noctrl !=.
	summ itt_pos
	local itt_`var' = r(mean)
}
matrix abccare = [3,`itt_female',`itt_male',`itt_pooled']
matrix colnames abccare = program female male pooled

// care family education
cd $dataresults
cd care_family/rslt_itt/
foreach var in male female pooled {
	insheet using itt_`var'.csv, clear
	keep if ddraw == 0 & draw == 0
	duplicates drop rowname, force
	keep rowname itt_noctrl
	sort rowname
	merge 1:1 rowname using "`revsheet'" 
	drop if _merge != 3
	replace itt_noctrl = - itt_noctrl if hyp == "-"
	gen itt_pos = 0
	replace itt_pos = 1 if itt_noctrl > 0 & itt_noctrl !=.
	summ itt_pos
	local itt_`var' = r(mean)
}

matrix care_family = [4,`itt_female',`itt_male',`itt_pooled']
matrix colnames care_family = program female male pooled

// abc school age
cd $dataresults
cd abcsa_ate/rslt_itt/
foreach var in male female pooled {
	insheet using itt_`var'.csv, clear
	keep if ddraw == 0 & draw == 0
	duplicates drop rowname, force
	keep rowname itt_noctrl
	sort rowname
	merge 1:1 rowname using "`revsheet'" 
	drop if _merge != 3
	replace itt_noctrl = - itt_noctrl if hyp == "-"
	gen itt_pos = 0
	replace itt_pos = 1 if itt_noctrl > 0 & itt_noctrl !=.
	summ itt_pos
	local itt_`var' = r(mean)
}

matrix abcsa = [5,`itt_female',`itt_male',`itt_pooled']
matrix colnames abcsa = program female male pooled

// all results
matrix all = J(1,4,.)
matrix colnames all = program female male pooled
foreach p in abc care abccare care_family abcsa {
	mat_rapp all : all `p'
}

matrix all = all[2...,1...]
matrix all = [[all[1...,1..2]] \ [all[1...,1],all[1...,3]] \ [all[1...,1],all[1...,4]]]
mat colnames all = program ppositive


// plot
preserve
clear
svmat all, names(col)
gen count = _n
gen     sex = 0 if count <= 5
replace sex = 1 if count > 5 & count <= 10
replace sex = 2 if count > 10
drop count

drop if sex == 2
replace program = program*2 - 1
replace ppositive = ppositive*100

label define programlabel 1 "ABC" 3 "CARE" 5 "ABC and CARE" 7 "Family Education, CARE" 9 "School-age, ABC", replace
la values program programlabel

#delimit
graph bar ppositive if program <= 5, over(sex) bar(1, color(gs12)) bar(2, lcolor(black) lwidth(medium) fcolor(black)) bar(3, color(gs4)) 
			asyvar bargap(0) over(program)
		        ytitle("% Outcomes with Positive Treatment-Control Mean Difference", size(small)) ylabel(0[15]90, angle(h) glcolor(gs14))
			legend(label(1 Females) label(2 Males) size(medsmall) cols(2))
			graphregion(color(white)) plotregion(fcolor(white));
# delimit cr
cd $output
graph export abccare_positiveeffects.eps, replace

#delimit
graph bar ppositive if program > 5, over(sex) bar(1, color(gs12)) bar(2, lcolor(black) lwidth(medium) fcolor(black))
			asyvar bargap(0) over(program)
		        ytitle("% Outcomes with Positive Treatment-Control Mean Difference", size(small)) ylabel(0[15]90, angle(h) glcolor(gs14))
			legend(label(1 Females) label(2 Males) size(medsmall) cols(2))
			graphregion(color(white)) plotregion(fcolor(white));
# delimit cr
graph export abccare_othertreatments.eps, replace
restore
