# =================================================================== #
# Function to run ITT with Bootstrap (for Parallel Computing Purpose)
# Author: Jessica Yu Kyung Koh
# Created: 06/27/2016
# Edited: 07/08/2016
# =================================================================== #
# Using packages
using DataFrames
using GLM
using StatsBase
using Distances

# Set globals and directories
global current = pwd()
global base =	"$current/../../../.."		# This is script/abccare folder
global data = "$current/../../../../../../data/abccare/extensions/cba-iv"
global dofiles = "$current"
global results = "$current/../../rslt"
global atecode = "$current/../../../../juliafunctions"

# Include necessary files
include("$current/driver.jl")
include("$current/data.jl")

# ================================================================ #
# Implement options
# ================================================================ #
# Define the gender loop
global genderloop = ["male", "female", "pooled"]

MatchInitial = Dict()
bsid_orig = Dict()
datainuse = Dict()

# Loop over gender and run estimate
for gender in genderloop

	if gender == "male"
		datainuse["$(gender)"] = abccare[abccare[:male] .== 1, :]
	elseif gender == "female"
		datainuse["$(gender)"] = abccare[abccare[:male] .== 0, :]
	elseif gender == "pooled"
		datainuse["$(gender)"] = abccare
	end

	# Drop "_$(gender)" from column names
	colnames = names(datainuse["$(gender)"])
	for col in colnames
		strver = "$(col)"
		if contains(strver, "_$(gender)")
			splitver = split(strver, "_")
			newname = parse(splitver[1])
			rename!(datainuse["$(gender)"], col, newname)
		end
	end

  # ==================== #
	# Bootstrap esstimates #
	# ==================== #
	# Keep the IDs of the original sample to perform ABC boostraps
	bsid_orig_tmp = datainuse["$(gender)"]
	bsid_orig_tmp = bsid_orig_tmp[bsid_orig_tmp[:adraw] .== 0, [:id, :male, :family]]
	bsid_orig["$(gender)"] = bsid_orig_tmp

	# Define the result matrix for the first bootstrap (brep = 0)
	for arep in 0:areps
		if arep == 0
		  MatchInitial["$(gender)"] = mestimate(datainuse["$(gender)"], outcomes, outcomelist, controls, 0, arep, "no", 0)
	  else
		  MatchInitial_add = mestimate(datainuse["$(gender)"], outcomes, outcomelist, controls, 0, arep, "no", 0)
		  MatchInitial["$(gender)"] = append!(MatchInitial["$(gender)"], MatchInitial_add)
		end
	end
	MatchInitial["$(gender)"] = sort(MatchInitial["$(gender)"], cols = [:draw, :ddraw])
end

global MatchInitial = MatchInitial

	# ================================================= #
	# Define the function for the rest of the bootstrap #
	# ================================================= #
function matchingrun(boots)
	Matchresult = Dict()
	MatchDict = Dict()

	for gender in genderloop

		global new_switch = 1

	  #  bootstrap estimates
	  for brep in 1:boots
	  	if brep != 0
	  	  bsid_draw = bsample(bsid_orig["$(gender)"], :male, :family)
	  	end

	    for arep in 0:areps
				datainuse_tmp = datainuse["$(gender)"]
				datainuse_tmp = datainuse_tmp[datainuse_tmp[:adraw] .== arep, :]
				datainuse_tmp = join(datainuse_tmp, bsid_draw, on = [:id, :male, :family], kind = :inner)

				global append_switch = 1
				MatchDict["Matching_check_$(gender)"] = mestimate(datainuse_tmp, outcomes, outcomelist, controlset, brep, arep, "no", 0)

				if (append_switch == 1) & (new_switch == 1)
					MatchDict["Matching_new_$(gender)"] = MatchDict["Matching_check_$(gender)"]
					global new_switch = 0
				elseif (append_switch == 1) & (new_switch == 0)
					MatchDict["Matching_add_$(data)"] = MatchDict["Matching_check_$(data)"]
					MatchDict["Matching_new_$(data)"] = append!(MatchDict["Matching_new_$(data)"], MatchDict["Matching_add_$(data)"])
				end
	    end
	  end

		Matchresult["$(gender)"] = MatchDict["Matching_new_$(data)"]

		global Matchresult["$(gender)"] = sort(Matchresult["$(gender)"] , cols = [:draw, :ddraw])
	end
	return Matchresult
end
