#!/usr/bin/env bash

#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_download_%j.e
#SBATCH --output=./outputs/output_download_%j.o


# --- Variables ---
ACCESSION=("Altai-5")
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
DATA_DIR="${PROJECT_DIR}/data/01_raw_data"
COURSE_DATA_DIR="/data/courses/assembly-annotation-course/raw_data"

# --- Setup ---
mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}" || exit 1   # exit if cd fails

# --- Create symlinks (force overwrite if they exist) ---
#ln -sfn "${COURSE_DATA_DIR}/${ACCESSION}" .
#ln -sfn "${COURSE_DATA_DIR}/RNAseq_Sha" .

# --- Copy data ---
for ACC in "${ACCESSION[@]}"; do
    echo "Copying ${ACC}..."
    cp -r "${COURSE_DATA_DIR}/${ACC}" .
done

# Copy RNAseq_Sha separately
cp -r "${COURSE_DATA_DIR}/RNAseq_Sha" .