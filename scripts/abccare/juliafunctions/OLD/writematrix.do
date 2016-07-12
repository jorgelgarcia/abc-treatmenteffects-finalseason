*=======================================================
* Function to write results
*=======================================================

/*
Author		Joshua Shea
Date		April 11, 2015
Description	This code allows the user to write out matrices into
		.csv files. It is written with the intention of being
		used to save estimates for resampled/permuted data.
		
		
		Options
		-------
		
		output
		Declare the file handle to write the matrix to
		
		matrix
		Declare the matrix that is to be written out into a .csv
		
		rowname
		Declare the name of the matrix, or the dependent variable if
		the matrix is a vector of coefficients
		
		write_draw
		Declare the resampling number.
		
		header
		Declare whether the headers need to be written out in the .csv.
		Headers are the column names in the matrix.

*/


capture program drop 	writematrix
program define 		writematrix

version 12
syntax, output(string) matrix(string) [rowname(string) write_draw(integer -999) HEADer]

// determine matrix size
local headers: colnames `matrix'
local columns: word count `headers'

// output headers
if "`header'" != ""{
	if "`rowname'" != "" file write `output' "rowname,"
	if "`write_draw'" != "-999" file write `output' "draw,"
	local index = 1
	foreach name in `headers' {
		file write `output' "`name'"
		if `index' < `columns' {
			file write `output' ","
			local index = `index' + 1
		}
		else {
			file write `output' _n
		}
	}
}

// output coefficients
if "`rowname'" != "" file write `output' "`rowname',"
if "`write_draw'" != "-999" file write `output' "`write_draw',"
forvalues index = 1/`columns' {
	local coef = `matrix'[1,`index']
	if `coef' == . file write `output' ""
	else file write `output' %12.4f (`coef')
	if `index' < `columns' {
		file write `output' ","
	}
	else {
		file write `output'  _n
	}
}

end
