#!/usr/bin/env bash

#SBATCH --cpus-per-task=64
#SBATCH --mem=200G
#SBATCH --time=3-00:00:00
#SBATCH --job-name=hifiasm
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --error=./errors/error_hifiasm_%j.e
#SBATCH --output=./outputs/output_hifiasm_%j.o

# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/analysis/06_hifiasm_assembly"
THREADS="${SLURM_CPUS_PER_TASK}"
APPTAINER_HIFIASM="/containers/apptainer/hifiasm_0.25.0.sif"

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

echo "Starting hifiasm assembly for accession: ${ACCESSION_NAME}"
echo "Input file: ${GENOMIC_INPUT}"
echo "Output directory: ${SAMPLE_OUTDIR}"

# --- Run hifiasm assembly ---
apptainer exec --bind /data "${APPTAINER_HIFIASM}" hifiasm \
    -o "${SAMPLE_OUTDIR}/pacbio.asm" \
    -t "${THREADS}" \
    "${GENOMIC_INPUT}"

# Check exit status
if [[ $? -eq 0 ]]; then
    echo "hifiasm assembly completed successfully for ${GENOMIC_INPUT}"
else
    echo "hifiasm assembly failed for ${GENOMIC_INPUT}"
    exit 1
fi

# --- Convert output to FASTA format ---
echo "Converting GFA to FASTA format"
awk '/^S/{print ">"$2;print $3}' "${SAMPLE_OUTDIR}/pacbio.asm.bp.p_ctg.gfa" > "${SAMPLE_OUTDIR}/${ACCESSION_NAME}_pacbio.asm.bp.p_ctg.fa"

# Check if conversion was successful
if [[ $? -eq 0 ]]; then
    echo "FASTA conversion completed successfully"
    echo "Final assembly: ${SAMPLE_OUTDIR}/${ACCESSION_NAME}_pacbio.asm.bp.p_ctg.fa"
else
    echo "FASTA conversion failed"
    exit 1
fi