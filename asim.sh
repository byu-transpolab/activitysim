#!/bin/bash -l

#SBATCH --time=10:00:00   # walltime
#SBATCH --ntasks=8
#SBATCH --nodes=1   # number of nodes
#SBATCH --mem-per-cpu=20G   # memory per CPU core
#SBATCH -J "asim"   # job name
#SBATCH --mail-user=shaydenatch@gmail.com   # email address
##SBATCH --mail-type=BEGIN
##SBATCH --mail-type=END
##SBATCH --mail-type=FAIL

# Set the max number of threads to use for programs using OpenMP. Should be <= ppn. Does nothing if the program doesn't use OpenMP.
export OMP_NUM_THREADS=$SLURM_CPUS_ON_NODE
SCNAME="base"


module load miniconda3
echo "Loaded Modules"
module list

conda activate asim

python -m wfrc_asim_scenario.simulation -w wfrc_asim_scenario -m
