#!/bin/bash
#PBS -N Julia
#PBS -j oe
#PBS -V
#PBS -l nodes=1:ppn=20

#-------------------------------------------------
cd "/home/yukyungkoh/abc-treatmenteffects-finalseason/scripts/abccare/cba/health/treatmenteffects-julia/itt"
julia parallel_itt_health_private_surv.jl
#julia abccare_matching.jl


