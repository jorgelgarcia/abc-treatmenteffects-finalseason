# ======================================================================== #
# Prepare data before running estimates on Income
# Original Code in STATA written by Joshua Shea
# Translator: Jessica Yu Kyung Koh
# Date: 07/07/2016
# ======================================================================== #

# Collect variable names to estimate effects for
outcomes = readtable("$(base)/$(component)/outcomes.csv")
outcomes_col = outcomes[:variable]

# Collect names of the outcomes and put them into an array so that we can use in the estimation
outcomelist = []
for outcome in outcomes_col
    outcomelist = append!(outcomelist, [parse(outcome)])
end

# Bring in USC projections
outcomesate = readtable("$(data)/outcomes_ate.csv")

# Drop id 64
outcomesate = outcomesate[!(outcomesate[:id] .== 64), :]

# Drop home-visit only kids
outcomesate  = outcomesate[!((outcomesate[:R] .== 0) & (outcomesate[:RV] .== 1)), :]

# for var in keepvar
for var in [:id, :R, :P]
    println("variable: $(var)")
    occurrence = 0  # To convert a column with occurrence > 0 from string to integer (shown below)
    for alphabet in ['a':'z']
     if in(string(".",alphabet), outcomesate[!isna(outcomesate[var]), var])
        occurrence = occurrence + 1
      end
      outcomesate[outcomesate[var] .== string(".",alphabet), var] = NA
    end

  # Variables that originally contained ".a"&& etc. are saved as string. Now we need to convert string to integers. I could not find destring command for Julia. To be updated later.
   if occurrence > 0 # If a column contains ".a" etc.
    # Create a new column (to be deleted later) that will be filled in with integer values for string column.
   outcomesate[:var_new] = 0
    # Now run the loop over each row
      for i in 1:length(outcomesate[var])
        if !isna(outcomesate[i,var])
          outcomesate[i,:var_new] = parse(Float64, outcomesate[i,var])
        else
          outcomesate[i,:var_new] = NA
        end
      end
    # Now delete the old (string) column and rename the new column to old column
      delete!(outcomesate, var)
      rename!(outcomesate, :var_new, var)
  end
end

outcomesate[isna(outcomesate[:id]), :id] = 9999


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

		for age in [0:5]
			if age > idage["id$(id_n)age"]
				println("Dealing with deaths CC: $(id_n) at age $(age)")
        outcomesate[outcomesate[:id] .== id_n, parse("cccostprivate$(age)")] = 0
        outcomesate[outcomesate[:id] .== id_n, parse("cccostpublic$(age)")] = 0
      end
    end

    for age in [0:26]
			if age > idage["id$(id_n)age"]
				println("Dealing with deaths EDU-PROG: $(id_n) at age $(age)")
        outcomesate[outcomesate[:id] .== id_n, parse("educost$(age)")] = 0
        outcomesate[outcomesate[:id] .== id_n, parse("progcost$(age)")] = 0
      end
    end

    for age in [6:50]
      if age > idage["id$(id_n)age"]
        println("Dealing with deaths CRIME: $(id_n) at age $(age)")
        outcomesate[outcomesate[:id] .== id_n, parse("private_crime$(age)")] = 0
        outcomesate[outcomesate[:id] .== id_n, parse("public_crime$(age)")] = 0
      end
    end
	end
end

global discretized = [:m_iq0y, :m_ed0y, :m_age0y, :hrabc_index, :p_inc0y, :apgar1, :apgar5, :prem_birth, :m_married0y, :m_teen0y, :f_home0y, :hh_sibs0y, :cohort, :m_work0y]

# Convert discrete variables to binary (= 1 if greater than median, = 0 otherwise)
for dvar in discretized
  println("Discretizing $(dvar)")
  med_d = median(outcomesate[!isna(outcomesate[dvar]), dvar]) # take the median of the non-missing values for each variables
  outcomesate[parse("$(dvar)_dum")] = 0 # Generate a new column for dummy
  outcomesate[outcomesate[dvar] .> med_d, parse("$(dvar)_dum")] = 1 # Replace dummy column to one if d_var is greater than the median
  outcomesate[isna(outcomesate[dvar]), parse("$(dvar)_dum")] = NA # Replace values of dunny column if corresponding rwo in original column is NA
end
