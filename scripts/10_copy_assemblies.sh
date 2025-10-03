#!/usr/bin/env bash

#SBATCH --time=1-00:00:00
#SBATCH --mem=100G
#SBATCH --cpus-per-task=16
#SBATCH --job-name=copy_assembly
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_copy_assembly_%j.e
#SBATCH --output=./outputs/output_copy_assembly_%j.o

# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/data/03_assemblies"
THREADS="${SLURM_CPUS_PER_TASK}"

# Validate input
if [ $# -lt 2 ]; then
    echo "Usage: $0 <assembly1.fasta> <assembly2.fasta> [...]"
    exit 1
fi

# Setup
mkdir -p "${OUTPUT_DIR}"
cd "${OUTPUT_DIR}"

# Copy assemblies with dynamic accession names
ASSEMBLIES_COPY=()
LABELS=()
for assembly in "$@"; do
    # Extract accession name (folder name) and assembly method from path
    accession=$(basename $(dirname "$assembly"))
    method=$(basename $(dirname $(dirname "$assembly")) | sed 's/^[0-9]*_//')
    filename="${method}_${accession}.fasta"
    
    cp "$assembly" "$filename"
    ASSEMBLIES_COPY+=("$filename")
    LABELS+=("${method}_${accession}")
done