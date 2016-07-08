# ======================================================================== #
# Prepare data before running estimates on Income
# Original Code in STATA written by Joshua Shea
# Translator: Jessica Yu Kyung Koh
# Date: 07/07/2016
# ======================================================================== #

# Collect variable names to estimate effects for
outcomes = readtable("$(base)/outcomes/outcomes_cba.csv")
outcomes_col = outcomes[:variable]

# Collect names of the outcomes and put them into an array so that we can use in the estimation
outcomelist = []
for outcome in outcomes_col
    outcomelist = append!(outcomelist, [parse(outcome)])
end


# ======================================================================- #

# ----------------------- #
# Bring in pooled results #
# ----------------------- #
labor_proj_p = readtable("$results/projections/labor_proj_pooled.csv")

# Rename column names to have them start with "c"
colnames = names(labor_proj_p)
colnames = deleteat!(colnames, findin(colnames, [:id]))
colnames = deleteat!(colnames, findin(colnames, [:adraw]))
for col in colnames
  newcol = split("$(col)", x)[2]
	rename!(labor_proj_f, col, parse("c$(newcol)_pooled"))
end

# Define "projection" data to merge in gender-specific projections
projections = labor_proj_p

# --------------------- #
# Bring in male results #
# --------------------- #
labor_proj_m = readtable("$results/projections/labor_proj_male.csv")

colnames = names(labor_proj_m)
colnames = deleteat!(colnames, findin(colnames, [:id]))
colnames = deleteat!(colnames, findin(colnames, [:adraw]))
for col in colnames
  newcol = split("$(col)", x)[2]
	rename!(labor_proj_f, col, parse("c$(newcol)_male"))
end

# Merge 1:1 id adraw using `projections', nogen
projections = join(projections, labor_proj_m, on = [:id, :adraw], kind = :outer)

# ----------------------- #
# Bring in female results #
# ----------------------- #
labor_proj_f = readtable("$results/projections/labor_proj_female.csv")

colnames = names(labor_proj_f)
colnames = deleteat!(colnames, findin(colnames, [:id]))
colnames = deleteat!(colnames, findin(colnames, [:adraw]))
for col in colnames
  newcol = split("$(col)", x)[2]
	rename!(labor_proj_f, col, parse("c$(newcol)_female"))
end

# Merge 1:1 id adraw using `projections', nogen
projections = join(projections, labor_proj_f, on = [:id, :adraw], kind = :outer)


# ------------------------------------------------------------------------------ #
# ----------------------------- #
# Merge in age 21 and 30 income #
# ----------------------------- #
abccare = readtable("$data/append-abccare_iv.csv")

# Drop home-visit only kids
abccare = abccare[!((abccare[:R] .== 0) & (abccare[:RV] .== 1)), :]

# Keep only the variables we need for income
keepvar = [:id, :R, :P, :family, :male, :si21y_inc_labor, :si30y_inc_labor]
keepvar = append!(keepvar, controls)
keepvar = append!(keepvar, ipwvars_all)
abccare = abccare[:, keepvar]
abccare[isna(abccare[:id]), :id] = 9999

abccare = join(abccare, projections, on = [:id], kind = :outer)

# Organize data
rename!(abccare, :si21y_inc_labor, :c21)
rename!(abccare, :si30y_inc_labor, :c30)
sort(abccare, cols = [:adraw, :id])

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
    mean_male = mean(abccare[abccare[:id] .== id_n, :male])
		if mean_male == 1
      sex = :male
		elseif mean_male == 0
      sex = :female
    end

		for age in [21:67]
			if age > idage["id$(id_n)age"]
				if (age == 21) | (age == 30)
					println("Dealing with deaths: $(id_n) at age $(age)")
          abccare[abccare[:id] .== id_n, parse("c$(age)")] = 0
				else
				  println("Dealing with deaths: $(id_n) at age $(age)")
          abccare[abccare[:id] .== id_n, parse("c$(age)_$(sex)")] = 0
          abccare[abccare[:id] .== id_n, parse("c$(age)_pooled")] = 0
				end
			end
		end
	end
end
