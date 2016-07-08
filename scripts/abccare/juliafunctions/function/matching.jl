# ================================================================ #
# Function to Perform Matching
# Author: Jessica Yu Kyung Koh
# Created: 05/30/2016
# Edited: 06/30/2016
# ================================================================ #

function mestimate(sampledata, outcomes, outcome_list, controls, draw, ddraw, bootsample, bygender)

  # ----------- #
  # Preparation #
  # ----------- #
  # Define matchinggender
  if bygender == 1
    mgender = ["pooled", "male", "female"]
  elseif bygender == 0
    mgender = ["pooled"]
  end

  # Define outMat that will store the results
  outMat = Dict()

  # Define matching data
  matchingdata = sampledata

  # Bootstrap resample if necessary
  if bootsample == "yes"
    if ddraw != 0
      matchingdata = bsample(matchingdata, :male, :family)
    end
  end

  # Generate IPW weight for the bootstrapped sample
  matchingdata = IPWweight(matchingdata, outcomes, outcome_list)

  # Generate Epanechnikov weight for the bootstrapped sampledata (Epanechnikov might fail, so we need to capture that)
  success = 1
  try
    matchingdata = epanechnikov(matchingdata, controls, 20)
  catch error
    success = 0
    global append_switch = 0
  end

  # if Epanechnikov succeeds
  if success == 1

    # ----------------------------------- #
    # Define sample for each gender group #
    # ----------------------------------- #
    subdata = Dict()

    for gender in mgender

      if gender == "male"
        subdata["$(gender)"] = matchingdata[matchingdata[:male] .== 1, :]
        controls = deleteat!(controls, findin(controls, [:male]))    # Julia does not automatically drop male
      elseif gender == "female"
        subdata["$(gender)"] = matchingdata[matchingdata[:male] .== 0, :]
        controls = deleteat!(controls, findin(controls, [:male]))
      elseif gender == "pooled"
        subdata["$(gender)"] = matchingdata
      end
      gender = parse(gender)


      # ------------------------------ #
     # Define sample for each p group #
     # ------------------------------ #
      for p in (0, 1)

        if p == 1
          predata = subdata["$(gender)"][!isna(subdata["$(gender)"][:P]), :]
          usedata = predata[(predata[:P] .== 1) | (predata[:R] .== 1), :]
        elseif p == 0
          predata = subdata["$(gender)"][!isna(subdata["$(gender)"][:P]), :]
          usedata = predata[(predata[:P] .== 0) | (predata[:R] .== 1), :]
        end

        outMat["matching_$(gender)_P$(p)"] = DataFrame(rowname = [], draw = [], ddraw = [],
                              epan_ipw = [], epan_N = [])

        # ------------------ #
        # Perform estimation #
        # ------------------ #
        for y in outcome_list

          # Restrict the estimates to those who we can actually estimate effects
          fml = Formula(y, Expr(:call, :+, :R, controls...))
          try
            lm(fml, usedata)
          catch err
            push!(outMat["matching_$(gender)_P$(p)"], [y, draw, ddraw, NA, NA])
            continue
          end

          # Determine who is in treatment and who is in control
          cond_treat = (usedata[:R] .== 1)
          cond_control = (usedata[:R] .== 0)

          for id in usedata[:id]
            usedata[parse("ie_$(y)_$(id)")] = 0.0    # generate column for Epanechnikov*IPW

            if in(parse("ipw_$(y)"), names(usedata)) & in(parse("epa_$(id)"), names(usedata))
              usedata[parse("ie_$(y)_$(id)")] = usedata[parse("ipw_$(y)")] .* usedata[parse("epa_$(id)")]
            elseif !in(parse("ipw_$(y)"), names(usedata)) & in(parse("epa_$(id)"), names(usedata))
              usedata[parse("ie_$(y)_$(id)")] = usedata[parse("epa_$(id)")]
            elseif !in(parse("epa_$(id)"), names(usedata))
              usedata = delete!(usedata, parse("ie_$(y)_$(id)"))
            end
          end

          # Do not match treated with P = 1 to control with P = 0
          for id in usedata[(usedata[:R] .== 0) & (usedata[:P] .== 0), :id]
            if in(parse("ie_$(y)_$(id)"), names(usedata))
              usedata[(usedata[:R] .== 1) & (usedata[:P] .== 1), parse("ie_$(y)_$(id)")] = NA
            end
          end
          # Do not match control with P = 0 to treated with P = 1
          for id in usedata[(usedata[:R] .== 1) & (usedata[:P] .== 1), :id]
            if in(parse("ie_$(y)_$(id)"), names(usedata))
              usedata[(usedata[:R] .== 0) & (usedata[:P] .== 0), parse("ie_$(y)_$(id)")] = NA
            end
          end

          # Declare counterfactuals and fill in values
          usedata[:counter0] = 0.0
          usedata[:counter1] = 0.0

          usedata[usedata[:R] .== 0, :counter0] = usedata[usedata[:R] .== 0, y]
          usedata[usedata[:R] .== 1, :counter0] = NA
          usedata[usedata[:R] .== 1, :counter1] = usedata[usedata[:R] .== 1, y]
          usedata[usedata[:R] .== 0, :counter1] = NA

          for id in usedata[:id]
            if in(parse("ie_$(y)_$(id)"), names(usedata))
              x = usedata[(!isna(usedata[parse("$(y)")])) & (!isna(usedata[parse("ie_$(y)_$(id)")])), parse("$(y)")]
              w = usedata[(!isna(usedata[parse("$(y)")])) & (!isna(usedata[parse("ie_$(y)_$(id)")])), parse("ie_$(y)_$(id)")]
              mean_yw = mean(x, weights(Array(w)))

              if usedata[(usedata[:id] .== id), :R][1,1] == 1
                usedata[(usedata[:id] .== id), :counter0] = mean_yw
              elseif usedata[(usedata[:id] .== id), :R][1,1] == 0
                usedata[(usedata[:id] .== id), :counter1] = mean_yw
              end
            end
          end

          # Estimate treatment effects
          usedata[:TE] = 0.0
          usedata[:TE] = usedata[:counter1] .- usedata[:counter0]

          if in(parse("ipw_$(y)"), names(usedata))
             mean_te = mean(usedata[(!isna(usedata[:TE])) & (!isnan(usedata[:TE])), :TE],  weights(Array(usedata[!isna(usedata[:TE]) & (!isnan(usedata[:TE])), parse("ipw_$(y)")])))
             N = length(usedata[!isna(usedata[:TE]) & (!isnan(usedata[:TE])), :TE])
          else
            mean_te = mean(usedata[!isna(usedata[:TE]) & (!isnan(usedata[:TE])), :TE])
            N = length(usedata[!isna(usedata[:TE]) & (!isnan(usedata[:TE])), :TE])
          end

          # Store estimation results for R (randomization into treatment in ABC) into the output_ITT matrix. push! adds a row to the matrix output_ITT.
          push!(outMat["matching_$(gender)_P$(p)"], [y, draw, ddraw, mean_te, N])
        end
          println("Bootstrap draw $(draw) - $(ddraw) - $(gender) - $(p) Success!")
      end
    end

    if bygender == 1
      Output = hcat(outMat["matching_male_P0"], outMat["matching_male_P1"], outMat["matching_female_P0"], outMat["matching_female_P1"], outMat["matching_pooled_P0"], outMat["matching_pooled_P1"])
    elseif bygender == 0
      Output = hcat(outMat["matching_pooled_P0"], outMat["matching_pooled_P1"])
    end
    println("Matching Draw $(draw) DDRAW $(ddraw) OUTPUT SUCCESS")
    
    return Output
  end
end
