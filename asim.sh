#!/bin/bash

#SBATCH --time=20:00:00   # walltime
#SBATCH --ntasks=16
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=20G   # memory per CPU core
#SBATCH -J "asim"   # job name
#SBATCH --mail-user=shaydenatch@gmail.com   # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

module purge
module load python/3.8
pip install -r requirements.txt

python -m wfrc_asim_scenario.simulation -w wfrc_asim_scenario -m
