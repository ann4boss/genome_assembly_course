#!/usr/bin/env bash


#SBATCH --time=1-00:00:00
#SBATCH --mem=100G
#SBATCH --cpus-per-task=16
#SBATCH --job-name=merqury
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_merqury_%j.e
#SBATCH --output=./outputs/output_merqury_%j.o


# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/analysis/12_merqury_results"
THREADS="${SLURM_CPUS_PER_TASK}"
APPTAINER_MERQURY="/containers/apptainer/merqury_1.3.sif"
export MERQURY="/usr/local/share/merqury"
MERYL_DB="${OUTPUT_DIR}/pacbio_k18.meryl"

# create output directory
mkdir -p ${OUTPUT_DIR}

# Input files
PACBIO_READS="/data/users/aboss/assembly_annotation_course/data/01_raw_data/Altai-5/ERR11437324.fastq.gz"
ASSEMBLIES=(
    "${PROJECT_DIR}/data/03_assemblies/flye_assembly_Altai-5.fasta"
    "${PROJECT_DIR}/data/03_assemblies/hifiasm_assembly_Altai-5.fasta" 
    "${PROJECT_DIR}/data/03_assemblies/LJA_assembly_Altai-5.fasta"
)
NAMES=("flye" "hifiasm" "LJA")



# --- Run Merqury on all assemblies ---
for i in "${!ASSEMBLIES[@]}"; do
    ASSEMBLY="${ASSEMBLIES[$i]}"
    NAME="${NAMES[$i]}"
    ASSEMBLY_OUTPUT="${OUTPUT_DIR}/${NAME}"
    
    echo "Processing $NAME assembly: $ASSEMBLY"
    
    # Create fresh output directory for this assembly
    mkdir -p "${ASSEMBLY_OUTPUT}"
    
    # Run Merqury with explicit output prefix
    echo "Running Merqury for $NAME..."
    
    # Change to output directory and run from there to avoid path issues
    cd "${ASSEMBLY_OUTPUT}"
    
    apptainer exec --bind /data:/data --pwd "${ASSEMBLY_OUTPUT}" $APPTAINER_MERQURY \
    bash -lc "merqury.sh $MERYL_DB $ASSEMBLY ${NAME}"
    
    # Check if Merqury generated the expected files
    echo "Checking output files for $NAME:"
    ls -la "${ASSEMBLY_OUTPUT}/" | head -10
    
    echo "Completed Merqury for $NAME"
done

# Return to original directory
cd "${OUTPUT_DIR}"