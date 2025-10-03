#!/usr/bin/env bash

#SBATCH --time=01:00:00
#SBATCH --mem=10G
#SBATCH --cpus-per-task=4
#SBATCH --job-name=plot_busco
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --partition=pibu_el8
#SBATCH --error=./errors/error_plot_busco_%j.e
#SBATCH --output=./outputs/output_plot_busco_%j.o


# --- Variables ---
PROJECT_DIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${PROJECT_DIR}/analysis/10_busco_plots"
THREADS="${SLURM_CPUS_PER_TASK}"

module load BUSCO/5.4.2-foss-2021a

# Check if BUSCO summary files are provided as arguments
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
  echo "Usage: $0 <flye_busco_summary> <hifiasm_busco_summary> <lja_busco_summary> <trinity_busco_summary>"
  echo "Example: $0 flye_summary.txt hifiasm_summary.txt lja_summary.txt trinity_summary.txt"
  exit 1
fi

FLYE_BUSCO_SUMMARY=$1
HIFIASM_BUSCO_SUMMARY=$2
LJA_BUSCO_SUMMARY=$3
TRINITY_BUSCO_SUMMARY=$4

mkdir -p "${OUTPUT_DIR}"
cd "${OUTPUT_DIR}"

# Copy BUSCO summary files to output directory with proper names
echo "Copying BUSCO summary files..."
cp "${FLYE_BUSCO_SUMMARY}" "short_summary.specific.brassicales_odb10.flye.txt"
cp "${HIFIASM_BUSCO_SUMMARY}" "short_summary.specific.brassicales_odb10.hifiasm.txt"
cp "${LJA_BUSCO_SUMMARY}" "short_summary.specific.brassicales_odb10.lja.txt"
cp "${TRINITY_BUSCO_SUMMARY}" "short_summary.specific.brassicales_odb10.trinity.txt"

# Download the generate_plot.py script from GitLab (correct URL)
wget -O generate_plot.py "https://gitlab.com/ezlab/busco/-/raw/5.4.2/scripts/generate_plot.py"

# Check if download was successful
if [ ! -f "generate_plot.py" ]; then
    echo "Error: Failed to download generate_plot.py"
    exit 1
fi

# Run the plot generation
python3 generate_plot.py -wd "${OUTPUT_DIR}"