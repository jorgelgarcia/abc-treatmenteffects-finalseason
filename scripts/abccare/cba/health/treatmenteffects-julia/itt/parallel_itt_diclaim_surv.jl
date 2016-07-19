# ================================================================ #
# ITT estimation of ABC/CARE Using Parallel Processing
# Author: Jessica Yu Kyung Koh
# Created: 06/28/2016
# Updated: 07/08/2016
# ================================================================ #

global here = pwd()

srand(1)

# ======================================================= #
# ITT Estimates Using Parallel Processing
# ======================================================= #
# Call number of processors
using ClusterManagers
procs = 25
#addprocs(procs)
addprocs_pbs(procs)

# Define "to parallelize process"
require("$here/bootstrap_itt_diclaim_surv.jl")
B = 25 # number of workers being used
b = 4  # number of work each worker does

ITTboot = pmap(ITTrun, [b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b])
ITTfinal = Dict()

# Increase the number of "draw" according to the worker number
for gender in genderloop
	for i in 2:B
		ITTboot[i]["$(gender)"][:draw] = ITTboot[i]["$(gender)"][:draw] .+ (b*(i-1))
		for j in 1:2 # concatenated
		ITTboot[i]["$(gender)"][parse("draw_$(j)")] = ITTboot[i]["$(gender)"][parse("draw_$(j)")] .+ (b*(i-1))
		end
	end

	# Concatenate outputs from all workers
	ITTfinal_pre1 = vcat(ITTinitial["$(gender)"], ITTboot[1]["$(gender)"], ITTboot[2]["$(gender)"], ITTboot[3]["$(gender)"], ITTboot[4]["$(gender)"], ITTboot[5]["$(gender)"], ITTboot[6]["$(gender)"], ITTboot[7]["$(gender)"], ITTboot[8]["$(gender)"], ITTboot[9]["$(gender)"], ITTboot[10]["$(gender)"])
	ITTfinal_pre2 = vcat(ITTfinal_pre1, ITTboot[11]["$(gender)"], ITTboot[12]["$(gender)"], ITTboot[13]["$(gender)"], ITTboot[14]["$(gender)"], ITTboot[15]["$(gender)"], ITTboot[16]["$(gender)"], ITTboot[17]["$(gender)"], ITTboot[18]["$(gender)"], ITTboot[19]["$(gender)"], ITTboot[20]["$(gender)"])
	ITTfinal_pre3 = vcat(ITTfinal_pre2, ITTboot[21]["$(gender)"], ITTboot[22]["$(gender)"], ITTboot[23]["$(gender)"], ITTboot[24]["$(gender)"], ITTboot[25]["$(gender)"])
	ITTfinal["$(gender)"] = ITTfinal_pre3

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
		writetable("$(results)/itt/$(component)_$(gender)_P$(P_switch).csv", ResultOutput["itt_$(gender)_P$(P_switch)"])
		c = c + 1
  end
end
