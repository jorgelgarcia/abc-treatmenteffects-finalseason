# ======================================================================== #
# Driver file for Income Julia
# Author: Jessica Yu Kyung Koh
# Created: 07/07/2016
# Edited: 07/07/2016
# ======================================================================== #
# set up number of bootstraps and controls
global itt = 0			# matching estimator is the default
global breps = 74 		# remember to subtract 1, i.e. 50 becomes 49
global areps = 2 	# remember to subtract 1, i.e. 50 becomes 49
global controls = [:hrabc_index, :apgar1, :apgar5, :hh_sibs0y, :grandma_county, :has_relatives, :male]
global ipwvars_all = [:m_iq0y, :m_ed0y, :m_age0y, :hrabc_index, :p_inc0y, :apgar1, :apgar5, :prem_birth, :m_married0y, :m_teen0y, :f_home0y, :hh_sibs0y, :cohort, :m_work0y, :has_relatives]
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
