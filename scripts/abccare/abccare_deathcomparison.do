
set more off
clear all
set matsize 11000

/*
Project    :  ABC CBA

Description:  this .do file compares the age of the actual death and the projected death
			  among those who died
			  
Basics:       
		
This version: 08/04/2016

This .do file: Jessica Yu Kyung Koh
This project : CEHD
*/

// set environment variables
global erc: env erc
global projects: env projects
global klmshare: env klmshare

// abc-data
global data    = "$projects/abc-treatmenteffects-finalseason/data/abccare/extensions/fam-merge"
// output
global output  = "$projects/abc-treatmenteffects-finalseason/output/appendixplots"

// 
cd "$data"
use abc-fam-merge

// keep id R P male family $controls $ipwvars_all
replace id = 9999 if missing(id)


// limit the data to point estimates of those who actually died
* keep if adraw == 0
keep if (id == 920) | (id == 951) | (id == 117) | (id == 947) | (id == 943)
keep id R P Q adraw male hrabc_index died*
drop died_surv*


// id's file
aorder
gen num_id = _n

// Generate unique id
foreach var of varlist id adraw {
	tostring `var', gen(str_`var')
}
gen str_uniqueid = str_id + str_adraw
duplicates report str_uniqueid
duplicates report num_id 

drop str_uniqueid

// locals of death age for each individual who died after age 30
local deathid   920 951 117 947 943
local id920age	= 38 // heart attack
local id951age	= 37 // heart attack
local id117age	= 38 // unknown heart disease
local id947age	= 38 // breast cancer
local id943age	= 40 // unknown

// reshape
reshape long died, i(num_id) j(age)
generate age2 = age
replace age2 = . if died == .
bysort num_id: egen agedied = max(age2)
drop age2
reshape wide died, i(num_id) j(age)

// proejcted died age
generate projectdied = .
foreach id in `deathid' {
	replace projectdied = `id`id'age' if id == `id'
}


cd "$output"

# delimit
graph bar (mean) agedied projectdied, over(id)
	   
bar(1, color(gs4)) bar(2, color(gs10))	   
	   
legend(	label(1 Projected Death) size(small) 
		label(2 Actual Death) 
		)
	ytitle("Age of Death") b1title("ID Number")
	 graphregion(color(white)) plotregion(fcolor(white));
# delimit cr 
graph export deathcomparison.eps, replace

* Need to add standard error bars
