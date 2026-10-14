#!/bin/bash
#SBATCH --job-name=p05_align_manager
#SBATCH --partition=courses
#SBATCH --account=binf6430.202710
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=10:00:00
#SBATCH --output=/scratch/islam.mdtar/Project05/logs/align_manager_%j.out
#SBATCH --error=/scratch/islam.mdtar/Project05/logs/align_manager_%j.err

set -euo pipefail

module load python/3.13.5
source /scratch/islam.mdtar/project05-snakemake-env/bin/activate
cd /scratch/islam.mdtar/Project05

snakemake \
    --executor slurm \
    --jobs 2 \
    --cores 32 \
    --local-cores 1 \
    --default-resources slurm_account=binf6430.202710 \
    --latency-wait 60 \
    --printshellcmds \
    align_all
