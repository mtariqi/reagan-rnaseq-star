configfile: "config/config.yaml"

rule all:
    input:
        "results/STAR_index/SA",
        "results/STAR_index/SAindex",
        "results/STAR_index/Genome",
        "results/STAR_index/genomeParameters.txt"

rule star_index:
    input:
        fasta=config["reference"]["fasta"],
        gtf=config["reference"]["gtf"],
        container=config["star"]["container"]
    output:
        index=directory("results/STAR_index")
    threads:
        config["star"]["threads"]
    resources:
        mem_mb=131072,
        runtime=480,
        slurm_partition="courses"
    params:
        overhang=config["star"]["sjdb_overhang"]
    log:
        "logs/star_index.log"
    shell:
        r"""
        mkdir -p {output.index:q}
        singularity run \
            -B /courses:/courses,/home:/home,/scratch:/scratch \
            {input.container:q} STAR \
            --runMode genomeGenerate \
            --runThreadN {threads} \
            --genomeDir {output.index:q} \
            --genomeFastaFiles {input.fasta:q} \
            --sjdbGTFfile {input.gtf:q} \
            --sjdbOverhang {params.overhang} \
            --outFileNamePrefix {output.index:q}/ \
            > {log:q} 2>&1

        test -s {output.index:q}/SA
        test -s {output.index:q}/SAindex
        test -s {output.index:q}/Genome
        test -s {output.index:q}/genomeParameters.txt
        """

import csv

with open(config["samples"], newline="") as handle:
    SAMPLES = [row["sample"] for row in csv.DictReader(handle, delimiter="\t")]

if len(SAMPLES) != 6 or len(set(SAMPLES)) != 6:
    raise ValueError("The sample manifest must contain six distinct samples.")

def fastq_paths(wildcards, mate):
    return [
        f'{config["fastq_root"]}/{wildcards.sample[:4]}/'
        f'{wildcards.sample}_{lane}_{mate}_001.fastq.gz'
        for lane in ("L001", "L002")
    ]

rule align_all:
    input:
        expand(
            "results/alignments/{sample}/{sample}_Aligned.sortedByCoord.out.bam",
            sample=SAMPLES
        ),
        expand(
            "results/alignments/{sample}/{sample}_Log.final.out",
            sample=SAMPLES
        )

rule star_align:
    input:
        index="results/STAR_index",
        r1=lambda wc: fastq_paths(wc, "R1"),
        r2=lambda wc: fastq_paths(wc, "R2"),
        container=config["star"]["container"]
    output:
        bam="results/alignments/{sample}/{sample}_Aligned.sortedByCoord.out.bam",
        final_log="results/alignments/{sample}/{sample}_Log.final.out"
    threads:
        16
    resources:
        mem_mb=131072,
        runtime=480,
        slurm_partition="courses",
        slurm_account="binf6430.202710"
    params:
        left=lambda wc, input: ",".join(input.r1),
        right=lambda wc, input: ",".join(input.r2),
        prefix="results/alignments/{sample}/{sample}_"
    log:
        "logs/star_align_{sample}.log"
    shell:
        r"""
        mkdir -p results/alignments/{wildcards.sample:q}

        singularity run \
            -B /courses:/courses,/home:/home,/scratch:/scratch \
            {input.container:q} STAR \
            --runThreadN {threads} \
            --genomeDir {input.index:q} \
            --readFilesIn {params.left:q} {params.right:q} \
            --readFilesCommand zcat \
            --outFileNamePrefix {params.prefix:q} \
            --outSAMtype BAM SortedByCoordinate \
            --limitBAMsortRAM 32000000000 \
            > {log:q} 2>&1

        test -s {output.bam:q}
        test -s {output.final_log:q}
        """

rule index_all:
    input:
        expand(
            "results/alignments/{sample}/{sample}_Aligned.sortedByCoord.out.bam.bai",
            sample=SAMPLES
        )

rule bam_index:
    input:
        bam="results/alignments/{sample}/{sample}_Aligned.sortedByCoord.out.bam"
    output:
        bai="results/alignments/{sample}/{sample}_Aligned.sortedByCoord.out.bam.bai"
    threads:
        2
    resources:
        mem_mb=4000,
        runtime=60
    log:
        "logs/bam_index_{sample}.log"
    shell:
        r"""
        samtools quickcheck -v {input.bam:q} > {log:q} 2>&1
        samtools index -@ 1 {input.bam:q} {output.bai:q} \
            >> {log:q} 2>&1
        test -s {output.bai:q}
        """
