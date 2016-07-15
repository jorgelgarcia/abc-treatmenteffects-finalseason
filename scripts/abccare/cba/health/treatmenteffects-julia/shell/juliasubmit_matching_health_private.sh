#!/bin/bash
#PBS -N Julia
#PBS -j oe
#PBS -V
#PBS -l nodes=1:ppn=20

#-------------------------------------------------
cd "/home/yukyungkoh/abc-treatmenteffects-finalseason/scripts/abccare/cba/health/treatmenteffects-julia/matching"
julia parallel_matching_health_private.jl


