# ========================================================================== #
# Calculating Factor Scores
# Author :  Jessica Yu Kyung Koh
# Date :    09/30/2016
# Note :    Steps to compute the factor score are the following:
#            (1) Compute the correlation matrix of the "standardized" data with k independent variables of interest
#            (2) Compute the eigenvalue + eigenvector pair of the correlation matrix
#            (3) Choose the number of factors, m (Note: We only use 1 with the max eigenvalue for the ABC-CARE project)
#                using the value of the eigenvalue (general rule: eigenvalue > 1)
#            (4) According to the Regression method to compute factor score,
#                factor score matrix is (m x k) matrix F = [f_{ij}], where
#                f_{ij} = c_{ij}/sqrt(lambda_j)
#            (5) Demean independent variables
#            (6) Compute the dot product of factor score matrix and demeaned independent variables
#
# Source: http://www.real-statistics.com/multivariate-statistics/factor-analysis/factor-scores/
# ========================================================================== #

# ===================================== #
# Correlation matrix (standardize data) #
# ===================================== #
function stdcorrdata(tofactordata)

    datasize = size(tofactordata)
    N = datasize[1]     # number of rows
    K = datasize[2]     # number of columns

    # Standardize each measure
    nonadata = tofactordata[:,:]
    for k in range(1, K)
        nonadata[:,k] = (nonadata[:,k] - mean(nonadata[!isna(nonadata[:,k]),k]))/std(nonadata[!isna(nonadata[:,k]),k])
        nonadata = nonadata[!isna(nonadata[:,k]), :]
    end

    # Preparation to creating correlation matrix
    arraydata = Array(nonadata)

    # Compute correlation matrix
    CM = cor(arraydata)
    return CM
end


# ===================================================================================== #
# Number of factors through Scree Plot rule (>1 eigen values of std correlation matrix) #
# ===================================================================================== #
function screeplot(tofactordata)
    datasize = size(tofactordata)
    N = datasize[1]     # number of rows
    K = datasize[2]     # number of columns
    CM = stdcorrdata(tofactordata)

    # Compute eigenvalues, produce scree plot, define number of factors
    eigCM = eigvals(CM)
    eigCM = sort!(eigCM, rev=true)    # sort in a descending order

    # Define and display number of factors
    factorn = max(sum(abs(eigCM) .> 1), 1)
    return factorn
end


# ======================== #
# Diagonal factor analysis #
# ======================== #
function diagonalfac(sampledata, tofactordata, factorn)

    datasize = size(tofactordata)
    N = datasize[1]     # number of rows
    K = datasize[2]     # number of columns

    # Delete rows with NA values and standardize each measure
    nonadata = tofactordata[:,:]
    for k in range(1, K)
        nonadata[:,k] = (nonadata[:,k] - mean(nonadata[!isna(nonadata[:,k]),k]))/std(nonadata[!isna(nonadata[:,k]),k])
        nonadata = nonadata[!isna(nonadata[:,k]), :]
    end

    arraydata = Array(nonadata)
    rankdata = rank(arraydata)

    # Generate number of factors
    if factorn == "None"
      factorn = screeplot(tofactordata)
    end

    # Compute standardized correlation matrix
    CM = stdcorrdata(tofactordata)

    # Create a matrix storing the factor loadings and factor loadings matrices
    floads  = Array(Float64, K, factorn)

    # Ingredientes to extract factors
    for j in range(1,factorn)
        # Calculate the eigenvalue + eigenvector pair of CM
        eigval = eig(CM)[1]
        eigvec = eig(CM)[2]

        # Index maximum eigenvalue and choose corresponding eigenvector
        maxeigval = indmax(eigval)
        maxeigvec = eigvec[:, maxeigval]

        # Calculate and store factor loadings (eigenvector / sqrt(eigenvalue))
        floads[:,j] =  maxeigvec ./ sqrt(eigmax(CM))
    end

    # Demean independent variables in the sample data
    colnames = names(nonadata)
    for col in colnames
      meancol = mean(nonadata[:,col])
      nonadata[col] -= meancol
    end

    # compute the factor score ("*" acts like a dot product here)
    arnonadata = Array(nonadata)
    fscores = -1 * arnonadata * floads

    # ------------------------------- #
    # Add factor score to sample data #
    # ------------------------------- #
    # Index rows that have no NA for any of the variables used to create a factor score
    sampledata[:new_id] = 0

    index = 1
    for i in 1:N
      # Turn NA switch on if the row contains at least one NA for any of the variables for factor score
      naswitch = 0
      for col in colnames
        if isna(sampledata[i, col])
          naswitch = 1
        end
      end

      # If naswitch is 0, index the row.
      if naswitch == 0
        sampledata[i, :new_id] = index
        index = index + 1
      elseif naswitch == 1
        sampledata[i, :new_id] = NA
      end
    end

    # Create new_id for the factor score
    fscoresize = size(fscores)[1]
    fscoresv = vec(fscores)
    fscoreframe = DataFrame(new_id = 1:fscoresize, factor = fscoresv)

    # Merge factorscore using new_id
    mergedata = join(sampledata, fscoreframe, on = [:new_id], kind = :outer)
    delete!(mergedata, :new_id)

    return mergedata
end
