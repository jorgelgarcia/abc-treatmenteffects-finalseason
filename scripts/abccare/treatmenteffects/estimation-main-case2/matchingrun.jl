# ======================================================================== #
# Function to run Matching with Bootstrap (for Parallel Computing Purpose)
# Author: Jessica Yu Kyung Koh
# Created: 06/27/2016
# Edited: 06/27/2016
# ======================================================================== #
# using packages
using DataFrames
using GLM
using StatsBase
using Distances

# Set globals and directories
global current = pwd()
global data = "$current/../../../../data/abccare/extensions/cba-iv"
global output = "$current/../rslt-case2"
global scripts = "$current/../../juliafunctions"

# Include helper files
include("$scripts/helper/writematrix.jl")
include("$scripts/helper/bsample.jl")
include("$scripts/helper/IPW.jl")
include("$scripts/helper/epanechnikov.jl")

# Include function files
include("$scripts/function/matching.jl")

# ================================================================ #
# Declare options, controls, and outcomes of interest
# ================================================================ #
# declare bootstraps
global bootstraps = 99
global dbootstraps = 99

# declare other options
global linear_ipw = 1
global bygender = 1
global factorswitch = 0
global quietly = 1

# ================================================================ #
# Implement options
# ================================================================ #
# Define the gender loop
global genderloop = ["male", "female", "pooled"]

# ================================================================ #
# Bring in data
# ================================================================ #
# List of outcomes
outcomes = readtable("$scripts/../outcomes/outcomes_cba_mainpaper.csv")

# ABC/CARE data
abccare = readtable("$data/append-abccare_iv.csv")

# Prepare data file
include("$current/prepare-data.jl")


# ================================================================ #
# Function to Run Estimation
# ================================================================ #
# Define the result matrix for the first bootstrap (brep = 0)
d_index = 1

Matchini = Dict()

for data in ("abccare", "abc")
#for data in ("abccare", "abc", "care")
	if data == "abccare"
		datainuse = abccare_data
		controlset = conDict["controls_abccare"]
		outcomelist = outcomeDict["outcome_abccare"]
	elseif data == "abc"
		datainuse = abc_data
		controlset = conDict["controls_abc"]
		outcomelist = outcomeDict["outcome_abc"]
	elseif data == "care"
		datainuse = care_data
		controlset = conDict["controls_care"]
		outcomelist = outcomeDict["outcome_care"]
	end

	for dbrep in 0:dbootstraps
		global append_switch = 1
		if dbrep == 0
		 Matchini["Matchini_$(data)"] = mestimate(datainuse, outcomes, outcomelist, controlset, 0, dbrep, "yes", 1)
		 println("printing Matchini $(Matchini["Matchini_$(data)"])")
	  else
	   MatchInitial_add = mestimate(datainuse, outcomes, outcomelist, controlset, 0, dbrep, "yes", 1)
		 if append_switch == 1
	   		Matchini["Matchini_$(data)"]  = append!(Matchini["Matchini_$(data)"] , MatchInitial_add)
				println("for $(data) - $(dbrep) appending sucess")
	 	 end
		end
	end

	if d_index == 1
	  global MatchInitial = Matchini["Matchini_$(data)"]
	else
	  global MatchInitial = append!(MatchInitial, Matchini["Matchini_$(data)"])
	end
	d_index = d_index + 1
end

global MatchInitial = sort(MatchInitial, cols = [:draw, :ddraw])


# ================================================= #
# Define the function for the rest of the bootstrap #
# ================================================= #
function matchingrun(boots)

	d_index = 1

	for data in ("abccare", "abc")
		if data == "abccare"
			datainuse = abccare_data
			controlset = conDict["controls_abccare"]
			outcomelist = outcomeDict["outcome_abccare"]
		elseif data == "abc"
			datainuse = abc_data
			controlset = conDict["controls_abc"]
			outcomelist = outcomeDict["outcome_abc"]
		elseif data == "care"
			datainuse = care_data
			controlset = conDict["controls_care"]
			outcomelist = outcomeDict["outcome_care"]
		end

    MatchDict = Dict()

		global new_switch = 1
		global exist_switch = 0
	  #  bootstrap estimates
	  for brep in 1:boots
			datainuse_tmp = bsample(datainuse, :male, :family)

	    for dbrep in 0:dbootstraps
				global append_switch = 1
				MatchDict["Matching_check_$(data)"] = mestimate(datainuse_tmp, outcomes, outcomelist, controlset, brep, dbrep, "yes", 1)

				if (append_switch == 1) & (new_switch == 1)
					MatchDict["Matching_new_$(data)"] = MatchDict["Matching_check_$(data)"]
					global new_switch = 0 		# turn off after creating matching_new
					global exist_switch = 1
				elseif (append_switch == 1) & (new_switch == 0)
					MatchDict["Matching_add_$(data)"] = MatchDict["Matching_check_$(data)"]
	        MatchDict["Matching_new_$(data)"] = append!(MatchDict["Matching_new_$(data)"], MatchDict["Matching_add_$(data)"])
					global exist_switch = 1
				end
	    end
	  end

		if d_index == 1
			global Matchresult = MatchDict["Matching_new_$(data)"]
		else
			if exist_switch == 1
				global Matchresult = append!(Matchresult, MatchDict["Matching_new_$(data)"])
			end
		end
		d_index = d_index + 1
	end

	global Matchresult = sort(Matchresult, cols = [:draw, :ddraw])
	return Matchresult
end
