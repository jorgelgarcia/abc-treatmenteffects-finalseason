# ================================================================ #
# Function to Form Linear-Probability IPW Weights
# Author: Jessica Yu Kyung Koh
# Created: 05/13/2016
# Updated: 05/31/2016
# ================================================================ #

function IPWweight(sampledata, outcomes, outcomel)
  # ----------- #
  # Preparation #
  # ----------- #
  # Define columns
    outcome_col = outcomes[:variable]
    ipw_var_col = outcomes[:ipw_var]

  # -------------------- #
  # Generate IPW Weights #
  # -------------------- #
    for var in outcomel
        # ------------------------------------------------------- #
        # Now loop over variables that need IPWs and form weights #
        # ------------------------------------------------------- #
          if (!isna(outcomes[(outcome_col .== "$(var)"), [:ipw_var]][1,1])) & (in(var, names(sampledata)))

          # Collect the list of IPW column variables (only for ABC-CARE variables)
           IPW_cols = outcomes[(outcome_col .== "$(var)"), [:ipw_var, :ipw_pooled1, :ipw_pooled2, :ipw_pooled3]]
           IPW_list = [IPW_cols[1,1], IPW_cols[1,2], IPW_cols[1,3], IPW_cols[1,4]]   # This is the list of the IPW column variables

          # Switch out variables for discretized ones if necessary
            new_IPW_list = []
            for i in 1:4
              if in(IPW_list[i], discretized)
                new_IPW_list = append!(new_IPW_list, [string(IPW_list[i],"_dum")])
              else
                new_IPW_list = append!(new_IPW_list, [IPW_list[i]])
              end
            end

          # Form columns for attrition indicator (NOT attrited => 1, Attrited => 0)
            sampledata[:attr] = 1(!isna(sampledata[var])) # putting "1" in front of the parentheses assigns "1" if the statement is true and "0" otherwise
            sampledata[:attr_treat] = sampledata[:attr] .* sampledata[:R] # R = 1 if treated, = 0 if control
            sampledata[:attr_control] = sampledata[:attr] .* (1-sampledata[:R])

          # Form group indicator for combinations of values across columns
            # Create a column for group index. To be filled out later
              sampledata[:group_index] = 0
              group_ipw = groupby(sampledata, [parse(new_IPW_list[2]), parse(new_IPW_list[3]), parse(new_IPW_list[4])])    # "groupby" groups same cases of combination of column values.
              group_ipw_num = length(group_ipw)
            # Fill out group_index column
              for i in 1:group_ipw_num
                group_ipw[i][:group_index] = i
              end

            # Replace group_index to NA if at least one of new_IPW_list item is NA
              for i in 1:size(sampledata)[1]
                  if isna(sampledata[i,parse(new_IPW_list[2])]) || isna(sampledata[i,parse(new_IPW_list[3])]) || isna(sampledata[i,parse(new_IPW_list[4])])
                    sampledata[i,:group_index] = NA
                  end
              end
            # Create pooled data array from group_index column (A pooled data array goes into glm as dummies for a categorical variable.)
              group_list = [:group_index]
              group_level = levels(sampledata[!isna(sampledata[:group_index]), :group_index])

              for value in group_level
                sampledata[parse("group_$(value)")] = 1(sampledata[:group_index] .== value)
                append!(group_list, [parse("group_$(value)")])
              end

              println("group_level: $(group_level)")
              println("group_list: $(group_list)")
              g_min = minimum(group_level)
              deleteat!(group_list, findin(group_list, [parse("group_$(g_min)")]))
              deleteat!(group_list, findin(group_list, [:group_index]))

          # --------------------------------------------------------------- #
          # Perform linear probability model for treated (Preparation step) #
          # --------------------------------------------------------------- #
            IPW_treat_fml = Formula(:attr_treat, Expr(:call, :+, group_list...))
            try # try/catch structure handles exceptions
              lm(IPW_treat_fml, sampledata)
            # If the regression fails
            catch err
              continue
            end

            # If there is no error in regression, store the regression results into IPW_treat_reg
            IPW_treat_reg = lm(IPW_treat_fml, sampledata)

          # Create weights for the treated according to the IPW formula in the Science paper (Appendix p.23)
            sampledata[:Wt] = 0.0
            sampledata[:Wt] = predict(IPW_treat_reg, sampledata)
            sampledata[sampledata[:Wt] .< 0, :Wt] = 0
            sampledata[:Wt] = 1./sampledata[:Wt]
            sampledata[sampledata[:Wt] .> 20, :Wt] = 20   # If the Wt inverse is too huge, set the value as 20 (this is arbitrary).
            sampledata[:sum_Att_t] = sum(!isna(sampledata[:Wt]) .* sampledata[:R] .* sampledata[:attr])
            notmiss_Wt = !isna(sampledata[:Wt])
            sampledata[:sum_Wt_Att_t] = sum(sampledata[(notmiss_Wt) & (sampledata[:R] .== 1) & (sampledata[:attr] .== 1), :Wt])        # sampledata[:sum_Wt_Att_t] = sum(sampledata[notmiss_Wt,:Wt] .* sampledata[notmiss_Wt,:R] .* sampledata[notmiss_Wt, :attr])  <= This does not work
            sampledata[:Wt] = sampledata[:Wt] .* sampledata[:sum_Att_t] ./ sampledata[:sum_Wt_Att_t] # CHECK
            sampledata[isna(sampledata[:Wt]), :Wt] = 1

            # --------------------------------------------------------------- #
            # Perform linear probability model for control (Preparation step) #
            # --------------------------------------------------------------- #
            IPW_ctrl_fml = Formula(:attr_control, Expr(:call, :+, group_list...))
            try # try/catch structure handles exceptions
              lm(IPW_ctrl_fml, sampledata)
            # If the regression fails
            catch err
              continue
            end

          # If there is no error in regression, store the regression results into IPW_ctrl_reg
            IPW_ctrl_reg = lm(IPW_ctrl_fml, sampledata)

          # Create weights for the controls according to the IPW formula in the Science paper (Appendix p.23)
            sampledata[:Wc] = 0.0
            sampledata[:Wc] = predict(IPW_ctrl_reg, sampledata)
            sampledata[sampledata[:Wc] .< 0, :Wc] = 0
            sampledata[:Wc] = 1./sampledata[:Wc]
            sampledata[sampledata[:Wc] .> 20, :Wc] = 20   # If the Wt inverse is too huge, set the value as 20 (this is arbitrary).
            sampledata[:sum_Att_c] = sum(!isna(sampledata[:Wc]) .* (1 .- sampledata[:R]) .* sampledata[:attr])
            notmiss_Wc = !isna(sampledata[:Wc])
            sampledata[:sum_Wc_Att_c] = sum(sampledata[(notmiss_Wc) & (sampledata[:R] .== 0) & (sampledata[:attr] .== 1), :Wc])     # sampledata[:sum_Wc_Att_c] = sum(sampledata[notmiss_Wc,:Wc] .* (1 .- sampledata[notmiss_Wc,:R]) .* sampledata[notmiss_Wc, :attr])
            sampledata[:Wc] = sampledata[:Wc] .* sampledata[:sum_Att_c] ./ sampledata[:sum_Wc_Att_c]
            sampledata[isna(sampledata[:Wc]), :Wc] = 1

            # ---------------------------------------- #
            # Now generate the IPW weight (Final step) #
            # ---------------------------------------- #
            sampledata[parse("ipw_$(var)")] = (sampledata[:R] .* sampledata[:Wt]) .+ ((1 .- sampledata[:R]) .* sampledata[:Wc])
            delete!(sampledata, [:attr, :attr_treat, :attr_control, :Wt, :Wc, :sum_Att_t, :sum_Att_c, :sum_Wt_Att_t, :sum_Wc_Att_c])
            for level in group_list
              delete!(sampledata, [level])
            end
        end
    end
    return sampledata
end
