rename ER31996	sestrat
rename ER31997	seclust

gen id = ER30001*1000 + ER30002

keep id sestrat seclust

tempfile psid_ids
save `psid_ids'

* create bootstrap 0: full PSID
drop sestrat seclust 
gen brep = 0
bysort brep: gen i = _n
tempfile psid_ids_append
save `psid_ids_append'

