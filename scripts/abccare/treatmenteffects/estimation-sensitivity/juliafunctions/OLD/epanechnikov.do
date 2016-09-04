*=======================================================
* Function to form Epanechnikov kernel
*=======================================================

capture program drop epanechnikov
capture program define epanechnikov

version 12
syntax, mprefix(string) controls(varlist) [bandwidth(real 1)]

* switch to smaller dataset for speed
tempfile presmall
save `presmall', replace
sort id
quietly reg `controls' R
keep if e(sample) == 1
keep id R `controls'

* make file for storing all the weights
tempfile small
save `small', replace
keep id
duplicates drop id, force
tempfile weights
save `weights', replace
use `small', clear

* form inverse of covariance matrix
* NOTE: do you use the covariance matrix of eveyrone, or split it by treatment?
capture corr `controls' if R == 1, cov
if _rc exit _rc
mat Cinv1 = invsym(r(C))

capture corr `controls' if R == 0, cov
if _rc exit _rc
mat Cinv0 = invsym(r(C))

* estimate the mahalanobis distance for each pair
levelsof id if R == 1, local(ids_R)
levelsof id if R == 0, local(ids_control)

foreach t in 0 1 {	
	* prepare switches so the code below generating weights can be looped
	local t_c = 1 - `t'	
	if `t' == 0 {
		local ids_loop `ids_control'
		local invcov Cinv1
	}
	if `t' == 1 {	
		local ids_loop `ids_R'
		local invcov Cinv0
	}

	foreach id in `ids_loop' {
		use `small', clear
		
		* generate vector of (X - mu), where mu is the observation for each individual
		local maha_controls
		foreach v in `controls' {
			levelsof `v' if id == `id', local(vlev)
			gen _`v'_`id'  = `v' - `vlev'
			local maha_controls `maha_controls' _`v'_`id'
		}
		mkmat `maha_controls' if R == `t_c', mat(X) rownames(id)
		
		* estimate mahalanobis metric, save as a dataset
		mat maha = X * `invcov' * X'
		mat maha = vecdiag(cholesky(diag(vecdiag(maha))))'
		*mat maha = vecdiag(maha)' // here was the old code, where we did not take square root
		clear
		svmat maha
				
		* convert mahalanobis into epanechnikov
		gen inband = abs(maha1/`bandwidth') <= 1
		replace maha1 = (1/`bandwidth') * (3/4) * (1 - (maha1/`bandwidth')^2) * inband
		rename maha1 `mprefix'`id'
		drop inband
		
		* bring in IDs to allow for merge into dataset of weights
		gen id = .
		local ids: rowname maha
		local idn: word count `ids'
		forvalues i = 1/`idn' {
			local idi: word `i' of `ids'
			replace id = `idi' in `i'
		}
		
		* merge with file of weights
		duplicates drop id, force
		merge 1:m id using `weights', nogen
		save `weights', replace
		
	}
}
* merge in matching weights
use `presmall', clear
merge m:1 id using `weights', nogen

end
