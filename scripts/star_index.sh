#!/bin/bash
#SBATCH --job-name=star_idx_gencode
#SBATCH --partition=courses
#SBATCH -N 1
#SBATCH -c 16
#SBATCH --mem 128G
#SBATCH -t 8:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eisik.m@northeastern.edu
#SBATCH --output=/scratch/islam.mdtar/Project05/logs/%x_%j.log
#SBATCH --error=/scratch/islam.mdtar/Project05/logs/%x_%j.err
shopt -s expand_aliases
CRN=$( ls -d /courses/BINF6430.* | sort | tail -n1 | cut -d "." -f2 )

alias STAR='singularity run -B "/courses:/courses,/home:/home,/scratch:/scratch" /shared/container_repository/explorer/star/2.7.10b/star_2.7.10b.sif STAR'

BASE_DIR=/courses/BINF6430.${CRN}
DATA_DIR=${BASE_DIR}/shared/gencode

GENOME_DIR=/scratch/islam.mdtar/Project05/results/STAR
mkdir -p ${GENOME_DIR}

STAR --runThreadN 16 \
     --runMode genomeGenerate \
     --genomeDir ${GENOME_DIR} \
     --genomeFastaFiles ${DATA_DIR}/GRCh38.primary_assembly.genome.fa \
     --sjdbGTFfile ${DATA_DIR}/gencode.v46.annotation.gtf \
     --sjdbOverhang 84
