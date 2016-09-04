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
global output = "$current/../rslt-sensitivity"
global scripts = "$current/../../juliafunctions"

# Include helper files
include("$current/juliafunctions/helper/writematrix.jl")
include("$current/juliafunctions/helper/bsample.jl")
include("$current/juliafunctions/helper/IPW.jl")
include("$current/juliafunctions/helper/epanechnikov.jl")

# Include function files
include("$current/juliafunctions/function/matching.jl")

# ================================================================ #
# Declare options, controls, and outcomes of interest
# ================================================================ #
# declare bootstraps
global bootstraps = 100
global dbootstraps = 0

# declare other options
global linear_ipw = 1
global bygender = 1
global factors = 1
global quietly = 1

# ================================================================ #
# Implement options
# ================================================================ #
# Define the gender loop
global genderloop = ["male", "female"]

# ================================================================ #
# Bring in data
# ================================================================ #
# List of outcomes
outcomes = readtable("$scripts/../outcomes/outcomes_cba_sensitivity.csv")

# ABC/CARE data
abccare = readtable("$data/append-abccare_iv.csv")

# Controls data
controldata = readtable("$current/controls/control_combination.csv")

# Prepare data file
include("$current/prepare-data.jl")


# ================================================================ #
# Function to Run Estimation
# ================================================================ #
# Define the result matrix for the first bootstrap (brep = 0)
d_index = 1

Matchini = Dict()

for data in ("abccare")
	if data == "abccare"
		datainuse = abccare_data
		controlset = conDict["controls_abccare"]
		outcomelist = outcomeDict["outcome_abccare"]
	end

	for dbrep in 0:dbootstraps
		global append_switch = 1
		if dbrep == 0
		 Matchini["Matchini_$(data)"] = mestimate(datainuse, outcomes, outcomelist, 0, dbrep, "yes", 1)
	  else
	   MatchInitial_add = mestimate(datainuse, outcomes, outcomelist, 0, dbrep, "yes", 1)
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

	for data in ("abccare")
		if data == "abccare"
			datainuse = abccare_data
			controlset = conDict["controls_abccare"]
			outcomelist = outcomeDict["outcome_abccare"]
		end

    MatchDict = Dict()

		global new_switch = 1
		global exist_switch = 0
	  #  bootstrap estimates
	  for brep in 1:boots
			datainuse_tmp = bsample(datainuse, :male, :family)

	    for dbrep in 0:dbootstraps
				global append_switch = 1
				MatchDict["Matching_check_$(data)"] = mestimate(datainuse_tmp, outcomes, outcomelist, brep, dbrep, "yes", 1)

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
