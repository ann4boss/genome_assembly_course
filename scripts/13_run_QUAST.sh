#!/usr/bin/env bash

#SBATCH --time=1-00:00:00
#SBATCH --mem=100G
#SBATCH --cpus-per-task=16
#SBATCH --job-name=Quast
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --mail-type=end
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_quast_%j.e
#SBATCH --output=./outputs/output_quast_%j.o

# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/analysis/11_quast_results"
THREADS="${SLURM_CPUS_PER_TASK}"
APPTAINER_QUAST="/containers/apptainer/quast_5.2.0.sif"
REFERENCES_DIR="/data/courses/assembly-annotation-course/references"

# Validate input
if [ $# -lt 2 ]; then
    echo "Usage: $0 <assembly1.fasta> <assembly2.fasta> [...]"
    exit 1
fi

# Setup
mkdir -p "${OUTPUT_DIR}"
cd "${OUTPUT_DIR}"
cp "${REFERENCES_DIR}"/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa "${OUTPUT_DIR}"
cp "${REFERENCES_DIR}"/Arabidopsis_thaliana.TAIR10.57.gff3 "${OUTPUT_DIR}"

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

# Generate labels
LABELS_STR=$(IFS=,; echo "${LABELS[*]}")

# Run QUAST without reference
apptainer exec --bind .:/data "${APPTAINER_QUAST}" quast.py \
    $(printf "/data/%s " "${ASSEMBLIES_COPY[@]}") \
    -o /data/no_reference --eukaryote --large -t "${SLURM_CPUS_PER_TASK:-8}" --labels "$LABELS_STR" --no-sv

# Run QUAST with reference
apptainer exec --bind .:/data "${APPTAINER_QUAST}" quast.py \
    $(printf "/data/%s " "${ASSEMBLIES_COPY[@]}") \
    -o /data/with_reference -r /data/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa \
    -g /data/Arabidopsis_thaliana.TAIR10.57.gff3 --eukaryote --large -t "${SLURM_CPUS_PER_TASK:-8}" --labels "$LABELS_STR" --no-sv
