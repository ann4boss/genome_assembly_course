#!/usr/bin/env bash

#SBATCH --time=1-00:00:00
#SBATCH --mem=100G
#SBATCH --cpus-per-task=16
#SBATCH --job-name=busco
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --mail-type=end
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_busco_%j.e
#SBATCH --output=./outputs/output_busco_%j.o

# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/analysis/09_busco_results"
BUSCO_DB="${PROJECT_DIR}/data/02_busco_dataset/brassicales_odb10"
THREADS="${SLURM_CPUS_PER_TASK}"
APPTAINER_BUSCO="/containers/apptainer/busco_5.8.2.sif"



# Check if FASTA_FILE is provided as an argument, otherwise exit with usage message
if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_fasta_file>"
  exit 1
fi

GENOME="$1"

# Create directories
mkdir -p "${OUTPUT_DIR}"

echo "Starting BUSCO analysis for: ${GENOME}"
echo "Output directory: ${OUTPUT_DIR}"

# Extract the specific directory name from the genome path
ASSEMBLY_METHOD=$(basename $(dirname $(dirname "${GENOME}")))
SAMPLE_NAME=$(basename $(dirname "${GENOME}"))
FULL_NAME="${ASSEMBLY_METHOD}_${SAMPLE_NAME}_busco"


# --- Run BUSCO with local database ---
apptainer exec --bind /data "${APPTAINER_BUSCO}" busco \
    -i "${GENOME}" \
    -o "${FULL_NAME}" \
    --out_path "${OUTPUT_DIR}" \
    -m genome \
    -l "${BUSCO_DB}" \
    --cpu "${THREADS}" \
    --download_path "${BUSCO_DB}" \
    --offline \
    --force



# Check exit status
if [[ $? -eq 0 ]]; then
    echo "BUSCO analysis completed successfully for ${GENOME}"
else
    echo "BUSCO analysis failed for ${GENOME}"
    exit 1
fi