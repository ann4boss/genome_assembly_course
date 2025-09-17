#!/usr/bin/env bash

### DOES NOT WORK!!! ###

#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --job-name=busco_download
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_busco_download_%j.e
#SBATCH --output=./outputs/output_busco_download_%j.o


# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
BUSCO_DB_DIR="${PROJECT_DIR}/data/02_busco_dataset"
APPTAINER_BUSCO="/containers/apptainer/busco_5.8.2.sif"

# Create directory if not exists
mkdir -p "${BUSCO_DB_DIR}"
cd ${BUSCO_DIR}

# Download the dataset
wget https://busco-data.ezlab.org/v5/data/lineages/brassicales_odb10.2024-01-08.tar.gz

# Extract it
tar -xzf brassicales_odb10.2024-01-08.tar.gz