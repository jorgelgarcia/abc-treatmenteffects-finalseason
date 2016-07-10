# ======================================================================== #
# Driver file for Income Julia
# Author: Jessica Yu Kyung Koh
# Created: 07/07/2016
# Edited: 07/07/2016
# ======================================================================== #
# set up number of bootstraps and controls
global itt = 0			# matching estimator is the default
global breps = 74 		# remember to subtract 1, i.e. 50 becomes 49
global areps = 3 	# remember to subtract 1, i.e. 50 becomes 49
global controls = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male]
global ipwvars_all = [:apgar1, :apgar5, :prem_birth]
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
