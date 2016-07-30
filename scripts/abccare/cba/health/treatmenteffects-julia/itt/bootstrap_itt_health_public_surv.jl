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
global data = "$current/../../../../../../data/abccare/extensions/fam-merge"
global results = "$current/../../rslt"
global atecode = "$current/../../../../juliafunctions"

# set up number of bootstraps and controls
global breps = 99 		# remember to subtract 1, i.e. 50 becomes 49
global areps = 99 	# remember to subtract 1, i.e. 50 becomes 49
global controls = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male, :abc]
global ipwvars_all = [:apgar1, :apgar5, :prem_birth]
global component = "health_public_surv"
global factors = 0
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
# Define the gender loop
global genderloop = ["male", "female", "pooled"]

ITTinitial = Dict()
bsid_orig = Dict()
datainuse = Dict()

# Loop over gender and run estimate
for gender in genderloop

	if gender == "male"
		datainuse["$(gender)"] = fammerge[fammerge[:male] .== 1, :]
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
	elseif gender == "female"
		datainuse["$(gender)"] = fammerge[fammerge[:male] .== 0, :]
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
	elseif gender == "pooled"
		datainuse["$(gender)"] = fammerge
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male, :abc]
	end

  # ==================== #
	# Bootstrap esstimates #
	# ==================== #

	# Define the result matrix for the first bootstrap (brep = 0)
	for arep in 0:areps
		datainuse_tmpz = datainuse["$(gender)"]
		datainuse_arepz = datainuse_tmpz[datainuse_tmpz[:adraw] .== arep, :]

		if arep == 0
		  ITTinitial["$(gender)"] = ITTestimator(datainuse_arepz, outcomes, outcomelist, controlset, 0, arep, "no", 0)
	  else
		  ITTinitial_add = ITTestimator(datainuse_arepz, outcomes, outcomelist, controlset, 0, arep, "no", 0)
		  ITTinitial["$(gender)"] = append!(ITTinitial["$(gender)"], ITTinitial_add)
		end
	end
	ITTinitial["$(gender)"] = sort(ITTinitial["$(gender)"], cols = [:draw, :ddraw])
end

	# ================================================= #
	# Define the function for the rest of the bootstrap #
	# ================================================= #
function ITTrun(boots)
	ITTresult = Dict()

	for gender in genderloop

		if gender == "male"
			controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
		elseif gender == "female"
			controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
		elseif gender == "pooled"
			controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male, :abc]
		end

		# Keep the IDs of the original sample to perform ABC boostraps
		bsid_orig_tmp = datainuse["$(gender)"]
		bsid_orig_tmp = bsid_orig_tmp[bsid_orig_tmp[:adraw] .== 0, [:id, :male, :family]]

	  #  bootstrap estimates
	  for brep in 1:boots
	  	if brep != 0
	  	  bsid_draw = bsample(bsid_orig_tmp, :male, :family)
	  	end

	    for arep in 0:areps
				datainuse_tmp = datainuse["$(gender)"]
				datainuse_arep = datainuse_tmp[datainuse_tmp[:adraw] .== arep, :]
				datainuse_act = join(datainuse_arep, bsid_draw, on = [:id, :male, :family], kind = :inner)

				if (brep == 1) & (arep == 0)
					ITTresult["$(gender)"] = ITTestimator(datainuse_act, outcomes, outcomelist, controlset, brep, arep, "no", 0)
				else
					ITTnew = ITTestimator(datainuse_act, outcomes, outcomelist, controlset, brep, arep, "no", 0)
	      	ITTresult["$(gender)"] = append!(ITTresult["$(gender)"], ITTnew)
				end
	    end
	  end

		ITTresult["$(gender)"] = sort(ITTresult["$(gender)"], cols = [:draw, :ddraw])
	end

	return ITTresult
end
