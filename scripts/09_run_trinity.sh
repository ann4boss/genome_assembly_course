#!/usr/bin/env bash

#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=1-00:00:00
#SBATCH --job-name=trinity
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --error=./errors/error_trinity_%j.e
#SBATCH --output=./outputs/output_trinity_%j.o

# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/analysis/08_trinity_assembly"
THREADS="${SLURM_CPUS_PER_TASK}"

mkdir -p "${OUTPUT_DIR}"

# Check if both FASTQ files are provided as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <path_to_forward_fastq> <path_to_reverse_fastq>"
  exit 1
fi

ILLUMINA_F1="$1"
ILLUMINA_F2="$2"


echo "Starting Trinity assembly for accession"
echo "Input files: ${ILLUMINA_F1} and ${ILLUMINA_F2}"


# --- Run Trinity assembly ---
module load Trinity/2.15.1-foss-2021a
module load picard/2.25.1-Java-11

Trinity --seqType fq \
        --left "${ILLUMINA_F1}" \
        --right "${ILLUMINA_F2}" \
        --CPU "${THREADS}" \
        --max_memory 60G \
        --output "${OUTPUT_DIR}"

# Check exit status
if [[ $? -eq 0 ]]; then
    echo "Trinity assembly completed successfully"
else
    echo "Trinity assembly failed"
    exit 1
fi