#!/bin/bash

#SBATCH --time=20:00:00   # walltime
#SBATCH --ntasks=8
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=70G   # memory per CPU core
#SBATCH -J "example_mtc"   # job name
#SBATCH --mail-user=shaydenatch@gmail.com   # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

module purge
module load python/3.8
pip install -r requirements.txt

python -m wfrc_asim_scenario.simulation -w activitysim/examples/example_mtc -m
