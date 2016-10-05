# ================================================================= #
# Function to run ITT with Bootstrap (for Parallel Computing Purpose)
# Author: Jessica Yu Kyung Koh
# Created: 06/27/2016
# Edited: 06/27/2016
# ================================================================= #
# using packages
using DataFrames
using GLM
using StatsBase
using Distances

# Set globals and directories
global current = pwd()
global data = "$current/../../../../data/abccare/extensions/cba-iv"
global output = "$current/../rslt"
global scripts = "$current/../../juliafunctions"

# Include helper files
include("$scripts/helper/writematrix.jl")
include("$scripts/helper/bsample.jl")
include("$scripts/helper/IPW.jl")

# Include function files
include("$scripts/function/ITT.jl")

# ================================================================ #
# Declare options, controls, and outcomes of interest
# ================================================================ #
# declare bootstraps
global bootstraps = 99
global dbootstraps = 0

# declare other options
global linear_ipw = 1
global bygender = 1
global factors = 1
global quietly = 1
global child_sibs = 0

# ================================================================ #
# Implement options
# ================================================================ #
# Define the gender loop
global genderloop = ["male", "female", "pooled"]

# ================================================================ #
# Bring in data
# ================================================================ #
# List of outcomes
outcomes = readtable("$scripts/../outcomes/outcomes_cba_dis_p_inc.csv")

# ABC/CARE data
abccare = readtable("$data/append-abccare_iv.csv")

# Prepare data file
include("$current/prepare-data.jl")

# ================================================================ #
# Function to Run Estimation
# ================================================================ #
# Define the result matrix for the first bootstrap (brep = 0)

d_index = 1

ITTini = Dict()

for data in ["abccare", "abc"]
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
		if dbrep == 0
		 ITTini["ITTini_$(data)"] = ITTestimator(datainuse, outcomes, outcomelist, controlset, 0, dbrep, "yes", 1)
	  else
		  ITTinitial_add = ITTestimator(datainuse, outcomes, outcomelist, controlset, 0, dbrep, "yes", 1)
		  ITTini["ITTini_$(data)"] = append!(ITTini["ITTini_$(data)"], ITTinitial_add)
		end
	end

	if d_index == 1
	  global ITTinitial = ITTini["ITTini_$(data)"]
	else
	  global ITTinitial = append!(ITTinitial, ITTini["ITTini_$(data)"])
	end
	d_index = d_index + 1
end
global ITTinitial = sort(ITTinitial, cols = [:draw, :ddraw])


# ================================================= #
# Define the function for the rest of the bootstrap #
# ================================================= #
function ITTrun(boots)

	d_index = 1

	for data in ["abccare", "abc"]
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


		ITTDict = Dict()

	  #  bootstrap estimates
	  for brep in 1:boots
	  	if brep != 0
	  	  datainuse_tmp = bsample(datainuse, :male, :family)
	  	end

	    for dbrep in 0:dbootstraps
	      if (brep == 1) & (dbrep == 0)
	        ITTDict["ITTresult_new_$(data)"] = ITTestimator(datainuse_tmp, outcomes, outcomelist, controlset, brep, dbrep, "yes", 1)
	      else
	        ITTDict["ITTresult_add_$(data)"] = ITTestimator(datainuse_tmp, outcomes, outcomelist, controlset, brep, dbrep, "yes", 1)
	        ITTDict["ITTresult_new_$(data)"] = append!(ITTDict["ITTresult_new_$(data)"], ITTDict["ITTresult_add_$(data)"])
	      end
	    end
	  end

		if d_index == 1
			global ITTresult = ITTDict["ITTresult_new_$(data)"]
		else
			global ITTresult = append!(ITTresult, ITTDict["ITTresult_new_$(data)"])
		end
		d_index = d_index + 1
	end

	global ITTresult = sort(ITTresult, cols = [:draw, :ddraw])
	return ITTresult

end
