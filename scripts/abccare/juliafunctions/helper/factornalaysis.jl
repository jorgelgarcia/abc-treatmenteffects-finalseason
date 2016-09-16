# ========================================================================================== #
# Diagonal Factor Analysis
# Author : Jorge Luis Garcia
# Translator : Jessica Yu Kyung Koh
#
# Basics:       three functions,    (1) standardize data and obtain the correlation matrix
#                                   (2) scree plot to determine the number of factors
#                                   (3) diagonal factor analysis
#                                   (*) option to avoid displaying scree plot
#                                   (*) option to manually input the number of factors
#               input,              a linearly independent measurement system as an array
#               output,             an array called fscores containning factor scores
# ========================================================================================== #

# ===================================== #
# Correlation matrix (standardize data) #
# ===================================== #
function stdcorrdata(tofactordata)
    datasize = size(tofactordata)
    N = datasize[1]     # number of rows
    K = datasize[2]     # number of columns

    # Standardize each measure
    nonadata = tofactordata
    for k in range(0, K)
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
function diagonalfac(tofactordata, factorn)

    datasize = size(tofactordata)
    N = datasize[1]     # number of rows
    K = datasize[2]     # number of columns

    # Delete rows with NA values and create an array of tofactordata
    nonadata = tofactordata
    for k in range(0, K)
        nonadata = nonadata[!isna(nonadata[:,k]), :]
    end

    arraydata = Array(nonadata)
    rankdata = rank(arraydata)

    # Preparation to creating correlation matrix
    arraydata = Array(nonadata)

    #println("$(N) is the number of measures")
    #println("$(rankdata) are linearly independent")
    #println("$(N) should be identical to $(rankdata) for the code to finish with success")

    # Generate number of factors
    if factorn == "None"
      factorn = screeplot(tofactordata)
    end

    # Compute standardized correlation matrix
    CM = stdcorrdata(tofactordata)

    # Create a matrix storing the factor loadings and factor loadings matrices
    floads  = Array(Float64, K, factorn)
    floadsm = Array(Float64, K, K, factorn)

    # Ingredientes to extract factors
    for j in range(0,factorn)
        # sum of squares of the correlation matrix (sum(matrix, 1) means summing columns in matrix)
        ssCM = sum(CM .^ 2, 1)
        # Index variable with maximum correlation
        maxcorr2 = indmax(ssCM)
        # Calculate and store factor loadings
        floads[:,j] = CM[:,maxcorr2]
        # Number of elements in CM
        nume = length(CM)
        # Calculate and store residual matrix
        floadsm[:,:,j] = dot(reshape(CM[:,maxcorr2], nume, 1), reshape(CM[:,maxcorr2], 1, nume))
        # Residualize the correlation matrix
        CM -= floadsm[:,:,j]
    end

    # Define and return factors
    fscores = dot(dot(nonadata,floads), inv(dot(transpose(floads),floads)))
    return fscores
end
