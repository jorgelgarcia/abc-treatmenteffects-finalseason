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
global areps = 1 	# remember to subtract 1, i.e. 50 becomes 49
global controls = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male]
global ipwvars_all = [:apgar1, :apgar5, :prem_birth]
global component = "ssiclaim_surv"
global factors = 0
global deaths = 1

# Include helper files
include("$atecode/helper/writematrix.jl")
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

MatchInitial = Dict()
bsid_orig = Dict()
datainuse = Dict()

# Loop over gender and run estimate
for gender in genderloop

	if gender == "male"
		datainuse["$(gender)"] = fammerge[fammerge[:male] .== 1, :]
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives]
	elseif gender == "female"
		datainuse["$(gender)"] = fammerge[fammerge[:male] .== 0, :]
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives]
	elseif gender == "pooled"
		datainuse["$(gender)"] = fammerge
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male]
	end

  # ==================== #
	# Bootstrap esstimates #
	# ==================== #
	# Define the result matrix for the first bootstrap (brep = 0)
	for arep in 0:areps
		datainuse_tmpz = datainuse["$(gender)"]
		datainuse_arepz = datainuse_tmpz[datainuse_tmpz[:adraw] .== arep, :]
		if arep == 0
		  MatchInitial["$(gender)"] = mestimate(datainuse_arepz, outcomes, outcomelist, controlset, 0, arep, "no", 0)
	  else
		  MatchInitial_add = mestimate(datainuse_arepz, outcomes, outcomelist, controlset, 0, arep, "no", 0)
		  MatchInitial["$(gender)"] = append!(MatchInitial["$(gender)"], MatchInitial_add)
		end
	end
	MatchInitial["$(gender)"] = sort(MatchInitial["$(gender)"], cols = [:draw, :ddraw])
end
