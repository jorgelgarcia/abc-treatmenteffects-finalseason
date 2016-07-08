
forvalues n = 1/32 {
    label define ER31996L `n' "Core sample stratum code"  , modify
}
forvalues n = 33/56 {
    label define ER31996L `n' "Latino sample stratum code"  , modify
}
forvalues n = 57/87 {
    label define ER31996L `n' "Immigrant sample stratum code"  , modify
}

label define ER31997L  ///
       1 "Unit number 1"  ///
       2 "Unit number 2"

label values ER31996  ER31996L
label values ER31997  ER31997L


