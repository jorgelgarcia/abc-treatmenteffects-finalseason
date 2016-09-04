# ================================================================ #
# Matching estimation of ABC/CARE Using Parallel Processing
# Author: Jessica Yu Kyung Koh
# Created: 05/03/2016
# Updated: 06/28/2016
# ================================================================ #

global thisdir = pwd()

srand(1)

# ======================================================= #
# Matching Estimates Using Parallel Processing
# ======================================================= #
# Call number of processors
using ClusterManagers
procs = 10
#addprocs(procs)
addprocs_pbs(procs)

# Define "to parallelize process"
require("$thisdir/matchingrun.jl")
B = 10 # number of workers being used
b = 10  # number of work each worker does

Matchboot = pmap(matchingrun, [b, b, b, b, b, b, b, b, b, b])

# Increase the number of "draw" according to the worker number
for i in 2:B
	Matchboot[i][:draw] = Matchboot[i][:draw] .+ (b*(i-1))
	for j in 1:5 # concatenated
	Matchboot[i][parse("draw_$(j)")] = Matchboot[i][parse("draw_$(j)")] .+ (b*(i-1))
	end
end

# Concatenate outputs from all workers
Matchfinal_pre1 = vcat(MatchInitial, Matchboot[1], Matchboot[2], Matchboot[3], Matchboot[4], Matchboot[5], Matchboot[6], Matchboot[7], Matchboot[8], Matchboot[9], Matchboot[10])
Matchfinal =  Machfinal_pre1

# ===================================================== #
# Export to csv
# ===================================================== #
# Define a dictionary for the file outputs to allow for file handles to include locals
ResultOutput = Dict()
colnames = [:rowname, :draw, :ddraw, :epan_ipw, :epan_N]

# open the necessary matrix
n = 0
for gender in genderloop
	for P_switch in (0, 1)
		ResultOutput["matching_$(gender)_P$(P_switch)"] = DataFrame(rowname = [], draw = [], ddraw = [], epan_ipw = [], epan_N = [])

		if n == 0
			ResultOutput["matching_$(gender)_P$(P_switch)"] = Matchfinal[:, colnames]
			delete!(Matchfinal, colnames)
		else
			rename!(Matchfinal, [parse("rowname_$(n)"), parse("draw_$(n)"), parse("ddraw_$(n)"), parse("epan_ipw_$(n)"), parse("epan_N_$(n)")], colnames)
			ResultOutput["matching_$(gender)_P$(P_switch)"] = Matchfinal[:, colnames]
			delete!(Matchfinal, colnames)
		end
		writetable("$(output)/matching/matching_$(gender)_P$(P_switch).csv", ResultOutput["matching_$(gender)_P$(P_switch)"])
		n = n + 1
  end
end
