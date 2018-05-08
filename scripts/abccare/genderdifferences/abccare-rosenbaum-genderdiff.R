

# libraries 
require('crossmatch')
require('foreign')
require('MASS')
require('nbpMatching')
set.seed(1)

# environment variables and filepaths
projects <- Sys.getenv('projects')
klmshare <- Sys.getenv('klmshare')
abccare	<- file.path(klmshare,'Data_Central','Abecedarian','data','ABC-CARE')
datafile	<- file.path(abccare,'extensions','cba-iv')
repo		<- file.path(projects, 'abccare-cba')
scripts	<- file.path(repo, 'scripts', 'abccare', 'genderdifferences')

# load data
setwd(datafile)
getwd()
df <- data.frame(read.dta('append-abccare_iv.dta'))

# only keep necessary variables
basicvars <- c('id','R','RV','male','dc_alt','dc_mo_pre')
iqvars <- c('iq2y','iq3y','iq3y6m','iq4y','iq4y6m','iq5y','iq6y6m','iq7y','iq8y','iq12y')
keeps <- append(basicvars,iqvars)
df <- df[, keeps, drop=FALSE]

# drop if R == 0 & RV == 1 and .x
df <- df[!(df$R==0 & df$RV==1),]
df <- df[!is.na(df$id),]
#df <- df[complete.cases(df),]

# balance number of males and number of females
nToDrop <- sum(df$male==1) - sum(df$male==0)

# create distance matrix
# 	idcol: column with ID numbers
# 	missing.weight: match on missing
# 	ndiscard: "phantoms" to make sure the cardinality of the groups balance
f1 <- gendistance(subset(df, select=c('id','iq2y','iq3y','iq4y')), idcol=1, missing.weight=0, ndiscard=nToDrop)
# reformat distance matrix
f2 <- distancematrix(f1)
# create matches
#f3 <- nonbimatch(dist)
# only list pairs once
#f4 <- f3$halves


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
#colnames(f2) <- NULL
#rownames(f2) <- NULL
z <- unlist(df$male, use.names=FALSE)
crossmatchtest(z,out)