import os
import glob

SRALIST = "SraAccList.txt"
DATASET = "dataset"
READS = ["R1","R2"] #or [1,2] check filenames

with open(SRALIST, "r") as srafile:
    ACCESSION = [x.strip() for x in srafile]

# snakemake --dag | dot -Tpdf > output/dag.pdf

localrules: main

rule main:
    input:
        expand("{dataset}/{accession}/{accession}_{read}.fastq.gz", dataset=DATASET, accession=ACCESSION, read=READS)

rule fetch_accession:
    output: temp("{dataset}/{accession}/{accession}.sra")
    params:
        output_folder = "{dataset}"
    threads: 4
    resources:
        time_min = 100,
        mem_mb = 64000
    container: "docker://befh/sra-tools:3.0.0"
    shell:
        """
        prefetch {wildcards.accession} --max-size 64G -O {params.output_folder}
        """

rule sra_to_fastq:
    input: "{dataset}/{accession}/{accession}.sra"
    output: expand("{{dataset}}/{{accession}}/{{accession}}_{read}.fastq", read=READS)
    params:
        output_folder = "{dataset}/{accession}",
    threads: 4
    resources:
        time_min = 100,
        mem_mb = 64000
    container: "docker://befh/sra-tools:3.0.0"
    shell:
        """
        fasterq-dump {input} -e 20 --split-files -O {params.output_folder}
        """

rule gzip_fastq:
    input:
        expand("{{dataset}}/{{accession}}/{{accession}}_{read}.fastq", read=READS)
    output:
        expand("{{dataset}}/{{accession}}/{{accession}}_{read}.fastq.gz", read=READS)
    params:
        output_folder = "{dataset}/{accession}"
    threads: 1
    resources:
        time_min = 30,
        mem_mb = 2000
    shell:
        """
        pigz {input}
        """
