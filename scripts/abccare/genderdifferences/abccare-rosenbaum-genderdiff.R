Sys.setenv(TMPDIR='/home/aziff/TMPDIR')

library('crossmatch')
library('foreign')
library('MASS')
library('nbpMatching')

# parameters
set.seed(1)

# environment variables and filepaths
klmshare  	<- Sys.getenv('klmshare')
abccare	  	<- file.path(klmshare,'Data_Central','Abecedarian','data','ABC-CARE')
datafile		<- file.path(abccare,'extensions','cba-iv')
repo	    		<- file.path(projects, 'abccare-cba')
scripts	  	<- file.path(repo, 'scripts', 'abccare', 'genderdifferences')
output 		<- file.path(projects,'abccare-cba', 'output')

# load data
setwd(datafile)
#setwd('/share/klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv')
getwd()
df <- data.frame(read.dta('abccare-factors-R-inputold-updated-short.dta'))

# define function for Rosenbaum test
rosenbaum <- function(data,varstokeep,catvar){
  print(varstokeep)
  # balance number of males and number of females
  nToDrop <- abs(sum(data[,catvar]==1) - sum(data[,catvar]==0))
  print(sum(data[,catvar]==1))
  print(sum(data[,catvar]==0))
  
  # create distance matrix
  # 	idcol: column with ID numbers
  # 	missing.weight: match on missing
  # 	ndiscard: "phantoms" to make sure the cardinality of the groups balance

  f1 <- gendistance(subset(data, select=c('id',varstokeep)), idcol=1, ndiscard=nToDrop)
  #, missing.weight=0,
  # reformat distance matrix

  f2 <- distancematrix(f1)

  # create matches
  #f3 <- nonbimatch(dist)
  #f4 <- f3$halves

  # make a new matrix with values of distance matrix
  # distancematrix() outputs a matrix that cannot be altered
  dimf2 <- dim(f2)
  out <- matrix(NA,dimf2,dimf2)
  for (i in 1:(dimf2[1]*dimf2[2])){
	  out[i] <- f2[i]
  }
  
  # if more than one phantom observation, need to make sure not dividing by 0
  if (nToDrop > 1) {
    #indices <- which(is.infinite(out))
    #for (i in indices){
    #  out[i] <- 0
    #}
    nToKeep = sum(data[,catvar]==1) + sum(data[,catvar]==0)
    out <-out[1:nToKeep,1:nToKeep]
  }
  #print(out)
  # get rid of Inf values so everything is numeric
  
  
  # crossmatch test
  z <- unlist(data[,catvar])
  crossmatchtest(z,out)
  
}

# reduce dataset to necessary variables
#varlists <- c(iqvars,sevars,achvars,parentvars,mworkvars,schvars,empvars,mhealthvars,crimevars,riskvars,healthvars)
#varlists <- c(iqvars,sevars,parentvars,schvars,empvars,mhealthvars)
#cats <- c('iqvars','achvars','sevars','parentvars','mworkvars','schvars','empvars','crimevars','riskvars','healthvars','mhealthvars','varlists')
#cats <- list(iq=iqvars,se=sevars,parent=parentvars,sch=schvars,mhealth=mhealthvars)
#agecats <- list(a5=age5,a15=age15,a34=age34)
#agecatsC <- list(a5=age5,a34=age34)
#agefactors <- c('factorage5','factorage15','factorage34')
#catfactors <- c('factoriq','factorach','factorse','factormlabor','factorparent','factoredu','factoremp','factorhealth','factorrisk','factorcrime','factorall')

factorcats <- list(fiq='factoriq',fach='factorach',fse='factorse',fmlabor='factormlabor',fparent='factorparent',fedu='factoredu',femp='factoremp',fcrime='factorcrime',frisk='factorrisk',fhealth='factorhealth')
#factorcats <- list(base='factorbase',age5='factorage5',age15='factorage15',age34='factorage34',fiq='factoriq',fach='factorach',fse='factorse',fmlabor='factormlabor',fparent='factorparent',fedu='factoredu',femp='factoremp',fcrime='factorcrime',frisk='factorrisk',fhealth='factorhealth',fall='factorall')
#basevars <- c('factorbase')

