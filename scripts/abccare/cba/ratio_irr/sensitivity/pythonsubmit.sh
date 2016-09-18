#!/bin/bash
#PBS -N PythonTest
#PBS -j oe
#PBS -V
#PBS -l nodes=1:ppn=20

#-------------------------------------------------

#cd "/home/jkcshea/abc-cba-new/scripts/abccare/treatmenteffects"
#python2.7 effects-tables.py

#-------------------------------------------------

cd "/home/$USER/projects/abc-treatmenteffects-finalseason/scripts/abccare/cba/ratio_irr/sensitivity"

# SINGLE PROCESS
python2.7 sa_bcrdwl.py
python2.7 sa_discount.py

# PARALLEL PROCESS
python2.7 sa_bcrfactor.py
python2.7 sa_irrfactor.py
python2.7 sa_irrdwl.py

#-------------------------------------------------

#cd "/home/jkcshea/abc-cba-new/scripts/abccare/cba/income/labor"
#cd "/home/jkcshea/abc-cba-new/scripts/abccare/cba/income/transfer"
#python2.7 bootstrap_prediction.py

