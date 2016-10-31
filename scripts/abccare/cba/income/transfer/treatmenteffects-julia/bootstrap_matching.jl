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
global base =	"$current/../.."		# This is script/abccare folder
global data = "$current/../../../../../../data/abccare/extensions/cba-iv"
global dofiles = "$current"
global results = "$current/../../rslt"
global atecode = "$current/../../../../juliafunctions"

# set up number of bootstraps and controls
global itt = 0			# matching estimator is the default
global breps = 98 		# remember to subtract 1, i.e. 50 becomes 49
global areps = 98   	# remember to subtract 1, i.e. 50 becomes 49
global controls = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male, :abc]
global ipwvars_all = [:m_iq0y, :m_ed0y, :m_age0y, :hrabc_index, :p_inc0y, :apgar1, :apgar5, :prem_birth, :m_married0y, :m_teen0y, :f_home0y, :hh_sibs0y, :cohort, :m_work0y, :has_relatives]
global factorswitch = 0
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
include("$current/data.jl")

# ================================================================ #
# Implement options
# ================================================================ #
# Define the gender loop
global genderloop = ["female"]

MatchInitial = Dict()
bsid_orig = Dict()
datainuse = Dict()

# Loop over gender and run estimate
for gender in genderloop

	if gender == "male"
		datainuse["$(gender)"] = abccare[abccare[:male] .== 1, :]
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
	elseif gender == "female"
		datainuse["$(gender)"] = abccare[abccare[:male] .== 0, :]
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
		datainuse["$(gender)"][:male] = 1 # bsample does not work for [:male] == 0
	elseif gender == "pooled"
		datainuse["$(gender)"] = abccare
		controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male, :abc]
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

	# Define the result matrix for the first bootstrap (brep = 0)
	for arep in 0:areps
		datainuse_tmpz = datainuse["$(gender)"]
		datainuse_tmpz = datainuse_tmpz[!isna(datainuse_tmpz[:adraw]), :]
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

	# ================================================= #
	# Define the function for the rest of the bootstrap #
	# ================================================= #
function matchingrun(boots)
	Matchresult = Dict()
	MatchDict = Dict()

	for gender in genderloop

		global new_switch = 1

		if gender == "male"
			controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
		elseif gender == "female"
			controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :abc]
		elseif gender == "pooled"
			controlset = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male, :abc]
		end

		# Keep the IDs of the original sample to perform ABC boostraps
		bsid_orig_tmp = datainuse["$(gender)"]
		bsid_orig_tmp = bsid_orig_tmp[!isna(bsid_orig_tmp[:adraw]), :]
		bsid_orig_tmp = bsid_orig_tmp[bsid_orig_tmp[:adraw] .== 0, [:id, :male, :family]]

	  #  bootstrap estimates
	  for brep in 1:boots
	  	if brep != 0
	  	  bsid_draw = bsample(bsid_orig_tmp, :male, :family)
	  	end

	    for arep in 0:areps
				datainuse_tmp = datainuse["$(gender)"]
				datainuse_tmp = datainuse_tmp[!isna(datainuse_tmp[:adraw]), :]
				datainuse_tmp = datainuse_tmp[datainuse_tmp[:adraw] .== arep, :]
				datainuse_act = join(datainuse_tmp, bsid_draw, on = [:id, :male, :family], kind = :inner)

				global append_switch = 1
			  MatchDict["Matching_check_$(gender)"] = mestimate(datainuse_act, outcomes, outcomelist, controlset, brep, arep, "no", 0)

				if (append_switch == 1) & (new_switch == 1)
					MatchDict["Matching_new_$(gender)"] = MatchDict["Matching_check_$(gender)"]
					global new_switch = 0
				elseif (append_switch == 1) & (new_switch == 0)
					MatchDict["Matching_add_$(gender)"] = MatchDict["Matching_check_$(gender)"]
					MatchDict["Matching_new_$(gender)"] = append!(MatchDict["Matching_new_$(gender)"], MatchDict["Matching_add_$(gender)"])
				end
	    end
	  end

		Matchresult["$(gender)"] = MatchDict["Matching_new_$(gender)"]
		Matchresult["$(gender)"] = sort(Matchresult["$(gender)"] , cols = [:draw, :ddraw])
	end

	return Matchresult
end
