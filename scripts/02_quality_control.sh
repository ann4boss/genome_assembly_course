#!/usr/bin/env bash

#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --job-name=fastqc
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_fastqc_%j.e
#SBATCH --output=./outputs/output_fastqc_%j.o

# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
DATA_DIR="${PROJECT_DIR}/data/01_raw_data"
OUTPUT_DIR="${PROJECT_DIR}/analysis/01_fastqc_results"
APPTAINER_FASTQC="/containers/apptainer/fastqc-0.12.1.sif"

# Create directories if they don’t exist
mkdir -p "${DATA_DIR}" "${OUTPUT_DIR}"

# --- Samples ---
SAMPLES=("Altai-5" "RNAseq_Sha")

# --- Run FastQC ---
for SAMPLE in "${SAMPLES[@]}"; do
    echo "Looking for FASTQ files in ${DATA_DIR}/${SAMPLE}"

    # Collect all FASTQ files in this sample directory
    FASTQ_FILES=(${DATA_DIR}/${SAMPLE}/*.fastq.gz)

    # Check if any files were found
    if [[ -e "${FASTQ_FILES[0]}" ]]; then
        echo "Running FastQC for sample: ${SAMPLE}"
        apptainer exec "${APPTAINER_FASTQC}" fastqc \
            -t "${SLURM_CPUS_PER_TASK}" \
            -o "${OUTPUT_DIR}" \
            "${SAMPLE}_${FASTQ_FILES[@]}"

        if [[ $? -eq 0 ]]; then
            echo "FastQC completed successfully for ${SAMPLE}."
        else
            echo "FastQC failed for ${SAMPLE}."
        fi
    else
        echo "No FASTQ files found for sample ${SAMPLE} — skipping."
    fi
done