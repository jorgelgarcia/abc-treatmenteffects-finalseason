cd "`mergedir'"

#delimit ;
*  PSID DATA CENTER *****************************************************
   JOBID            : 195045                            
   DATA_DOMAIN      : PSID                              
   USER_WHERE       : NULL                              
   FILE_TYPE        : All Individuals Data              
   OUTPUT_DATA_TYPE : ASCII                             
   STATEMENTS       : do                                
   CODEBOOK_TYPE    : PDF                               
   N_OF_VARIABLES   : 4                                 
   N_OF_OBSERVATIONS: 75253                             
   MAX_REC_LENGTH   : 10                                
   DATE & TIME      : August 4, 2015 @ 21:37:24
*************************************************************************
;

infix
      ER30001      1 - 4     ER30002      5 - 7     ER31996      8 - 9    
      ER31997     10 - 10   
using psid_ids.txt, clear 
;

destring, replace ;

label variable ER30001  "1968 INTERVIEW NUMBER"                    ;
label variable ER30002  "PERSON NUMBER                         68" ;
label variable ER31996  "SAMPLING ERROR STRATUM"                   ;
label variable ER31997  "SAMPLING ERROR CLUSTER"                   ;


# delimit cr

cd "`dofiles'"
