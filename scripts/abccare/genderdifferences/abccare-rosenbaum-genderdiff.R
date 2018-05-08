Sys.setenv(TMPDIR='/home/aziff/TMPDIR')

library('crossmatch')
library('foreign')
library('MASS')
library('nbpMatching')

# parameters
set.seed(1)

# environment variables and filepaths
klmshare  <- Sys.getenv('klmshare')
abccare	  <- file.path(klmshare,'Data_Central','Abecedarian','data','ABC-CARE')
datafile	<- file.path(abccare,'extensions','cba-iv')
repo	    <- file.path(projects, 'abccare-cba')
scripts	  <- file.path(repo, 'scripts', 'abccare', 'genderdifferences')

# load data
#setwd(datafile)
setwd('/share/klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv')
getwd()
df <- data.frame(read.dta('append-abccare_iv.dta'))

#  only keep necessary variables
basicvars <- c('id','R','RV','male','dc_alt','dc_mo_pre')
iqvars <- c('iq2y','iq3y','iq3y6m','iq4y','iq4y6m','iq5y','iq6y6m','iq8y')
achvars <- c('ach6y','ach7y6m','ach8y','ach8y6m')
sevars <- c('ibr_task0y6m','ibr_actv0y6m','ibr_sociab0y6m')
sevars <- c(sevars,'ibr_task1y','ibr_actv1y','ibr_sociab1y')
sevars <- c(sevars,'ibr_task1y6m','ibr_actv1y6m','ibr_sociab1y6m')
parentvars <- c('home0y6m','home1y6m','home2y6m','home3y6m','home4y6m')
pincvars		<- c('p_inc1y6m','p_inc2y6m','p_inc3y6m','p_inc4y6m')
mworkvars	<-c('m_work1y6m','m_work2y6m','m_work3y6m','m_work4y6m')
fhomevars <- c('f_home1y6m','f_home2y6m','f_home3y6m','f_home4y6m')
schvars <- c('sch_hs30y','si30y_univ_comp','years_30y','tot_sped')
empvars <- c('si30y_works_job','si30y_inc_labor')
crimevars <- c('ad34_fel','ad34_mis','si30y_adlt_totinc')
riskvars <- c('si30y_cig_num','drink_days','drink_binge_days')
healthvars <- c('si34y_sys_bp','si34y_dia_bp','si34y_prehyper','si34y_hyper')
healthvars <- c(healthvars,'si34y_chol_hdl','si34y_dyslipid','si34y_hemoglobin','si34y_prediab','si34y_diab')
healthvars <- c(healthvars,'si34y_bmi','si34y_obese','si34y_sev_obese','si34y_whr','si34y_obese_whr','si34y_fram_p1')
mhealthvars <- c('bsi_tsom','bsi_tdep','bsi_tanx','bsi_thos','bsi_tgsi')


varlists <- c(iqvars,parentvars,mworkvars,fhomevars,schvars,empvars)
varlists <- c(varlists,sevars,mhealthvars)

keeps <- append(basicvars,varlists)
df <- df[, keeps, drop=FALSE]

# drop if R == 0 & RV == 1 and .x
df <- df[!(df$R==0 & df$RV==1),]
df <- df[!(df$R==0),]
df <- df[!is.na(df$id),]

# balance number of males and number of females
nToDrop <- sum(df$male==1) - sum(df$male==0)

# create distance matrix
# 	idcol: column with ID numbers
# 	missing.weight: match on missing
# 	ndiscard: "phantoms" to make sure the cardinality of the groups balance
f1 <- gendistance(subset(df, select=c('id',varlists)), idcol=1, missing.weight=0, ndiscard=nToDrop)
# reformat distance matrix
f2 <- distancematrix(f1)
# create matches
#f3 <- nonbimatch(dist)
# only list pairs once
#f4 <- f3$halves

# make a new matrix with values of distance matrix
# distancematrix() outputs a matrix that cannot be altered
dimf2 <- dim(f2)
out <- matrix(NA,dimf2,dimf2)
for (i in 1:(dimf2[1]*dimf2[2])){
	out[i] <- f2[i]
}

# assign a matchID for each pair: the first pair is 1, etc.
#keepers = c()
#matchID = c()
#for( i in 1:dim(f4)[1]) {
#	keepers = c(keepers, f4$Group1.Row[i], f4$Group2.Row[i])
#	matchID = c(matchID, i, i)
#}
# merge back into dataset sorting by pairs
#d4 = df[keepers,]
#d4$matchID = matchID

# crossmatch test
z <- unlist(df$male, use.names=FALSE)
crossmatchtest(z,out)
