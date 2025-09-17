#!/usr/bin/env bash

#NOT CHECKED!!!

#SBATCH --time=1-00:00:00
#SBATCH --mem=100G
#SBATCH --cpus-per-task=16
#SBATCH --job-name=mercury
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --mail-type=end
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_mercury_%j.e
#SBATCH --output=./outputs/output_mercury_%j.o


# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/analysis/12_mercury_results"
THREADS="${SLURM_CPUS_PER_TASK}"
APPTAINER_MERCURY="/containers/apptainer/merqury_1.3.sif"


# Check if FASTQ_FILE is provided as an argument, otherwise exit with usage message
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then # || [ -z "$3" ]
  echo "Usage: $0 <path_to_fastq_file>"
  exit 1
fi

ASSEMBLY_FLYE=$1
ASSEMBLY_HIFIASM=$2
#ASSEMBLY_LJA=$3
PACBIO=$3

# create output directory
mkdir -p ${OUTPUT_DIR}


export MERQURY="/usr/local/share/merqury"

mkdir -p $OUTPUT_DIR 
# Count k-mer frequencies
# k=19 based on  output
K=19
apptainer exec --bind $WORKDIR $CONTAINER_DIR \
meryl k=$K count ${PACBIO} output $OUTPUT_DIR/genome.meryl

cd $OUTPUT_DIR

apptainer exec --bind $WORKDIR $CONTAINER_DIR \
sh $MERQURY/merqury.sh $OUTPUT_DIR/genome.meryl ${ASSEMBLY_FLYE} flye

apptainer exec --bind $WORKDIR $CONTAINER_DIR \
sh $MERQURY/merqury.sh $OUTPUT_DIR/genome.meryl ${ASSEMBLY_HIFIASM} hifiasm

apptainer exec --bind $WORKDIR $CONTAINER_DIR \
sh $MERQURY/merqury.sh $OUTPUT_DIR/genome.meryl ${ASSEMBLY_LJA} lja