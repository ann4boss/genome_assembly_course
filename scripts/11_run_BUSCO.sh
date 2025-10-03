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
ASSEMBLIES_DIR="${PROJECT_DIR}/data/03_assemblies"
#BUSCO_DB="${PROJECT_DIR}/data/02_busco_dataset/brassicales_odb10"
THREADS="${SLURM_CPUS_PER_TASK}"
module load BUSCO/5.4.2-foss-2021a

mkdir -p "${OUTPUT_DIR}"

# Find all FASTA files in the assemblies directory
find "${ASSEMBLIES_DIR}" -type f \( -name "*.fa" -o -name "*.fasta" -o -name "*.fna" \) | while read -r GENOME; do


  echo "Processing: ${GENOME}"

  # Extract sample information from path
  ASSEMBLY_METHOD=$(basename $(dirname "${GENOME}"))
  SAMPLE_NAME=$(basename "${GENOME%.*}")
  FULL_NAME="${ASSEMBLY_METHOD}_${SAMPLE_NAME}_busco"

  # Determine mode based on file type/name
  if [[ "${GENOME}" == *"trinity"* ]] || [[ "${GENOME}" == *"transcriptome"* ]]; then
      MODE="transcriptome"
      echo "Running in transcriptome mode (Trinity assembly detected)"
  else
      MODE="genome"
      echo "Running in genome mode"
  fi

  # Run BUSCO with auto-lineage
  busco \
      -i "${GENOME}" \
      -o "${FULL_NAME}" \
      --out_path "${OUTPUT_DIR}" \
      -m "${MODE}" \
      --auto-lineage \
      --cpu "${THREADS}" \
      --force

  # Check if BUSCO ran successfully
  if [ $? -eq 0 ]; then
      echo "BUSCO analysis completed successfully for ${GENOME}"
  else
      echo "Error: BUSCO analysis failed for ${GENOME}"
  fi

  echo "----------------------------------------"
done

echo "All BUSCO analyses completed"