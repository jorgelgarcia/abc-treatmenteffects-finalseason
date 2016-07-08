# ================================================================ #
# Function to Write Out Matrix for Resampled Data
# Author: Jessica Yu Kyung Koh
# Created: 06/15/2016
# ================================================================ #

#=
Description:	This code allows the user to write out matrices into
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
=#

function writematrix(output, matrix, rowname, write_draw, header)
  # -------------- #
  # Define headers #
  # -------------- #
  colnames = names(matrix)   # Shows list of column names

  if header == 1
    if colnames != NaN
      if rowname != NaN
        write(output, "rowname,")
      end
      if write_draw != -999
        write(output, "draw,")
      end
      index = 1
      for name in colnames
        write(output, "$(name)")
        if index < length(colnames)
          write(output, ",")
          index = index + 1
        else
          write(output, "\n")
        end
      end
    end
  end

  # ------------------- #
  # Output coefficients #
  # ------------------- #
  if rowname != NaN
    write(output, "$(rowname),")
  end
  if write_draw != -999
    write(output, "$(write_draw),")
  end
  for index in 1:length(colnames)
  	coef = matrix[1,index]
    if isna(coef)
      write(output, "")
    else
      write(output, "$(round(coef, 4))")
    end
    if index < length(colnames)
      write(output, ",")
    else
      write(output, "\n")
    end
  end
end
