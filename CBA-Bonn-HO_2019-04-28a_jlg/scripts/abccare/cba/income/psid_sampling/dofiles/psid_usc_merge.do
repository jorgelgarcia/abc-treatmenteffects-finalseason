cd "`mergedir'"

use USC_PSID_bootstrap_draws.dta, clear

joinby sestrat seclust using `psid_ids'

drop sestrat seclust bsample

bysort brep: gen i = _n

// bring in bootstrap 0 --- No, since... well, USC set up the bootstrap to be... sampled to reflect PSID... but that doesn't relaly make a difference does it?
* append using `psid_ids_append'

sort brep i
rename id draw
reshape wide draw, i(i) j(brep)

drop i
