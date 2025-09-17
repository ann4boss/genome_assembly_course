#!/usr/bin/env bash

#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --job-name=fastp_cleaning
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_cleaning_%j.e
#SBATCH --output=./outputs/output_cleaning_%j.o
#SBATCH --array=0-1  #adjust according to number of samples!!
#SBATCH --ntasks=1

# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
DATA_DIR="${PROJECT_DIR}/data/01_raw_data"
OUTPUT_DIR="${PROJECT_DIR}/analysis/02_cleaning_results"
APPTAINER_FASTP="/containers/apptainer/fastp_0.23.2--h5f740d0_3.sif"
APPTAINER_FASTQC="/containers/apptainer/fastqc-0.12.1.sif"

# Create directories if they don’t exist
mkdir -p "${DATA_DIR}" "${OUTPUT_DIR}"

# --- Samples ---
SAMPLES=("Altai-5" "RNAseq_Sha")

# --- Get sample for current SLURM array task ---
SAMPLE="${SAMPLES[$SLURM_ARRAY_TASK_ID]}"
echo "Processing sample: ${SAMPLE}"

# Collect all FASTQ files in the sample folder
FASTQ_FILES=(${DATA_DIR}/${SAMPLE}/*.fastq.gz)

if [[ ! -e "${FASTQ_FILES[0]}" ]]; then
    echo "No FASTQ files found for sample ${SAMPLE} — skipping."
    exit 1
fi

# Determine if paired-end or single-end based on number of files
if [[ ${#FASTQ_FILES[@]} -eq 1 ]]; then
    READ1="${FASTQ_FILES[0]}"
    READ2=""
elif [[ ${#FASTQ_FILES[@]} -eq 2 ]]; then
    READ1="${FASTQ_FILES[0]}"
    READ2="${FASTQ_FILES[1]}"
else
    echo "More than 2 FASTQ files found for sample ${SAMPLE}. Please check naming."
    exit 1
fi

# --- Run fastp ---
# Run fastp for cleaning with following settings:
# detect_adapter_for_pe: Automatically detects and removes adapter sequences for paired-end reads
# low_complexity_filter: Filters out reads with low complexity, such as repetitive genomic regions, Sequencing artifacts or errors, or Adapter contamination or other technical issues
# complexity_threshold: Sets the threshold for low-complexity filtering, default 30% complexity
# overrepresentation_analysis: Analyzes and reports overrepresented sequences, such as PCR duplicates or contaminants
# qualified_quality_phred: Sets the Phred quality score threshold for base qualification (bases with quality < 15 are considered unqualified)
# cut_tail -q 20: Trims low-quality bases from the tail of reads (quality < 20).
# unqualified_percent_limit 40: Discards reads if more than 40% of their bases are unqualified (quality < 15).
# length_required 50: Discards reads shorter than 50 bases after trimming -> minimizes ambiguity in mapping
# n_base_limit 1: Discards reads with more than 1 ambiguous base (N)
# dedup: Removes duplicate reads
# correction: Enables base correction for overlapping regions in paired-end reads.
echo "Running fastp for sample: ${SAMPLE}"
if [[ -n "$READ2" ]]; then
    apptainer exec --bind "${DATA_DIR}","${OUTPUT_DIR}" "${APPTAINER_FASTP}" \
        fastp -i "${READ1}" -I "${READ2}" \
        -o "${OUTPUT_DIR}/${SAMPLE}_cleaned_R1.fastq.gz" \
        -O "${OUTPUT_DIR}/${SAMPLE}_cleaned_R2.fastq.gz" \
        -t 4 \
        --detect_adapter_for_pe \
        --low_complexity_filter \
        --complexity_threshold 30 \
        --overrepresentation_analysis \
        --qualified_quality_phred 15 \
        --cut_tail -q 20 \
        --unqualified_percent_limit 40 \
        --length_required 50 \
        --n_base_limit 1 \
        --dedup \
        --correction \
        --html "${OUTPUT_DIR}/${SAMPLE}_fastp_report.html" \
        --json "${OUTPUT_DIR}/${SAMPLE}_fastp_report.json"
else # without filtering!
    apptainer exec --bind "${DATA_DIR}","${OUTPUT_DIR}" "${APPTAINER_FASTP}" \
        fastp -i "${READ1}" \
        -o "${OUTPUT_DIR}/${SAMPLE}_cleaned.fastq.gz" \
        -t 4 \
        --disable_length_filtering \
        --html "${OUTPUT_DIR}/${SAMPLE}_fastp_report.html" \
        --json "${OUTPUT_DIR}/${SAMPLE}_fastp_report.json"
fi

# --- Run FastQC on cleaned reads ---
echo "Running FastQC on cleaned reads for sample: ${SAMPLE}"
CLEANED_FILES=(${OUTPUT_DIR}/${SAMPLE}_cleaned*.fastq.gz)
apptainer exec "${APPTAINER_FASTQC}" fastqc \
    -t "${SLURM_CPUS_PER_TASK}" \
    -o "${OUTPUT_DIR}" \
    "${CLEANED_FILES[@]}"

if [[ $? -eq 0 ]]; then
    echo "FastQC completed successfully for ${SAMPLE}."
else
    echo "FastQC failed for ${SAMPLE}."
fi
