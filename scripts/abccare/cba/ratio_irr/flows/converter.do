capture program drop converter
program define converter
version 12
syntax, csvin(string) csvout(string) ename(string) prefix(string)

insheet using "`csvin'.csv", names clear	
capture confirm string variable `ename'
if !_rc {
	capture confirm variable `ename'_p 
	if !_rc {
		replace `ename' = "NA" if `ename'_p == "NaN" & `ename' == "0.0"
	}
}

if "`prefix'" == "ip_p_inc"{
	replace rowname = "ip_p_inc1" if rowname == "ip_p_inc1y6m"
	replace rowname = "ip_p_inc2" if rowname == "ip_p_inc2y6m"
	replace rowname = "ip_p_inc3" if rowname == "ip_p_inc3y6m"
	replace rowname = "ip_p_inc4" if rowname == "ip_p_inc4y6m"
}

capture confirm variable ddraw
if !_rc local ddraw = 1
else local ddraw = 0
if `ddraw' == 1 keep rowname draw ddraw `ename'
if `ddraw' == 0 keep rowname draw `ename'

rename `ename' x

di "`prefix' `ename' `csvin' `csvout'"
if `ddraw' == 1 reshape wide x, i(draw ddraw) j(rowname) string
if `ddraw' == 0 reshape wide x, i(draw) j(rowname) string

forvalues age = 0/108 {
	capture confirm variable x`prefix'`age'
	if !_rc {
		
		capture confirm string variable x`prefix'`age'
		if !_rc {
			di "string variable: x`prefix'`age'"
			replace x`prefix'`age' = "" if x`prefix'`age' == "NA" | x`prefix'`age' == "NaN"
			destring x`prefix'`age', replace
		}
		
		rename x`prefix'`age' c`age'
	}
	else {
		gen c`age' = 0
	}	
}

/*
// if running p_inc
forvalues age = 0/21 {
	replace c`age' = ""
}
*/

order c*, sequential

if `ddraw' == 1 {
	order ddraw draw, first
	rename ddraw adraw
	sort draw adraw
}
if `ddraw' == 0 {
	order draw, first
	sort draw 
}

outsheet using "`csvout'.csv", comma replace
end
