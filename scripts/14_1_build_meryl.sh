#!/usr/bin/env bash

#SBATCH --time=1-00:00:00
#SBATCH --mem=100G
#SBATCH --cpus-per-task=16
#SBATCH --job-name=meryl
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_meryl_%j.e
#SBATCH --output=./outputs/output_meryl_%j.o


# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/analysis/12_merqury_results"
THREADS="${SLURM_CPUS_PER_TASK}"
APPTAINER_MERQURY="/containers/apptainer/merqury_1.3.sif"
export MERQURY="/usr/local/share/merqury"
MERYL_DB="${OUTPUT_DIR}/pacbio.meryl"

# create output directory
mkdir -p ${OUTPUT_DIR}

# Input files
PACBIO_READS="/data/users/aboss/assembly_annotation_course/data/01_raw_data/Altai-5/ERR11437324.fastq.gz"
ASSEMBLIES=(
    "/data/users/aboss/assembly_annotation_course/data/03_assemblies/flye_assembly_Altai-5.fasta"
    "/data/users/aboss/assembly_annotation_course/data/03_assemblies/hifiasm_assembly_Altai-5.fasta" 
    "/data/users/aboss/assembly_annotation_course/data/03_assemblies/LJA_assembly_Altai-5.fasta"
)
NAMES=("flye" "hifiasm" "LJA")


# --- Step 1: Find best K --- 
echo "--- Step 1: Finding best K value ---"
GENOME_SIZE=135000000  
TOLERABLE_RATE=0.001

BEST_K=$(apptainer exec --bind $PROJECT_DIR $APPTAINER_MERQURY \
sh $MERQURY/best_k.sh $GENOME_SIZE | tail -1 | awk '{printf "%.0f", $1}')
echo "Best K-mer size: $BEST_K"

# Update MERYL_DB with the actual K value
MERYL_DB="${OUTPUT_DIR}/pacbio_k${BEST_K}.meryl"

# --- Step 2: Build k-mer database --- 
echo "--- Step 2: Building k-mer database with k=$BEST_K ---"
apptainer exec --bind $PROJECT_DIR $APPTAINER_MERQURY \
meryl k=$BEST_K count "${PACBIO_READS}" output $MERYL_DB

# Create histogram for quality filtering
echo "Creating k-mer histogram..."
apptainer exec --bind $PROJECT_DIR $APPTAINER_MERQURY \
meryl histogram "${MERYL_DB}" > "${MERYL_DB}.hist"
    
# Get database statistics
echo "Meryl database statistics:"
apptainer exec --bind $PROJECT_DIR $APPTAINER_MERQURY \
meryl statistics "${MERYL_DB}" | head -10



