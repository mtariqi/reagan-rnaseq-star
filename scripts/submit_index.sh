#!/bin/bash
#SBATCH --job-name=p05_index_manager
#SBATCH --partition=courses
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=10:00:00
#SBATCH --output=/scratch/islam.mdtar/Project05/logs/index_manager_%j.out
#SBATCH --error=/scratch/islam.mdtar/Project05/logs/index_manager_%j.err

set -euo pipefail

module load python/3.13.5
source /scratch/islam.mdtar/project05-snakemake-env/bin/activate
cd /scratch/islam.mdtar/Project05

snakemake \
    --executor slurm \
    --slurm-no-account \
    --jobs 1 \
    --cores 16 \
    --latency-wait 60 \
    --printshellcmds \
    star_index
