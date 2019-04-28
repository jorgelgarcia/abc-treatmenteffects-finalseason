# ================================================================ #
# ITT estimation of ABC/CARE Using Parallel Processing
# Author: Jessica Yu Kyung Koh
# Created: 05/03/2016
# Updated: 07/08/2016
# ================================================================ #

global here = pwd()

srand(1)

# ======================================================= #
# ITT Estimates Using Parallel Processing
# ======================================================= #
# Call number of processors
procs = 19
addprocs(procs)

# Define "to parallelize process"
require("$here/bootstrap_matching_progcost.jl")
B = 20 # number of workers being used
b = 1  # number of work each worker does

matchboot = pmap(matchingrun, [b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b])
Matchfinal = Dict()
# Increase the number of "draw" according to the worker number
for gender in genderloop
		println("matchboot check $(matchboot[1])")
	for i in 2:B
		matchboot[i]["$(gender)"][:draw] = matchboot[i]["$(gender)"][:draw] .+ (b*(i-1))
		for j in 1:1 # concatenated
		matchboot[i]["$(gender)"][parse("draw_$(j)")] = matchboot[i]["$(gender)"][parse("draw_$(j)")] .+ (b*(i-1))
		end
	end

	# Concatenate outputs from all workers
	matchfinal_pre1 = vcat(MatchInitial["$(gender)"], matchboot[1]["$(gender)"], matchboot[2]["$(gender)"], matchboot[3]["$(gender)"], matchboot[4]["$(gender)"], matchboot[5]["$(gender)"], matchboot[6]["$(gender)"], matchboot[7]["$(gender)"], matchboot[8]["$(gender)"], matchboot[9]["$(gender)"], matchboot[10]["$(gender)"])
	matchfinal_pre2 = vcat(matchfinal_pre1, matchboot[11]["$(gender)"], matchboot[12]["$(gender)"], matchboot[13]["$(gender)"], matchboot[14]["$(gender)"], matchboot[15]["$(gender)"], matchboot[16]["$(gender)"], matchboot[17]["$(gender)"], matchboot[18]["$(gender)"], matchboot[19]["$(gender)"], matchboot[20]["$(gender)"])
	Matchfinal["$(gender)"] = matchfinal_pre2

	# ===================================================== #
	# Export to csv
	# ===================================================== #
	# Define a dictionary for the file outputs to allow for file handles to include locals
	ResultOutput = Dict()
	colnames = [:rowname, :draw, :ddraw, :epan_ipw, :epan_N]

	# open the necessary matrix
	c = 0
	for P_switch in (0, 1)
		ResultOutput["matching_$(gender)_P$(P_switch)"] = DataFrame(rowname = [], draw = [], ddraw = [], epan_ipw = [], epan_N = [])
		if c == 0
			ResultOutput["matching_$(gender)_P$(P_switch)"] = Matchfinal["$(gender)"][:, colnames]
			delete!(Matchfinal["$(gender)"], colnames)
		else
			rename!(Matchfinal["$(gender)"], [parse("rowname_$(c)"), parse("draw_$(c)"), parse("ddraw_$(c)"), parse("epan_ipw_$(c)"), parse("epan_N_$(c)")], colnames)
			ResultOutput["matching_$(gender)_P$(P_switch)"] = Matchfinal["$(gender)"][:, colnames]
			delete!(Matchfinal["$(gender)"], colnames)
		end
		writetable("$(results)/matching/$(component)_$(gender)_P$(P_switch)$(nm).csv", ResultOutput["matching_$(gender)_P$(P_switch)"])
		c = c + 1
  end
end
