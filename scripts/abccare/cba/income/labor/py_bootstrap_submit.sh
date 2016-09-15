#!/bin/bash
#PBS -N IncomeProjections
#PBS -j oe
#PBS -V
#PBS -l nodes=1:ppn=20

cd "/home/aziff/projects/abc-treatmenteffects-finalseason/scripts/abccare/cba/income/labor"

python2.7 bootstrap_prediction_weights.py
