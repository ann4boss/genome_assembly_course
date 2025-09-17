#!/usr/bin/env bash

#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=1-00:00:00
#SBATCH --job-name=flye
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --error=./errors/error_flye_%j.e
#SBATCH --output=./outputs/output_flye_%j.o

# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/analysis/05_flye_assembly"
THREADS="${SLURM_CPUS_PER_TASK}"
APPTAINER_FLYE="/containers/apptainer/flye_2.9.5.sif"

# Check if FASTQ_FILE is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_fastq_file>"
  exit 1
fi

GENOMIC_INPUT="$1"

# Create directory for the assemblies
mkdir -p "${OUTPUT_DIR}"

# Get accession name (parent folder of the input file)
ACCESSION_NAME=$(basename "$(dirname "${GENOMIC_INPUT}")")

# Define output directory for this accession
SAMPLE_OUTDIR="${OUTPUT_DIR}/${ACCESSION_NAME}"
mkdir -p "${SAMPLE_OUTDIR}"

echo "Starting Flye assembly for accession: ${ACCESSION_NAME}"
echo "Input file: ${GENOMIC_INPUT}"
echo "Output directory: ${SAMPLE_OUTDIR}"

# --- Run Flye assembly ---
apptainer exec --bind /data "${APPTAINER_FLYE}" flye \
    --pacbio-hifi "${GENOMIC_INPUT}" \
    -t "${THREADS}" \
    -o "${SAMPLE_OUTDIR}"

# Check exit status
if [[ $? -eq 0 ]]; then
    echo "Flye assembly completed successfully for ${GENOMIC_INPUT}"
else
    echo "Flye assembly failed for ${GENOMIC_INPUT}"
    exit 1
fi