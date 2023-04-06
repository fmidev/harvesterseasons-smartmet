#!/bin/bash 
#SBATCH --job-name=xgb-fit
#SBATCH --time=504:00:00
#SBATCH --cpus-per-task=24 
#SBATCH --nodes=2
#SBATCH --nodelist=66,65
#SBATCH --mem-per-cpu=4000

set -xu
python $*