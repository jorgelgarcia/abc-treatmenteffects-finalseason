* --------------------------------------------- *
* ABC-CARE Outcomes Treatment Effect Estimation 
* Author: Jessica Yu Kyung Koh
* Date: 07/08/2016
* --------------------------------------------- *

- This folder contains Julia scripts that estimate the treatment effects on ABC-CARE outcomes

	(1) prepare-data.jl:
		A script that modifies the data to facilitate the estimation. This script is called into other scripts.
	
	(2) ITTrun.jl and matchingrun.jl:
		These scripts run estimation for ITT and matching, respectively, and save outputs to giant matrices.
		
	(3) parallel_itt.jl and parallel_matching.jl:
		These scripts parallelize the estimation process to be distributed to multiple processors to speed up the process.
		These scripts combine the work by multiple workers (scripts (2) are called in), and generate the output in the format we want.