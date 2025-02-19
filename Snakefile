import os
import glob

SRALIST = "SraAccList.txt"
DATASET = "dataset"
READS = ["I1","R1","R2"]

with open(SRALIST, "r") as srafile:
    ACCESSION = [x.strip() for x in srafile]

# snakemake --dag | dot -Tpdf > output/dag.pdf

shell.executable("/bin/sh")

## NB: Manual check of output fastq and renamed files according to read length I1=8; R1=26; R2=98

localrules: main

rule main:
    input:
        expand("{dataset}/{accession}/{accession}_{new_read}.fastq", dataset=DATASET, accession=ACCESSION, new_read=READS)

rule fetch_accession:
    output: temp("{dataset}/{accession}/{accession}.sra")
    params:
        output_folder = "{dataset}"
    threads: 4
    resources:
        time_min = 500,
        mem_mb = 64000
    container: "docker://befh/sra-tools:3.0.0"
    shell:
        """
        export http_proxy=http://172.28.7.1:3128
        export https_proxy=http://172.28.7.1:3128
        export all_proxy=http://172.28.7.1:3128
        export no_proxy=localhost,*.chimera.hpc.mssm.edu,172.28.0.0/16
        prefetch {wildcards.accession} --max-size 64G -O {params.output_folder}
        """

# rule sra_to_fastq_checksplit:
#     input: "{dataset}/{accession}/{accession}.sra"
#     output: "{dataset}/{accession}.log"
#     params:
#         output_folder = "{dataset}/{accession}",
#         split_fastq = "--split-files --include-technical"
#     threads: 4
#     resources:
#         time_min = 500,
#         mem_mb = 64000
#     container: "docker://befh/sra-tools:3.0.0"
#     shell:
#         """
#         fasterq-dump {input} -e 20 --split-files --include-technical -O {params.output_folder}
#         touch {output}
#         """

rule sra_to_fastq:
    input: "{dataset}/{accession}/{accession}.sra"
    output: expand("{{dataset}}/{{accession}}/{{accession}}_{default_read}.fastq", default_read=[1,2,3])
    params:
        output_folder = "{dataset}/{accession}",
        # split_fastq = "--split-files --include-technical"
    threads: 4
    resources:
        time_min = 500,
        mem_mb = 64000
    container: "docker://befh/sra-tools:3.0.0"
    shell:
        """
        fasterq-dump {input} -e 20 --split-files --include-technical -O {params.output_folder}
        """

rule rename_fastq:
    input:
        expand("{{dataset}}/{{accession}}/{{accession}}_{default_read}.fastq", default_read=[1,2,3])
    output:
        expand("{{dataset}}/{{accession}}/{{accession}}_{new_read}.fastq", new_read=READS)
    params:
        output_folder = "{dataset}/{accession}"
    threads: 1
    resources:
        time_min = 30,
        mem_mb = 2000
    shell:
        """
        mv {input[0]} {output[0]}
        mv {input[1]} {output[1]}
        mv {input[2]} {output[2]}
        """
