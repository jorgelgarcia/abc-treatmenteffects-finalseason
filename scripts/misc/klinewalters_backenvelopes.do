version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Treatment Effects / CBA
Description:    this .do file investigates Kline-Walters CBAs
*This version:  July 7, 2015
*This .do file: Jorge L. Garcia
*/

// set environment variables (server)
global erc: env erc
global projects: env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// set general locations
// do files
global scripts    = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global data       = "$klmmexico/abccare/NPV/8-21b"
// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

// parameters
local treated    = 65
local control    = 72
local IQeff      = .45524217
local chettyinc  = 566717.69/((1 + .03)^13) 

local ptotalcost = (92570*`treated' - 3057*`control')
local atotalcost = 92750 - 3057

cd $data

// chetty type
// 27
use NPV_vectors_age27.dta, clear

// use chetty income
gen      inc27ret = (meanR1_labor_c - meanR0_labor_c)
replace  inc27ret = inc27ret/`IQeff'
replace  inc27ret = (inc27ret / meanR0_labor_c)

gen   bclabor1 = ((1 + `IQeff'*inc27ret)*(`chettyinc')*(`treated') - (`chettyinc')*(`treated'))/`ptotalcost'
summ  bclabor1
matrix ex1 = [r(mean),r(sd)]

// use our income
gen   bclabor2 = ((1 + `IQeff'*inc27ret)*(meanR0_labor_c)*(`treated') - (meanR0_labor_c)*(`treated'))/`ptotalcost'
summ  bclabor2
matrix ex2 = [r(mean),r(sd)]

// direct bc. 
gen   dbcinc27 = (meanR1_labor_c - meanR0_labor_c)/`atotalcost'
summ  dbcinc27
matrix ex1b = [r(mean),r(sd)]
gen   dbnpv27  = (meanR1_NPV - meanR0_NPV)/`atotalcost'
summ  dbnpv27
matrix ex2b = [r(mean),r(sd)]

// 34
use NPV_vectors_age34.dta, clear

// use income
gen      inc34ret = (meanR1_labor_c - meanR0_labor_c)
replace  inc34ret = inc34ret/`IQeff'
replace  inc34ret = (inc34ret / meanR0_labor_c)

gen   bclabor3 = ((1 + `IQeff'*inc34ret)*(meanR0_labor_c)*(`treated') - (meanR0_labor_c)*(`treated'))/`ptotalcost'
summ  bclabor3
matrix ex3 = [r(mean),r(sd)]

// use npv
gen      inc34ret2 = (meanR1_NPV - meanR0_NPV)
replace  inc34ret2 = inc34ret2/`IQeff'
replace  inc34ret2 = (inc34ret2 / meanR0_NPV)

gen   bclabor4 = ((1 + `IQeff'*inc34ret2)*(meanR0_NPV)*(`treated') - (meanR0_NPV)*(`treated'))/`ptotalcost'
summ  bclabor4
matrix ex4 = [r(mean),r(sd)]

gen   dbcinc34 = (meanR1_labor_c - meanR0_labor_c)/`atotalcost'
summ  dbcinc34
matrix ex3b = [r(mean),r(sd)]
gen   dbnpv34  = (meanR1_NPV - meanR0_NPV)/`atotalcost'
summ  dbnpv34
matrix ex4b = [r(mean),r(sd)]

// life-cycle
use NPV_vectors_age79.dta, clear

// use income
gen      inc79ret = (meanR1_labor_c - meanR0_labor_c)
replace  inc79ret = inc79ret/`IQeff'
replace  inc79ret = (inc79ret / meanR0_labor_c)

gen   bclabor5 = ((1 + `IQeff'*inc79ret)*(meanR0_labor_c)*(`treated') - (meanR0_labor_c)*(`treated'))/`ptotalcost'
summ  bclabor5
matrix ex5 = [r(mean),r(sd)]

// use npv
gen      inc79ret2 = (meanR1_NPV - meanR0_NPV)
replace  inc79ret2 = inc79ret2/`IQeff'
replace  inc79ret2 = (inc79ret2 / meanR0_NPV)

gen   bclabor6 = ((1 + `IQeff'*inc79ret2)*(meanR0_NPV)*(`treated') - (meanR0_NPV)*(`treated'))/`ptotalcost'
summ  bclabor6
matrix ex6 = [r(mean),r(sd)]

gen   dbcinc79 = (meanR1_labor_c - meanR0_labor_c)/`atotalcost'
summ  dbcinc79
matrix ex5b = [r(mean),r(sd)]
gen   dbnpv79  = (meanR1_NPV - meanR0_NPV)/`atotalcost'
summ  dbnpv79
matrix ex6b = [r(mean),r(sd)]

matrix ex = [ex1 \ ex2 \ ex3 \ ex4 \ ex5 \ ex6]
matrix exb = [ex1b \ ex2b \ ex3b \ ex4b \ ex5b \ ex6b]
