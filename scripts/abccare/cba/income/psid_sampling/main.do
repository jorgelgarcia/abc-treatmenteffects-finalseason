clear all
set more off
set maxvar 32000
local filedir: 	pwd

if strpos("`filedir'", "psid") == 0 {
	di as error "Error: Must run dofile from file's directory"
	exit 111
}

* Global directories
local mergedir = subinstr("`filedir'/merge", "/", c(dirsep),.)
local dofiles = subinstr("`filedir'/dofiles", "/", c(dirsep), .)
local savefile = subinstr("`filedir'/psid_bsid", "/", c(dirsep), .)

cd "`dofiles'"
include psid_ids.do
include psid_ids_label_define.do
include psid_ids_organize.do
include psid_usc_merge.do

save "`savefile'", replace
