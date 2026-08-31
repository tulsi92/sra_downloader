# SRA Downloader

This repository contains a Snakemake workflow for downloading sequencing data from the NCBI Sequence Read Archive (SRA) and converting `.sra` files into FASTQ files for downstream analyses.

Separate workflows are provided for paired-end and single-end datasets.

## Workflow overview

The pipeline performs the following steps for each accession:

1. Download `.sra` files from the NCBI Sequence Read Archive
2. Convert `.sra` files to FASTQ format
3. Rename FASTQ files to standardized read names (paired-end workflow)

## Workflow

| Step | Snakemake rule | Description | Primary outputs |
|------|----------------|-------------|-----------------|
| **1. Download SRA files** | `fetch_accession` | Download sequencing files from the NCBI Sequence Read Archive using `prefetch`. | `.sra` files |
| **2. Convert to FASTQ** | `sra_to_fastq` | Convert `.sra` files to FASTQ format using `fasterq-dump`. | FASTQ files |
| **3. Gzip FASTQ** | `gzip_fastq` | Gzip FASTQ files to conserve file size. | Gzipped FASTQ files |
| **4. Rename FASTQ files** *(indexed only)* | `rename_fastq` | Rename FASTQ files to standardized read identifiers (`I1`, `R1`, `R2`). | Renamed FASTQ files |

## Prerequisites

### Input data

Required inputs include:

- A text file containing one SRA accession per line (e.g. `SraAccList.txt`)

Example:

```text
SRR8270313
SRR8270314
SRR8270315
```

### Software

The workflow is implemented in Snakemake and uses:

- SRA Toolkit (`prefetch`, `fasterq-dump`)
- Docker container (`befh/sra-tools:3.0.0`)

## Configuration

Update the parameters at the top of the Snakefile before running:

- `SRALIST` – file containing SRA accession numbers
- `DATASET` – output directory name
- `READS` – output read names (paired-end workflow only)

Example:

```python
SRALIST = "SraAccList.txt"
DATASET = "dataset_20250212"
READS = ["R1", "R2"]
```

## Running the pipeline

```bash
# Dry run
snakemake -np

# Run the full workflow
snakemake --profile lsf
```

## Outputs

For each accession, the workflow generates:

- Downloaded `.sra` files (temporary)
- Gzipped FASTQ files

Directory structure:

```
dataset/
└── SRR8270313/
    ├── SRR8270313_R1.fastq.gz
    └── SRR8270313_R2.fastq.gz
```

## Single-end datasets

A separate Snakefile is provided for datasets generated using single-end sequencing.

The single-end workflow:

- Downloads SRA files
- Converts them directly to FASTQ
- Does not perform read renaming

The indexed workflow:
- Assumes paired-end data with index reads (`I1`, `R1`, `R2`)

## Notes
- Output directory structures can vary between SRA datasets. Depending on the dataset, output paths in the Snakefile may need to be adjusted
- Proxy settings are included for execution on the Mount Sinai HPC environment and may need to be modified for other systems
