#!/bin/bash
#PBS -N PythonTest
#PBS -j oe
#PBS -V
#PBS -1 procs=25

cd $PBS_O_WORKDIR

mpirun -n 25 -machinefile $PBS_NODEFILE python2.7 bootstrap_prediction_weights.py