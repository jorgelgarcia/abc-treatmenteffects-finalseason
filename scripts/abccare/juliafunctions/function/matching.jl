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
  matchingdata = sampledata[:,:]

  # Bootstrap resample if necessary
  if bootsample == "yes"
    if ddraw != 0
      matchingdata = bsample(matchingdata, :male, :family)
    end
  end

  # Estimate factors if necessary
  if factorswitch == 1
    matchingdata = factors(matchingdata)
  end

  # Generate IPW weight for the bootstrapped sample
  matchingdata = IPWweight(matchingdata, outcomes, outcome_list)

  # Generate Epanechnikov weight for the bootstrapped sampledata (Epanechnikov might fail, so we need to capture that)
  success = 1
  println("Beginning Epanechnikov")
  try
    matchingdata = epanechnikov(matchingdata, controls, 20)
  catch error
    success = 0
    global append_switch = 0
    println("Epan error: $(error)")
    println("Epanechinikov failed")
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

        #=# -------------------------------- #
        # Delete control with no variation #
        # -------------------------------- #
        usecontrols = controls

        for var in controls
          level = size(levels(usedata[var]))[1]
          if level == 1
            usecontrols = deleteat!(usecontrols, findin(usecontrols, [var]))
          end
        end =#


        outMat["matching_$(gender)_P$(p)"] = DataFrame(rowname = [], draw = [], ddraw = [],
                              epan_ipw = [], epan_N = [])

        # ------------------ #
        # Perform estimation #
        # ------------------ #
        for y in outcome_list

          # Restrict the estimates to those who we can actually estimate effects
          fml = Formula(y, Expr(:call, :+, :R, controls...))
          try
           #  lm(fml, usedata)
            lm(fml, usedata)
          catch err
            push!(outMat["matching_$(gender)_P$(p)"], [y, draw, ddraw, NA, NA])
            continue
          end

          control_list = [:R]
          append!(control_list, controls)

          obsdata = usedata
          for var in control_list
            obsdata = obsdata[!isna(obsdata[var]),:]
          end

          # Determine who is in treatment and who is in control
          cond_treat = (obsdata[:R] .== 1)
          cond_control = (obsdata[:R] .== 0)

          for id in obsdata[:id]

            if typeof(id) == Float64
              id = Int(id)
            end

            obsdata[parse("ie_$(y)_$(id)")] = 0.0    # generate column for Epanechnikov*IPW

            if in(parse("ipw_$(y)"), names(obsdata)) & in(parse("epa_$(id)"), names(obsdata))
              obsdata[parse("ie_$(y)_$(id)")] = obsdata[parse("ipw_$(y)")] .* obsdata[parse("epa_$(id)")]
            elseif !in(parse("ipw_$(y)"), names(obsdata)) & in(parse("epa_$(id)"), names(obsdata))
              obsdata[parse("ie_$(y)_$(id)")] = obsdata[parse("epa_$(id)")]
            elseif !in(parse("epa_$(id)"), names(obsdata))
              obsdata = delete!(obsdata, parse("ie_$(y)_$(id)"))
            end
          end

          # Do not match treated with P = 1 to control with P = 0
          for id in obsdata[(obsdata[:R] .== 0) & (obsdata[:P] .== 0), :id]
            if typeof(id) == Float64
              id = Int(id)
            end
            if in(parse("ie_$(y)_$(id)"), names(obsdata))
              obsdata[(obsdata[:R] .== 1) & (obsdata[:P] .== 1), parse("ie_$(y)_$(id)")] = NA
            end
          end
          # Do not match control with P = 0 to treated with P = 1
          for id in obsdata[(obsdata[:R] .== 1) & (obsdata[:P] .== 1), :id]
            if typeof(id) == Float64
              id = Int(id)
            end
            if in(parse("ie_$(y)_$(id)"), names(obsdata))
              obsdata[(obsdata[:R] .== 0) & (obsdata[:P] .== 0), parse("ie_$(y)_$(id)")] = NA
            end
          end

          # Declare counterfactuals and fill in values
          obsdata[:counter0] = 0.0
          obsdata[:counter1] = 0.0

          obsdata[obsdata[:R] .== 0, :counter0] = obsdata[obsdata[:R] .== 0, y]
          obsdata[obsdata[:R] .== 1, :counter0] = NA
          obsdata[obsdata[:R] .== 1, :counter1] = obsdata[obsdata[:R] .== 1, y]
          obsdata[obsdata[:R] .== 0, :counter1] = NA

          for id in obsdata[:id]
            if typeof(id) == Float64
              id = Int(id)
            end
            if in(parse("ie_$(y)_$(id)"), names(obsdata))
              x = obsdata[(!isna(obsdata[parse("$(y)")])) & (!isna(obsdata[parse("ie_$(y)_$(id)")])), parse("$(y)")]
              w = obsdata[(!isna(obsdata[parse("$(y)")])) & (!isna(obsdata[parse("ie_$(y)_$(id)")])), parse("ie_$(y)_$(id)")]
              mean_yw = mean(x, weights(Array(w)))

              if obsdata[(obsdata[:id] .== id), :R][1,1] == 1
                obsdata[(obsdata[:id] .== id), :counter0] = mean_yw
              elseif obsdata[(obsdata[:id] .== id), :R][1,1] == 0
                obsdata[(obsdata[:id] .== id), :counter1] = mean_yw
              end
            end
          end

          # Estimate treatment effects
          obsdata[:TE] = 0.0
          obsdata[:TE] = obsdata[:counter1] .- obsdata[:counter0]

          if in(parse("ipw_$(y)"), names(obsdata))
            mean_te = mean(obsdata[(!isna(obsdata[:TE])) & (!isnan(obsdata[:TE])), :TE],  weights(Array(obsdata[!isna(obsdata[:TE]) & (!isnan(obsdata[:TE])), parse("ipw_$(y)")])))
            N = length(obsdata[!isna(obsdata[:TE]) & (!isnan(obsdata[:TE])), :TE])
          else
            mean_te = mean(obsdata[!isna(obsdata[:TE]) & (!isnan(obsdata[:TE])), :TE])
            N = length(obsdata[!isna(obsdata[:TE]) & (!isnan(obsdata[:TE])), :TE])
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
