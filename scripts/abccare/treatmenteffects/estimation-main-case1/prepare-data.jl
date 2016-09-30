# ================================================================ #
# Prepare and Clean Data to Run Estimation
# Author: Jessica Yu Kyung Koh
# Updated: 07/08/2016
# ================================================================ #

# ================================================================ #
# Control Set for ABC-CARE, ABC, and CARE
# ================================================================ #
# Declare the control sets, and the number of them you want to test
conDict = Dict()

#conDict["controls_abccare"] = [:male, :hrabc_index, :apgar1, :apgar5, :f_home0y, :grandma_county]
conDict["controls_abccare"] = [:male, :abc, :hrabc_index, :apgar1, :apgar5, :f_home0y, :grandma_county]
conDict["controls_abc"] = [:male, :hrabc_index, :apgar1, :apgar5, :m_teen0y, :hh_sibs0y, :grandma_county]
conDict["controls_care"] = [:male, :apgar1, :m_married0y, :f_home0y, :cohort]

# Declare outcome list for each data
outcome_col = outcomes[:variable]

outcomeDict = Dict()

outcomeDict["outcome_abccare"] = []
for outcome in outcome_col
  if (outcomes[outcomes[:variable] .== outcome, :only_abc] .== 0)[1] & (outcomes[outcomes[:variable] .== outcome, :only_care] .== 0)[1]
    outcomeDict["outcome_abccare"] = append!(outcomeDict["outcome_abccare"], [parse(outcome)])
  end
end

outcomeDict["outcome_abc"] = []
for outcome in outcome_col
  if (outcomes[outcomes[:variable] .== outcome, :only_abc] .== 1)[1]
    outcomeDict["outcome_abc"] = append!(outcomeDict["outcome_abc"], [parse(outcome)])
  end
end

outcomeDict["outcome_care"] = []
for outcome in outcome_col
  if (outcomes[outcomes[:variable] .== outcome, :only_care] .== 1)[1]
    outcomeDict["outcome_care"] = append!(outcomeDict["outcome_care"], [parse(outcome)])
  end
end


# ======================================================= #
# Use a subset of data
# ======================================================= #
# Collect names of the outcomes and put them into an array so that we can use in the estimation
outcome_list = []
for outcome in outcome_col
    outcome_list = append!(outcome_list, [parse(outcome)])
end

# Define the combined controls for all data
controls_all = []
for set in ("abccare", "abc", "care")
  for item in conDict["controls_$(set)"]
    if !in(item, controls_all)
      append!(controls_all, [item])
    end
  end
end

# Collect names of variables needed for IPW estimation
ipw_controls = Dict()
ipw_varlist = []
for col in [:ipw_var, :ipw_pooled1, :ipw_pooled2, :ipw_pooled3]
  ipw_controls["$(col)"] = levels(outcomes[!isna(outcomes[col]), col])
  for item in ipw_controls["$(col)"]
    if !in(parse(item), ipw_varlist)
      ipw_varlist = append!(ipw_varlist, [parse(item)])
    end
  end
end

# Collect names of discretized variables (used in IPW)
discretized = [:m_iq0y, :m_ed0y, :m_age0y, :hrabc_index, :apgar1, :apgar5, :prem_birth, :m_married0y, :m_teen0y, :has_relatives, :male, :f_home0y, :hh_sibs0y]
for item in discretized
  if !in(item, ipw_varlist)
    ipw_varlist = append!(ipw_varlist, [item])
  end
end

# Use a subset of data to reduce the running time
keepvar = [:id, :family, :R, :RV, :Q, :cohort_group1, :cohort_group2, :cohort_group3, :cohort_group4, :cohort_group5, :cohort_group6]
keepvar = append!(keepvar, controls_all)
keepvar = append!(keepvar, outcome_list)
keepvar = append!(keepvar, ipw_varlist)
abccare = abccare[:, keepvar]


# ------------------------------------------ #
# Limit the ABC-CARE data and fix weird ID's #
# ------------------------------------------ #
abccare = abccare[abccare[:id] .!= 64, :]
abccare = abccare[!((abccare[:RV] .== 1) & (abccare[:R] .== 0)), :]

# ---------------------------------------------------- #
# Correcting weird variables (Unique Problem to Julia) #
# ---------------------------------------------------- #
# ABCCARE data has a lot of values like ".a", ".b", and so on. Since Julia does not recognize these as missing values, we need to convert this to missing values (NA)
for var in keepvar
    println("variable: $(var)")
    occurrence = 0  # To convert a column with occurrence > 0 from string to integer (shown below)
    for alphabet in ['a':'z']
     if in(string(".",alphabet), abccare[!isna(abccare[var]), var])
        occurrence = occurrence + 1
      end
      abccare[abccare[var] .== string(".",alphabet), var] = NA
    end

    if var == :hct_phy12y
      println("Printing for hct_phy12y")
      println("$(abccare[:,[:hct_phy12y,:hct_cog12y]])")
    end

  # Variables that originally contained ".a"&& etc. are saved as string. Now we need to convert string to integers. I could not find destring command for Julia. To be updated later.
   if occurrence > 0 # If a column contains ".a" etc.
    # Create a new column (to be deleted later) that will be filled in with integer values for string column.
   abccare[:var_new] = 0.0
    # Now run the loop over each row
      for i in 1:length(abccare[var])
        if !isna(abccare[i,var])
          abccare[i,:var_new] = parse(Float64, abccare[i,var])
        else
          abccare[i,:var_new] = NA
        end
      end
    # Now delete the old (string) column and rename the new column to old column
      delete!(abccare, var)
      rename!(abccare, :var_new, var)
  end
end

abccare[isna(abccare[:id]), :id] = 9999

# -------------------------------------------------------------------------------- #
# Convert discrete variables to binary (= 1 if greater than median, = 0 otherwise) #
# -------------------------------------------------------------------------------- #
global discretized = ["m_iq0y", "m_ed0y", "m_age0y", "hrabc_index", "apgar1", "apgar5", "prem_birth", "m_married0y", "m_teen0y", "has_relatives", "male", "f_home0y", "hh_sibs0y"]

for dvar in discretized
  dvar_p = parse(dvar) # Making "d_var" to :d_var
  med_d = median(abccare[!isna(abccare[dvar_p]), dvar_p]) # take the median of the non-missing values for each variables
  abccare[parse("$(dvar)_dum")] = 0 # Generate a new column for dummy
  abccare[abccare[dvar_p] .> med_d, parse("$(dvar)_dum")] = 1 # Replace dummy column to one if d_var is greater than the median
  abccare[isna(abccare[dvar_p]), parse("$(dvar)_dum")] = NA # Replace values of dunny column if corresponding rwo in original column is NA
end


# ----------------------------------------------- #
# Generate the P variable (Q/60) <= 0.2 ==> P = 0 #
# ----------------------------------------------- #
abccare[:Qthres] = abccare[:Q] ./ 60
abccare[:P] = 1(abccare[:Qthres] .> 0.2)

# ------------------------------- #
# Define ABC, CARE, ABC-CARE data #
# ------------------------------- #
abccare_data = abccare

abc_data = abccare
abc_data = abc_data[abc_data[:abc] .== 1, :]

care_data = abccare
care_data = care_data[care_data[:abc] .== 0, :]
