clear all
set maxvar 32000
set more off	

* set up global paths

global klmshare:	env klmshare
*global abc		"$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extension/cba-iv/append-abccare_iv.dta"
global abc		"/home/jkcshea/Documents/cehd/projects/abc-cba/data/abccare/extensions/cba-iv/append-abccare_iv.dta"
global psid		"$klmshare/Data_Central/data-repos/psid/extensions/abc-match/psid-abc-match.dta"
global nlsy		"$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/nlsy-abc-match.dta"
global cnlsy		"$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/cnlsy-abc-match.dta"

global projects:	env projects
global output		"$projects/abc-treatmenteffects-finalseason/AppOutput/Methodology"

* form histogram of variables

local bw = 1
local center = 0
local step = 5

foreach data in abc psid nlsy cnlsy{
	use "${`data'}", clear
	
	if "`data'" == "abc" {
		drop if R == 0 & RV == 1
		sum years_30y
		local abc_n = r(N)
	}

	foreach v in years_30y {

		keep `v'
		tempfile hist`v'
		
		* find the range of the distribution
		quietly sum `v' 
		local min = floor(r(min))
		local max = ceil(r(max))
		local bars = (`max' - `min') / `bw'
		
		* set locals for forming the PDF
		gen index = .
		gen pdf = .
		local bottom = `min'
		quietly sum `v'
		local total = r(N)
		local bwhalf = `bw' / 2
		local missingix
		
		* form the PDF above the center
		local top = `center' + `bwhalf'
		local bottom = `center' - `bwhalf'
		while `top' < `max' {
			* save list of any missing indexes (i.e. PDF = 0)
			quietly count if `v' > `bottom' & `v' <= `top'
			if r(N) == 0 {
				local index = (`top' + `bottom')/2
				local missingix `missingix' " `index' "
			}
			gen tmp = 1 if `v' > `bottom' & `v' <= `top'
			replace index = (`top' + `bottom')/2 if `v' > `bottom' & `v' <= `top'
			egen tmpsum = sum(tmp)
			quietly sum tmpsum
			replace pdf = r(mean)/`total' if `v' > `bottom' & `v' <= `top'

			drop tmp tmpsum
			
			local top = `top' + `bw'
			local bottom = `bottom' + `bw'
		}
		
		* form the PDF below the center
		local top = `center' - `bwhalf'
		local bottom = `center' - `bwhalf' - `bw'
		while `bottom' > `min' {
			* save list of any missing indexes (i.e. PDF = 0)
			quietly count if `v' > `bottom' & `v' <= `top'
			if r(N) == 0 {
				local index = (`top' + `bottom')/2
				local missingix `missingix' " `index' "
			}	
			gen tmp = 1 if `v' > `bottom' & `v' <= `top'
			replace index = (`top' + `bottom')/2 if `v' > `bottom' & `v' <= `top'
			egen tmpsum = sum(tmp)
			quietly sum tmpsum
			replace pdf = r(mean)/`total' if `v' > `bottom' & `v' <= `top'

			drop tmp tmpsum
			
			local top = `top' - `bw'
			local bottom = `bottom' - `bw'
		}
		
		* create the PDF data set (with missing indexes)
		contract pdf index
		rename pdf pdf`data'
		save `hist`v'', replace

		* bring back in missing indexes
		clear
		di `missingix'
		local missn: word count `missingix'
		set obs `missn'
		gen index = .
		forvalues i = 1/`missn'{
			local ixval: word `i' of `missingix'
			replace index = `ixval' in `i'
		}
		tempfile missingix
		save `missingix', replace

		* combine all histogram data sets + missing index
		use `hist`v'', clear
		append using `missingix'
		drop if missing(index)
		keep index pdf*
		tempfile hist`data'
		save `hist`data'', replace
	}
}

* merge all data sets together
use `histabc', clear
foreach data in psid nlsy cnlsy {
	merge 1:1 index using `hist`data''
	drop _merge
}
	

* perpare locals to fix horizontal labels of the histogram
sort index
gen i = _n
quietly sum i
local N = r(max)
local customlab

* decide what labels you want, based on step argument 
gen step = `step'
gen labtag = mod(index, step)

* generate label
forvalues j = 1/`N' {
	quietly levelsof index in `j', local(labname)
	quietly levelsof labtag in `j', local(labtag)
	if `labtag' == 0 {
		local customlab `customlab' `j' `" `labname' "'
	}
	else {
		local customlab `customlab' `j' `" "'
	}
}

di "`dataobs'"

* generate x axis label using tricky method
gen xlab = "Years of Education"
	
* plot
#delimit
graph bar pdfabc pdfpsid pdfnlsy pdfcnlsy, 
	over(index,  relabel(`customlab') label(labsize(small))) 
	over(xlab, label(labsize(small))) 
	bar(1, color(gs1)) 
	bar(2, color(gs5)) 
	bar(3, color(gs8)) 
	bar(4, color(gs12)) 

	legend(label(1 ABC, CARE (N = `abc_n')) label(2 PSID (N = 14,599)) label(3 NLSY (N = 12, 686)) label(4 CNLSY (N = 2,222)) size(small) rows(2))
	ylabel(, nolabels  nogrid angle(h) glcolor(gs14))
	ytitle(Density, size(small))
	graphregion(color(white)) plotregion(fcolor(white))
;
#delimit cr

cd "$filedir"
graph export "$output/support_educ.eps", replace





/*


*http://www.stata.com/support/faqs/graphics/gph/graphdocs/bar-chart-with-multiple-bars-graphed-over-another-variable/index.html
