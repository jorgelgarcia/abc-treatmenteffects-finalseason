# ======================================================================== #
# Prepare data before running estimates on Income
# Original Code in STATA written by Joshua Shea
# Translator: Jessica Yu Kyung Koh
# Date: 07/07/2016
# ======================================================================== #

# Collect variable names to estimate effects for
outcomes = readtable("$(base)/analysis/health/code/$(component)/outcomes.csv")
outcomes_col = outcomes[:variable]

# Collect names of the outcomes and put them into an array so that we can use in the estimation
outcomelist = []
for outcome in outcomes_col
    outcomelist = append!(outcomelist, [parse(outcome)])
end


# Bring in USC projections
fammerge = readtable("$(abc)/abc-fam-merge.csv")

# Drop home-visit only kids
fammerge  = fammerge[!((fammerge[:R] .== 0) & (fammerge[:RV] .== 1)), :]

# for var in keepvar
for var in [:id, :R, :P]
    println("variable: $(var)")
    occurrence = 0  # To convert a column with occurrence > 0 from string to integer (shown below)
    for alphabet in ['a':'z']
     if in(string(".",alphabet), abccare[!isna(fammerge[var]), var])
        occurrence = occurrence + 1
      end
      fammerge[fammerge[var] .== string(".",alphabet), var] = NA
    end

  # Variables that originally contained ".a"&& etc. are saved as string. Now we need to convert string to integers. I could not find destring command for Julia. To be updated later.
   if occurrence > 0 # If a column contains ".a" etc.
    # Create a new column (to be deleted later) that will be filled in with integer values for string column.
   fammerge[:var_new] = 0
    # Now run the loop over each row
      for i in 1:length(fammerge[var])
        if !isna(fammerge[i,var])
          fammerge[i,:var_new] = parse(Float64, fammerge[i,var])
        else
          fammerge[i,:var_new] = NA
        end
      end
    # Now delete the old (string) column and rename the new column to old column
      delete!(fammerge, var)
      rename!(fammerge, :var_new, var)
  end
end

fammerge[isna(fammerge[:id]), :id] = 9999


# Deal with deaths
if deaths == 1

  # Define a dictionary for age if death for each id
  idage = Dict()
	idage["id74age"]	= 0
	idage["id9999age"]	= 0
	idage["id914age"]	= 1
	idage["id99age"] = 4
	idage["id909age"]	= 30
	idage["id87age"]	= 29
	idage["id920age"] = 38
	idage["id951age"] = 37
	idage["id117age"] = 38
	idage["id947age"] = 38
	idage["id943age"] = 40

	for id_n in [74, 9999, 914, 99, 909, 87, 920, 951, 117, 947, 943]

		for age in [8:79]
			if age > idage["id$(id_n)age"]
				println("Dealing with deaths: $(id_n) at age $(age)")
        fammerge[fammerge[:id] .== id_n, parse("health_private_surv$(age)")] = 0
        fammerge[fammerge[:id] .== id_n, parse("health_public_surv$(age)")] = 0
      end
    end

    for age in [30:79]
			if age > idage["id$(id_n)age"]
				println("Dealing with deaths: $(id_n) at age $(age)")
        fammerge[fammerge[:id] .== id_n, parse("diclaim_surv$(age)")] = 0
        fammerge[fammerge[:id] .== id_n, parse("ssiclaim_surv$(age)")] = 0
        fammerge[fammerge[:id] .== id_n, parse("ssclaim_surv$(age)")] = 0
        fammerge[fammerge[:id] .== id_n, parse("qaly_surv$(age)")] = 0
      end
    end
	end
end

# Drop id 64
fammerge = fammerge[!(fammerge[:id] .== 64), :]

# Convert discrete variables to binary (= 1 if greater than median, = 0 otherwise)
global discretized = ["m_iq0y", "m_ed0y", "m_age0y", "hrabc_index", "apgar1", "apgar5", "prem_birth", "m_married0y", "m_teen0y", "male", "f_home0y", "hh_sibs0y"]

for dvar in discretized
  dvar_p = parse(dvar) # Making "d_var" to :d_var
  med_d = median(fammerge[!isna(fammerge[dvar_p]), dvar_p]) # take the median of the non-missing values for each variables
  fammerge[parse("$(dvar)_dum")] = 0 # Generate a new column for dummy
  fammerge[fammerge[dvar_p] .> med_d, parse("$(dvar)_dum")] = 1 # Replace dummy column to one if d_var is greater than the median
  fammerge[isna(fammerge[dvar_p]), parse("$(dvar)_dum")] = NA # Replace values of dunny column if corresponding rwo in original column is NA
end
