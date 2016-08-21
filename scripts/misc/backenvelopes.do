version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Treatment Effects / CBA
Description:    this .do file investigates the IRR/BC distributions
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

local ptotalcost = (92570*`treated' - 3057*`control')
local atotalcost = 92750 - 3057


// pool etimates
cd $data
use NPV_vectors_age27.dta, clear







