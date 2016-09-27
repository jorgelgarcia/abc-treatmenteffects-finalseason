# ================================================================ #
# ITT estimation of ABC/CARE Using Parallel Processing
# Author: Jessica Yu Kyung Koh
# Created: 05/03/2016
# Updated: 06/28/2016
# ================================================================ #

global thisdir = pwd()

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
require("$thisdir/ITTrun.jl")
B = 25 # number of workers being used
b = 40  # number of work each worker does

ITTboot = pmap(ITTrun, [b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b])

# Increase the number of "draw" according to the worker number
for i in 2:B
	ITTboot[i][:draw] = ITTboot[i][:draw] .+ (b*(i-1))
	for j in 1:8 # concatenated
	ITTboot[i][parse("draw_$(j)")] = ITTboot[i][parse("draw_$(j)")] .+ (b*(i-1))
	end
end

# Concatenate outputs from all workers
ITTfinal_pre1 = vcat(ITTinitial, ITTboot[1], ITTboot[2], ITTboot[3], ITTboot[4], ITTboot[5], ITTboot[6], ITTboot[7], ITTboot[8], ITTboot[9], ITTboot[10])
ITTfinal_pre2 = vcat(ITTfinal_pre1, ITTboot[11], ITTboot[12], ITTboot[13], ITTboot[14], ITTboot[15], ITTboot[16], ITTboot[17], ITTboot[18], ITTboot[19], ITTboot[20])
ITTfinal = vcat(ITTfinal_pre2, ITTboot[21], ITTboot[22], ITTboot[23], ITTboot[24], ITTboot[25])

# ===================================================== #
# Export to csv
# ===================================================== #
# Define a dictionary for the file outputs to allow for file handles to include locals
ResultOutput = Dict()
colnames = [:rowname, :draw, :ddraw, :itt_noctrl, :itt_noctrl_p, :itt_noctrl_N, :itt_ctrl, :itt_ctrl_p, :itt_ctrl_N, :itt_wctrl, :itt_wctrl_p, :itt_wctrl_N]

# open the necessary matrix
n = 0
for gender in genderloop
	c = 0
	for P_switch in (0, 1, 10)
		ResultOutput["itt_$(gender)_P$(P_switch)"] = DataFrame(rowname = [], draw = [], ddraw = [],
		                               										itt_noctrl = [], itt_noctrl_p = [], itt_noctrl_N = [],
		                               										itt_ctrl = [], itt_ctrl_p = [], itt_ctrl_N = [],
		                               										itt_wctrl = [], itt_wctrl_p = [], itt_wctrl_N = [])

		if n == 0
			ResultOutput["itt_$(gender)_P$(P_switch)"] = ITTfinal[:, colnames]
			delete!(ITTfinal, colnames)
		else
			rename!(ITTfinal, [parse("rowname_$(n)"), parse("draw_$(n)"), parse("ddraw_$(n)"), parse("itt_noctrl_$(n)"), parse("itt_noctrl_p_$(n)"), parse("itt_noctrl_N_$(n)"), parse("itt_ctrl_$(n)"), parse("itt_ctrl_p_$(n)"), parse("itt_ctrl_N_$(n)"), parse("itt_wctrl_$(n)"), parse("itt_wctrl_p_$(n)"), parse("itt_wctrl_N_$(n)")], colnames)
			ResultOutput["itt_$(gender)_P$(P_switch)"] = ITTfinal[:, colnames]
			delete!(ITTfinal, colnames)
		end
		writetable("$(output)/itt/itt_$(gender)_P$(P_switch)_sib$(child_sibs).csv", ResultOutput["itt_$(gender)_P$(P_switch)"])
		n = n + 1
  end
end
