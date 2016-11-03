# ============================================================================ #
# Factor Analysis for ABC-CARE Treatment Effects
# Author: Joshua Shea
# Translator: Jessica Yu Kyung Koh
# Date: 10/03/2016
# ============================================================================ #

# ================================================================ #
# Create list of factor items for each category using a dictionary #
# ================================================================ #
function factors(datatouse)

	factors = Dict()

	factors["factor_iq5y"] = [:iq2y, :iq3y, :iq3y6m, :iq4y, :iq4y6m, :iq5y]
	factors["factor_iq12y"] = [:iq7y, :iq8y, :iq12y]
	factors["factor_iq21y"] = [:iq15y, :iq21y]
	factors["factor_ach12y"] = [:ach5y6m, :ach6y, :ach6y6m, :ach7y, :ach7y6m, :ach8y, :ach8y6m]
	factors["factor_ach21y"] = [:ach15y, :ach21y]
	factors["factor_home"] = [:home0y6m, :home1y6m, :home2y6m, :home3y6m, :home4y6m ,:home8y]
	factors["factor_pinc"] = [:p_inc1y6m, :p_inc2y6m, :p_inc3y6m, :p_inc4y6m, :p_inc8y, :p_inc12y, :p_inc15y, :p_inc21y]
	factors["factor_mwork"] = [:m_work1y6m, :m_work2y6m, :m_work3y6m, :m_work4y6m, :m_work21y]
	# factors["factor_meduc"] = [:mb_ed1y6m, :mb_ed2y6m, :mb_ed3y6m, :mb_ed4y6m, :mb_ed8y]
	factors["factor_fhome"] = [:f_home1y6m, :f_home2y6m, :f_home3y6m, :f_home4y6m, :f_home8y]
	factors["factor_educ"] = [:sch_hs30y, :si30y_techcc_att, :si30y_univ_comp, :years_30y, :inv_ever_sped, :inv_tot_sped, :inv_ever_ret, :inv_tot_ret]
	factors["factor_emp"] = [:si30y_works_job, :si21y_inc_labor, :si30y_inc_labor, :inv_si21y_inc_trans_pub, :inv_si30y_inc_trans_pub]
	factors["factor_crime"] = [:ad34_fel, :ad34_mis, :si30y_adlt_totinc]
	factors["factor_tad"] = [:si30y_cig_num, :drink_days, :drink_binge_days, :si34y_drugs]
	factors["factor_shealth"] = [:si30y_subj_health, :si34y_subj_health]
	factors["factor_hyper"] = [:si34y_sys_bp, :si34y_dia_bp, :si34y_prehyper, :si34y_hyper]
	factors["factor_chol"] = [:inv_si34y_chol_hdl, :si34y_dyslipid]
	factors["factor_diabetes"] = [:si34y_hemoglobin, :si34y_prediab, :si34y_diab]
	factors["factor_obese"] = [:si34y_bmi, :si34y_obese, :si34y_sev_obese, :si34y_whr, :si34y_obese_whr, :si34y_fram_p1]
	factors["factor_bsi"] = [:bsi_tsom, :BSISom_T, :bsi_tdep, :BSIDep_T, :bsi_tanx, :BSIAnx_T, :bsi_thos, :BSIHos_T, :bsi_tgsi, :B18GSI_T]


	# ================ #
	# Data preparation #
	# ================ #
	# Flip signs of some variables
	flip_variables = [:si34y_chol_hdl, :si21y_inc_trans_pub, :si30y_inc_trans_pub, :ever_sped, :tot_sped, :ever_ret, :tot_ret]
	for var in flip_variables
		datatouse[parse("inv_$(var)")] = datatouse[var] .* -1
	end

	# Create a list of all categories
	categories = [:iq5y, :iq12y, :iq21y, :ach12y, :ach21y, :home, :pinc, :mwork, :fhome, :educ, :emp, :crime, :tad, :shealth, :hyper, :chol, :diabetes, :obese, :bsi]

	# Determine if we need to deal with ABC
	if size(datatouse[datatouse[:abc] .== 1, :], 1) > 0
	   abcfactor = 1
	else
	   abcfactor = 0
	end

	# Determine if we need to deal with CARE
	if size(datatouse[datatouse[:abc] .== 0, :], 1) > 0
	   carefactor = 1
	else
	   carefactor = 0
	end

	# Update locals if CARE is part of the sample
	if carefactor == 1
		factor_pinc = [:p_inc1y6m, :p_inc2y6m, :p_inc3y6m, :p_inc4y6m]
		factor_achv12 = [:ach5y6m, :ach6y, :ach6y6m, :ach7y, :ach7y6m, :ach8y, :ach8y6m]
	end

	# ============== #
	# Create factors #
	# ============== #
	factordata = Dict()

	for cat in categories
		newcatlocal = []
		for var in factors["factor_$(cat)"]

			# Create a category local list if it is only ABC or only CARE
			if ((carefactor == 0) & (abcfactor == 1)) | ((carefactor == 1) & (abcfactor == 0))
				if datatouse[!isna(datatouse[var]), var] != 0
					newcatlocal = push!(newcatlocal, var)
				end
			end

			# Create a category local list if it is both ABC and CARE
			if ((carefactor == 1) & (abcfactor == 1))
				acount = length(datatouse[(!isna(datatouse[var])) & (datatouse[:abc] .== 1), var])
				ccount = length(datatouse[(!isna(datatouse[var])) & (datatouse[:abc] .== 0), var])
				if ((acount != 0) & (ccount != 0))
					newcatlocal = push!(newcatlocal, var)
				end
			end
	  end

		keepvar = [:id]
		keepvar = append!(keepvar, newcatlocal)
		keepvar = deleteat!(keepvar, findin(keepvar, [:id]))

		factordata["factor_$(cat)"] = datatouse[:, keepvar]

	# Calculate the number of factors using a defined function
		factor_switch = 1
		try
			diagonalfac(datatouse, factordata["factor_$(cat)"], 1)
		catch err
			factor_switch = 0
		end

		if factor_switch == 1
			datatouse = diagonalfac(datatouse, factordata["factor_$(cat)"], 1)
	    rename!(datatouse, :factor, parse("factor_$(cat)"))
		end
	end

	return datatouse
end
