#!/usr/bin/env bash

#SBATCH --cpus-per-task=16
#SBATCH --mem=100G
#SBATCH --time=2-00:00:00
#SBATCH --job-name=LJA
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --error=./errors/error_lja_%j.e
#SBATCH --output=./outputs/output_lja_%j.o

# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/analysis/07_lja_assembly"
THREADS="${SLURM_CPUS_PER_TASK}"
APPTAINER_LJA="/containers/apptainer/lja-0.2.sif"

# Check if FASTQ_FILE is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_fastq_file>"
  exit 1
fi

GENOMIC_INPUT="$1"

# Get accession name (parent folder of the input file)
ACCESSION_NAME=$(basename "$(dirname "${GENOMIC_INPUT}")")

# Define output directory for this accession
SAMPLE_OUTDIR="${OUTPUT_DIR}/${ACCESSION_NAME}"
mkdir -p "${SAMPLE_OUTDIR}"
echo "Starting LJA assembly for: ${GENOMIC_INPUT}"
echo "Output directory: ${OUTPUT_DIR}"

# --- Run LJA assembly ---
apptainer exec \
    --bind /data \
    "${APPTAINER_LJA}" \
    lja \
    -o "${SAMPLE_OUTDIR}" \
    --reads "${GENOMIC_INPUT}" \
    -t "${THREADS}"

# Check exit status
if [[ $? -eq 0 ]]; then
    echo "LJA assembly completed successfully for ${GENOMIC_INPUT}"
else
    echo "LJA assembly failed for ${GENOMIC_INPUT}"
    exit 1
fi