# drop if R == 0 & RV == 1 and .x
df <- df[!(df$R==0 & df$RV==1),]
df <- df[!is.na(df$id),]

# create different dataframes for each comparison

## GROUP A
# girls, treatment vs. control
GTvCd <- df[(df$male==0),]
# boys, treatment vs. control
BTvCd <- df[(df$male==1),]
# pooled, treatment vs. control
TvCd <- df
# girls, treatment vs. alternative
GTvCad <- df[(df$male==0)&((df$P==1 & df$R==0)|(df$R==1))& !is.na(df$P),]
# girls, treatment vs. home care
GTvChd <- df[(df$male==0)&((df$P==0 & df$R==0)|(df$R==1))& !is.na(df$P),]
# boys, treatment vs. alternative
BTvCad <- df[(df$male==1)&((df$P==1 & df$R==0)|(df$R==1))& !is.na(df$P),]
# boys, treatment vs. home care
BTvChd <- df[(df$male==1)&((df$P==0 & df$R==0)|(df$R==1))& !is.na(df$P),]

## GROUP B
# girls, alternative vs. home care
GCavChd <- df[df$male==0 & df$R==0 & !is.na(df$P),]

# boys, alternative vs. home care
BCavChd <- df[df$male==1 & df$R==0 & !is.na(df$P),]


## GROUP C
# alternative, boy vs. girl
CaBvGd <- df[((df$R==1)|(df$P==1 & df$R==0 & !is.na(df$P))),]
# home care, boy vs. girl
ChBvGd <- df[((df$R==1)|(df$P==0 & df$R==0 & !is.na(df$P))),]
CBvGd <- df[((df$R==0) & !is.na(df$factorbase)),]
TBvGd <- df[((df$R==1) & !is.na(df$factorbase)),]
BvGd <<- df[!is.na(df$factorbase),]

# combine dataframes in to a list
bigdfA <- list(GTvC=GTvCd,BTvC=BTvCd)
#bigdfB <- list(BCavCh=BCavChd,GCavCh=GCavChd)
#bigdfC <- list(ChBvG=ChBvGd,CaBvG=CaBvGd,CBvG=df[(df$R==0),], TBvG=df[(df$R==1),],BvG=df)
#smalldfC <- list(CBvG=CBvGd, TBvG=TBvGd,BvG=BvGd)

outputAf <- sapply(factorcats, function(x) sapply(bigdfA, function(y) rosenbaum(y,x,'R')))
#outputBf <- sapply(factorcats, function(x) sapply(bigdfB, function(y) rosenbaum(y,x,'P')))
#outputCf <- sapply(factorcats, function(x) sapply(bigdfC, function(y) rosenbaum(y,x,'male')))
#outputCf <- sapply(factorcats, function(x) sapply(smalldfC, function(y) rosenbaum(y,x,'male')))
#outputDisadvantage <- rosenbaum(df[(df$R==0),],basevars,'male')
#outputSelection <- sapply(bigdfB,function(x) rosenbaum(x,basevars,'P'))

setwd(output)
#cAf <-data.frame(outputDisadvantage) 
#write.matrix(cAf,'rosenbaum-output-Disadvantage.txt',sep=',')

#cBf <-data.frame(outputSelection) 
#write.matrix(cBf,'rosenbaum-output-BSelection.txt',sep=',')

#setwd('/home/aziff/projects/abccare-cba/output')
cAf <-data.frame(outputAf) 
write.matrix(cAf,'rosenbaum-output-Afactors-updated-short.txt',sep=',')

#cBf <-data.frame(outputBf) 
#write.matrix(cBf,'rosenbaum-output-Bfactors-updated-short.txt',sep=',')

#cCf <-data.frame(outputCf)
#write.matrix(cCf,'rosenbaum-output-Cfactors-updated-short.txt',sep=',')
