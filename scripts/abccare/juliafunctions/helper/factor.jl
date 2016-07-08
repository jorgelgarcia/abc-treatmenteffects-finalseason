# ================================================================ #
# Fuction to create factor scores
# Author: Jessica Yu Kyung Koh
# Created: 06/25/2016
# ================================================================ #
function factor(sampledata, factor_outcomes)

	# Find covariance matrix of factor_outcomes
	smapledata[:, factor_outcomes]
	covdata = sampledata[:, factor_outcomes]
	for var in factor_outcomes
		covdata = covdata[!isna(covdata[var]),:]
	end

	CovX = cov(Array(covdata))

	# Compute eigenvalues and eigenvectors. Retrieve factor loadings by sqrt(eigenval_i)*eigenvec_i for each i
	evals, evecs = eig(CovX)
	

end
