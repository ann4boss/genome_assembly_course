#!/usr/bin/env bash

#SBATCH --time=02:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4
#SBATCH --job-name=jellyfish
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_kmer_%j.e
#SBATCH --output=./outputs/output_kmer_%j.o

# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
DATA_DIR="${PROJECT_DIR}/data/01_raw_data"
OUTPUT_DIR="${PROJECT_DIR}/analysis/04_kkmer"
THREADS="${SLURM_CPUS_PER_TASK}"

# --- Load Jellyfish module ---
module load Jellyfish/2.3.0-GCC-10.3.0

# Create directories
mkdir -p "${OUTPUT_DIR}"

# --- Process only the specific PacBio files ---
PACBIO_FILES=(
    "${DATA_DIR}/Altai-5/ERR11437324.fastq.gz"
)

for FILE in "${PACBIO_FILES[@]}"; do
    # Extract the directory name (Anz-0, Co-4, Db-1)
    DIR_NAME=$(basename $(dirname "${FILE}"))
    
    COUNT_FILE="${OUTPUT_DIR}/${DIR_NAME}_count.jf"
    HISTO_FILE="${OUTPUT_DIR}/${DIR_NAME}_kkmer.histo"

    echo "Processing: ${FILE}"
    jellyfish count -C -m 21 -s 5G -t "${THREADS}" -o "${COUNT_FILE}" <(zcat "${FILE}")
    jellyfish histo -t "${THREADS}" "${COUNT_FILE}" > "${HISTO_FILE}"
    echo "Completed: ${DIR_NAME}"
done