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
global base =	"~/abc-cba"
global abc = "~/abc-cba/data/abccare/extensions/cba-iv"
global dofiles = "~/abc-cba/analysis/income/code/labor/stata"
global results = "~/abc-cba/analysis/income/rslt"
global atecode = "~/abc-care/scripts/controlcontamination/atecode"

# Include necessary files
include("driver.jl")
include("data.jl")

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
		  ITTinitial["$(gender)"] = ITTestimator(datainuse["$(gender)"], outcomes, outcomelist, controls, 0, arep, "no", 0)
	  else
		  ITTinitial_add = ITTestimator(datainuse["$(gender)"], outcomes, outcomelist, controls, 0, arep, "no", 0)
		  ITTinitial["$(gender)"] = append!(ITTinitial["$(gender)"], ITTinitial_add)
		end
	end
	ITTinitial["$(gender)"] = sort(ITTinitial["$(gender)"], cols = [:draw, :ddraw])
end

global ITTinitial = ITTinitial

	# ================================================= #
	# Define the function for the rest of the bootstrap #
	# ================================================= #
function ITTrun(boots)
	ITTresult = Dict()

	for gender in genderloop
	  #  bootstrap estimates
	  for brep in 1:boots
	  	if brep != 0
	  	  bsid_draw = bsample(bsid_orig["$(gender)"], :male, :family)
	  	end

	    for arep in 0:areps
				datainuse_tmp = datainuse["$(gender)"]
				datainuse_tmp = datainuse_tmp[datainuse_tmp[:adraw] .== arep, :]
				datainuse_tmp = join(datainuse_tmp, bsid_draw, on = [:id, :male, :family], kind = :inner)
				if (brep == 1) & (arep == 0)
					ITTresult["$(gender)"] = ITTestimator(datainuse_tmp, outcomes, outcomelist, controlset, brep, arep, "no", 0)
				else
					ITTnew = ITTestimator(datainuse_tmp, outcomes, outcomelist, controlset, brep, arep, "no", 0)
	      	ITTresult["$(gender)"] = append!(ITTresult["$(gender)"], ITTnew)
				end
	    end
	  end

		global ITTresult["$(gender)"] = sort(ITTresult["$(gender)"], cols = [:draw, :ddraw])
	end

	return ITTresult
end
