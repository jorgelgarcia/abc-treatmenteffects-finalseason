# ================================================================ #
# Function to Form Epanechnikov Kernel
# Author: Jessica Yu Kyung Koh
# Created: 05/30/2016
# Edited: 06/22/2016
# ================================================================ #

function epanechnikov(sampledata, controls, bandwidth)

  # ----------- #
  # Preparation #
  # ----------- #
  # Create data that has no empty values for controls
  varlist = [:R]
  varlist = append!(varlist, controls)

  covdata = sampledata[:, varlist]
  for var in controls
    covdata = covdata[!isna(covdata[var]),:]
  end

  # Form inverse of covariance matrix
  cov1 = cov(Array(covdata[covdata[:R] .== 1, controls]))
  Cinv1 = inv(cov1)    # for treated
  cov0 = cov(Array(covdata[covdata[:R] .== 0, controls]))
  Cinv0 = inv(cov0)    # for controls

  # Create a temporary dataset (new_sampledata) in order to generate id-level columns
  for var in controls
    sampledata = sampledata[!isna(sampledata[var]),:]
  end
  sampledata = sampledata[!isna(sampledata[:P]),:]
  # ----------------------------------------------- #
  # Estimate the Mahalanobis Distance for Each Pair #
  # ----------------------------------------------- #
  for treat in (0, 1)
    # Prepare switches so the code below generating weights can be looped
    treat_c = 1 - treat

    # Define conditions to select only treated or only controls
    cond_treat = (sampledata[:R] .== 1)
    cond_control = (sampledata[:R] .== 0)

    if treat == 0
      condition = cond_control
      invcov = Cinv1
    elseif treat == 1
      condition = cond_treat
      invcov = Cinv0
    end

    # Loop through each id's to generate id-specific Epanechnikov weights
    for id in sampledata[condition, :id]

      # Generate vector of (X-mu), where mu is the observation for each individual
      maha_controls = [:drop]     # list to collect (X-mu) column names for all controls

      for var in controls
        sampledata[parse("$(var)_$(id)")] = 0.0     # Declare new column as flaat
        mu = sampledata[sampledata[:id] .== id, var][1,1]
        sampledata[parse("$(var)_$(id)")] = sampledata[parse("$(var)")] .- mu
        maha_controls = append!(maha_controls, [parse("$(var)_$(id)")])
      end
      deleteat!(maha_controls, findin(maha_controls, [:drop]))
      # Declare matrix of (X-mu) (I will call it X for convenience)
      X = Array(sampledata[sampledata[:R] .== treat_c, maha_controls])

      # Estimate Mahalanobis metric
      maha = X * invcov * X'
      try
        diag(maha) .^ (1/2)
      catch err
        continue
      end
      maha = diag(maha) .^ (1/2)

      # Convert Mahalanobis to Epanechnikov
      inband = 1(abs(maha ./ bandwidth) .<= 1)
      maha = ((1/bandwidth) * (3/4)) .* (1 .- (maha ./ bandwidth).^2) .* inband

      # Put weight into the sampledata
      sampledata[parse("epa_$(id)")] = 0.0
      sampledata[sampledata[:R] .== treat_c, parse("epa_$(id)")] = maha
      sampledata[sampledata[:R] .== treat, parse("epa_$(id)")] = NA
      for var in controls
        delete!(sampledata, [parse("$(var)_$(id)")])
      end
    end
  end
  return sampledata
end
