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
global base =	"$current/../.."
global data = "$current/../../../../../../data/abccare/extensions/outcomes_ate"
global results = "$current/../../rslt"
global atecode = "$current/../../../../juliafunctions"

# set up number of bootstraps and controls
# global areps = 3 	# remember to subtract 1, i.e. 50 becomes 49
global controls = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male, :abc]
global ipwvars_all = [:m_iq0y, :m_ed0y, :m_age0y, :hrabc_index, :p_inc0y, :apgar1, :apgar5, :prem_birth, :m_married0y, :m_teen0y, :f_home0y, :hh_sibs0y, :cohort, :m_work0y]
global component = "progcost"
global factors = 0
global nomurder = 0
global deaths = 1

# Include helper files
#include("$atecode/helper/writematrix.jl")
include("$atecode/helper/bsample.jl")
include("$atecode/helper/IPW.jl")
include("$atecode/helper/epanechnikov.jl")

# Include function files
include("$atecode/function/matching.jl")
include("$atecode/function/ITT.jl")

# Include necessary files
include("$current/../data.jl")

# ================================================================ #
# Implement options
# ================================================================ #
# Deal with no murder
global nm = ""
if nomurder == 1
	global nm = "nm"
end

# Define the gender loop
global genderloop = ["male", "female", "pooled"]

ITTinitial = Dict()
bsid_orig = Dict()
datainuse = Dict()

# Loop over gender and run estimate
for gender in genderloop

	if gender == "male"
		datainuse["$(gender)"] = outcomesate[outcomesate[:male] .== 1, :]
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
	elseif gender == "female"
		datainuse["$(gender)"] = outcomesate[outcomesate[:male] .== 0, :]
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
	elseif gender == "pooled"
		datainuse["$(gender)"] = outcomesate
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male, :abc]
	end

  # ==================== #
	# Bootstrap esstimates #
	# ==================== #
	ITTinitial["$(gender)"] = ITTestimator(datainuse["$(gender)"], outcomes, outcomelist, controlset, 0, 0, "no", 0)
	ITTinitial["$(gender)"] = sort(ITTinitial["$(gender)"], cols = [:draw, :ddraw])
end

	# ================================================= #
	# Define the function for the rest of the bootstrap #
	# ================================================= #
function ITTrun(boots)
	ITTresult = Dict()

	for gender in genderloop
		if gender == "male"
			datainuse["$(gender)"] = outcomesate[outcomesate[:male] .== 1, :]
			controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
		elseif gender == "female"
			datainuse["$(gender)"] = outcomesate[outcomesate[:male] .== 0, :]
			controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
		elseif gender == "pooled"
			datainuse["$(gender)"] = outcomesate
			controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male, :abc]
		end

	  #  bootstrap estimates
	  for brep in 1:boots
			datainuse_boot = bsample(datainuse["$(gender)"], :male, :family)
			if (brep == 1)
				ITTresult["$(gender)"] = ITTestimator(datainuse_boot, outcomes, outcomelist, controlset, brep, 0, "no", 0)
			else
				ITTnew = ITTestimator(datainuse_boot, outcomes, outcomelist, controlset, brep, 0, "no", 0)
      	ITTresult["$(gender)"] = append!(ITTresult["$(gender)"], ITTnew)
			end
	  end

		ITTresult["$(gender)"] = sort(ITTresult["$(gender)"], cols = [:draw, :ddraw])
	end

	return ITTresult
end
