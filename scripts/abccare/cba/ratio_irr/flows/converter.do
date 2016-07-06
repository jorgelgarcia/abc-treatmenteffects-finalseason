capture program drop converter
program define converter
version 12
syntax, csvin(string) csvout(string) ename(string) prefix(string)

insheet using "`csvin'.csv", names clear	

if "`prefix'" == "p_inc"{
	replace rowname = "p_inc1" if rowname == "p_inc1y6m"
	replace rowname = "p_inc2" if rowname == "p_inc2y6m"
	replace rowname = "p_inc3" if rowname == "p_inc3y6m"
	replace rowname = "p_inc4" if rowname == "p_inc4y6m"
}

capture confirm variable ddraw
if !_rc local ddraw = 1
else local ddraw = 0
if `ddraw' == 1 keep rowname draw ddraw `ename'
if `ddraw' == 0 keep rowname draw `ename'

rename `ename' x

if `ddraw' == 1 reshape wide x, i(draw ddraw) j(rowname) string
if `ddraw' == 0 reshape wide x, i(draw) j(rowname) string

forvalues age = 0/79 {
	capture confirm variable x`prefix'`age'
	if !_rc rename x`prefix'`age' c`age'
	else gen c`age' = 0
}

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
