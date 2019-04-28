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
global areps = 0 	# remember to subtract 1, i.e. 50 becomes 49
global controls = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male]
global ipwvars_all = [:apgar1, :apgar5, :prem_birth]
global component = "ssclaim_surv"
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
		  ITTinitial["$(gender)"] = ITTestimator(datainuse_arepz, outcomes, outcomelist, controlset, 0, arep, "no", 0)
	  else
		  ITTinitial_add = ITTestimator(datainuse_arepz, outcomes, outcomelist, controlset, 0, arep, "no", 0)
		  ITTinitial["$(gender)"] = append!(ITTinitial["$(gender)"], ITTinitial_add)
		end
	end
	ITTinitial["$(gender)"] = sort(ITTinitial["$(gender)"], cols = [:draw, :ddraw])
end

# Export to csv
ITTfinal = Dict()
for gender in genderloop

	ITTfinal["$(gender)"] = ITTinitial["$(gender)"]

	# ===================================================== #
	# Export to csv
	# ===================================================== #
	# Define a dictionary for the file outputs to allow for file handles to include locals
	ResultOutput = Dict()
	colnames = [:rowname, :draw, :ddraw, :itt_noctrl, :itt_noctrl_p, :itt_noctrl_N, :itt_ctrl, :itt_ctrl_p, :itt_ctrl_N, :itt_wctrl, :itt_wctrl_p, :itt_wctrl_N]

	# open the necessary matrix
	c = 0
	for P_switch in (0, 1, 10)
		ResultOutput["itt_$(gender)_P$(P_switch)"] = DataFrame(rowname = [], draw = [], ddraw = [],
		                               										itt_noctrl = [], itt_noctrl_p = [], itt_noctrl_N = [],
		                               										itt_ctrl = [], itt_ctrl_p = [], itt_ctrl_N = [],
		                               										itt_wctrl = [], itt_wctrl_p = [], itt_wctrl_N = [])

		if c == 0
			ResultOutput["itt_$(gender)_P$(P_switch)"] = ITTfinal["$(gender)"][:, colnames]
			delete!(ITTfinal["$(gender)"], colnames)
		else
			rename!(ITTfinal["$(gender)"], [parse("rowname_$(c)"), parse("draw_$(c)"), parse("ddraw_$(c)"), parse("itt_noctrl_$(c)"), parse("itt_noctrl_p_$(c)"), parse("itt_noctrl_N_$(c)"), parse("itt_ctrl_$(c)"), parse("itt_ctrl_p_$(c)"), parse("itt_ctrl_N_$(c)"), parse("itt_wctrl_$(c)"), parse("itt_wctrl_p_$(c)"), parse("itt_wctrl_N_$(c)")], colnames)
			ResultOutput["itt_$(gender)_P$(P_switch)"] = ITTfinal["$(gender)"][:, colnames]
			delete!(ITTfinal["$(gender)"], colnames)
		end
		writetable("$(results)/itt_point/$(component)_$(gender)_P$(P_switch).csv", ResultOutput["itt_$(gender)_P$(P_switch)"])
		c = c + 1
  end
end
