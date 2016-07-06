
set more off
clear all
set matsize 11000

/*
Project    :  ABC CBA

Description:  this .do file describes education variables at age 30 in ABC

Basics:       
		
This version: 07/09/2015

This .do file: Jorge Luis Garcia
This project : CEHD
*/

// set environment variables
global erc: env erc
global projects: env projects
global klmshare: env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// declare addresses
*global dofiles = "$klmmexico/abc-cba/analysis/cba/allcomponents"
// abc-data
*global data    = "$klmmexico/abc-cba/analysis/cba/rslt/"
global data	= "E:\Documents\ERC\Projects\abc-cba\analysis\cba\rslt"
// output
*global output  = "$klmmexico/abc-cba/draft/output/misc"

// 
cd $data
insheet using di_claim.csv, names clear

levelsof age, local(ages)
foreach a in `ages' {
	foreach s in m f {
		levelsof `s' if age == `a', local(`s'`a')
	}
}

insheet using flow_diclaim_m.csv, clear
collapse *
drop draw adraw
gen id = 1
reshape long c, i(id) j(age) 
rename c diclaim_m

levelsof age, local(ages)
foreach a in `ages' {
	if "`m`a''" != "" replace diclaim_m = diclaim_m * `m`a'' if age==`a'
}

bysort id: gen diclaim_m_cum = sum(diclaim_m)
