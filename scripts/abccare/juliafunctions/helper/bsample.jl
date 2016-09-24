# ================================================================== #
# Function to Perform Bootstrap Resample with Strata and Clustering
# Author: Jessica Yu Kyung Koh
# Created: 06/15/2016
# Edited: 06/20/2016
# ================================================================== #

function bsample(sampledata::AbstractDataFrame, strata, cluster)
  # ------------ #
  # Preparation #
  # ----------- #
  # Define the list of values for strata
  strata_level = levels(sampledata[parse("$(strata)")])
  println("strata_level is $(strata_level)")

  # Define a dictionary in order to loop over variable names
  resampledict = Dict()
  resample = []

  # ---------------------------------------------------------------#
  # Resample data for each strata and append the resampled stratas #
  # ---------------------------------------------------------------#
  index1 = 1

  data_noNA = sampledata[!isna(sampledata[parse("$(strata)")]), :]

  for i in strata_level
    # Define a strata data and number of rows in the strata. Resample for each strata should be of same size
    data = data_noNA[data_noNA[parse("$(strata)")] .== i, :]
    n = size(data, 1)
    cluster_level = levels(data[parse("$(cluster)")])

    index2 = 0

    # Collect rows until the row number is of size n
    while index2 < n
      # If index2 == 1, define a dictionary value. If not, append to the defined dictionary value
      if index2 == 0
        resampledict["x_$(i)"] = data[data[parse("$(cluster)")] .== rand(cluster_level), :]
        cluster_size = size(resampledict["x_$(i)"], 1)
        index2 = index2 + cluster_size
      else
        resampledict["x_$(i)_append"] = data[data[parse("$(cluster)")] .== rand(cluster_level), :]
        cluster_size = size(resampledict["x_$(i)_append"], 1)

        if index2 + cluster_size <= n
          resampledict["x_$(i)"] = append!(resampledict["x_$(i)"], resampledict["x_$(i)_append"])
          index2 = index2 + cluster_size
        else
          continue
        end

      end
    end

    # If index1 == 1, define resample. If not, append to the defined resample
    if index1 == 1
      resample = resampledict["x_$(i)"]
      if strata_level[1] == 1
        sampledata = resample
      end
    else
      sampledata = append!(resample, resampledict["x_$(i)"])
    end
    index1 = index1 + 1
  end

  println("Bootstrap success!")
  return sampledata
end
