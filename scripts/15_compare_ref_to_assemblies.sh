#!/usr/bin/env bash

#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --job-name=MUMmer
#SBATCH --mail-user=anna.boss@students.unibe.ch
#SBATCH --partition=pibu_el8
#SBATCH --error=/data/users/aboss/assembly_annotation_course/errors/error_mummer_%j.err
#SBATCH --output=/data/users/aboss/assembly_annotation_course/outputs/output_mummer_%j.out

# --- Variables ---
WORKDIR="/data/users/${USER}/assembly_annotation_course"
OUTPUT_DIR="${WORKDIR}/analysis/13_mummer_comparison"
THREADS="${SLURM_CPUS_PER_TASK}"
REFERENCES="/data/courses/assembly-annotation-course/references"
REF_FILE="${REFERENCES}/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa"
CONTAINER="/containers/apptainer/mummer4_gnuplot.sif"

# Assembly files
ASSEMBLIES=(
    "/data/users/aboss/assembly_annotation_course/data/03_assemblies/flye_assembly_Altai-5.fasta"
    "/data/users/aboss/assembly_annotation_course/data/03_assemblies/hifiasm_assembly_Altai-5.fasta" 
    "/data/users/aboss/assembly_annotation_course/data/03_assemblies/LJA_assembly_Altai-5.fasta"
)
NAMES=("flye" "hifiasm" "LJA")

# Create directories
mkdir -p "${OUTPUT_DIR}"

# --- Step 1: Compare each assembly against reference ---
echo "=== Step 1: Assembly vs Reference Comparison ==="

for i in "${!ASSEMBLIES[@]}"; do
    ASSEMBLY="${ASSEMBLIES[i]}"
    NAME="${NAMES[i]}"
    DELTA_FILE="${OUTPUT_DIR}/${NAME}_vs_ref.delta"
    
    echo "--- Running nucmer: ${NAME} vs reference ---"
    
    apptainer exec --bind /data "${CONTAINER}" \
        nucmer \
        --threads "${THREADS}" \
        --mincluster 1000 \
        --breaklen 1000 \
        --prefix "${OUTPUT_DIR}/${NAME}_vs_ref" \
        "${REF_FILE}" \
        "${ASSEMBLY}"
    
    echo "✓ Completed: ${NAME}_vs_ref.delta"
done

# --- Step 2: Compare assemblies against each other ---
echo "=== Step 2: Assembly vs Assembly Comparison ==="

# Compare all pairs of assemblies
for i in "${!ASSEMBLIES[@]}"; do
    for j in "${!ASSEMBLIES[@]}"; do
        if [[ $i -lt $j ]]; then  # Avoid self-comparison and duplicates
            ASSEMBLY1="${ASSEMBLIES[i]}"
            ASSEMBLY2="${ASSEMBLIES[j]}"
            NAME1="${NAMES[i]}"
            NAME2="${NAMES[j]}"
            PREFIX="${OUTPUT_DIR}/${NAME1}_vs_${NAME2}"
            
            echo "--- Running nucmer: ${NAME1} vs ${NAME2} ---"
            
            apptainer exec --bind /data "${CONTAINER}" \
                nucmer \
                --threads "${THREADS}" \
                --mincluster 1000 \
                --breaklen 1000 \
                --prefix "${PREFIX}" \
                "${ASSEMBLY1}" \
                "${ASSEMBLY2}"
            
            echo "✓ Completed: ${NAME1}_vs_${NAME2}.delta"
        fi
    done
done

# --- Step 3: Generate dot plots ---
echo "=== Step 3: Generating Dot Plots ==="

# Generate plots for reference comparisons
for i in "${!ASSEMBLIES[@]}"; do
    NAME="${NAMES[i]}"
    DELTA_FILE="${OUTPUT_DIR}/${NAME}_vs_ref.delta"
    PLOT_PREFIX="${OUTPUT_DIR}/${NAME}_vs_ref_plot"
    
    echo "--- Generating plot: ${NAME} vs reference ---"
    
    apptainer exec --bind /data "${CONTAINER}" \
        mummerplot \
        -R "${REF_FILE}" \
        -Q "${ASSEMBLIES[i]}" \
        --fat \
        --layout \
        --filter \
        -t png \
        --large \
        -p "${PLOT_PREFIX}" \
        "${DELTA_FILE}"
    
    echo "✓ Plot created: ${PLOT_PREFIX}.png"
done

# Generate plots for assembly comparisons
for i in "${!ASSEMBLIES[@]}"; do
    for j in "${!ASSEMBLIES[@]}"; do
        if [[ $i -lt $j ]]; then
            NAME1="${NAMES[i]}"
            NAME2="${NAMES[j]}"
            DELTA_FILE="${OUTPUT_DIR}/${NAME1}_vs_${NAME2}.delta"
            PLOT_PREFIX="${OUTPUT_DIR}/${NAME1}_vs_${NAME2}_plot"
            
            echo "--- Generating plot: ${NAME1} vs ${NAME2} ---"
            
            apptainer exec --bind /data "${CONTAINER}" \
                mummerplot \
                -R "${ASSEMBLIES[i]}" \
                -Q "${ASSEMBLIES[j]}" \
                --fat \
                --layout \
                --filter \
                -t png \
                --large \
                -p "${PLOT_PREFIX}" \
                "${DELTA_FILE}"
            
            echo "✓ Plot created: ${PLOT_PREFIX}.png"
        fi
    done
done

# --- Final Summary ---
echo "Reference comparisons:"
for NAME in "${NAMES[@]}"; do
    echo "  ${NAME}_vs_ref.delta"
    echo "  ${NAME}_vs_ref_plot.png"
done

echo "Assembly comparisons:"
for i in "${!NAMES[@]}"; do
    for j in "${!NAMES[@]}"; do
        if [[ $i -lt $j ]]; then
            echo "  ${NAMES[i]}_vs_${NAMES[j]}.delta"
            echo "  ${NAMES[i]}_vs_${NAMES[j]}_plot.png"
        fi
    done
done

echo "Total comparisons:"
echo "  $(ls ${OUTPUT_DIR}/*.delta | wc -l) delta files"
echo "  $(ls ${OUTPUT_DIR}/*.png | wc -l) plot files"

echo "Job completed at: $(date)"