#!/bin/bash
#SBATCH -N 1
#SBATCH -t 6:00:00
#SBATCH --partition=cpu
#SBATCH --job-name=biofield
#SBATCH --output=/scratch/prj/ukbiobank/usr/chrislo/ukb_gwas/data/biofield/job_logs/biofield.log

##############################################################
# Date Modified: 20240123
# Author: Chris Lo (chris.lowh@kcl.ac.uk)
# This bash/R script contains codes used to extract UKB biofield and genotype data with ukbkings
# Note (20230928):
	# ukbkings can not be loaded in R session because of deprecation in dependencies. 
	# Manual edits / checks:
		# Check on biofield_ukb.csv to confirm the variables have not been extracted yet (but there will be checks in the R script)
		# Edit configuration files:
			# Field ID
			# Name (as you want)
##############################################################


lock_file="/scratch/prj/ukbiobank/usr/chrislo/ukb_gwas/data/biofield/exe/biofield.lock"

# Check if the lock file exists
if [ -f "$lock_file" ]; then
    echo "Biofield extraction script is currently run by other users. Try again later."
    exit 1
fi

# Create the lock file
touch "$lock_file"

# Run ukbkings in docker container and call R script
singularity exec --bind /scratch/prj/ukbiobank/usr/chrislo:/chrislo,/datasets/ukbiobank:/ukbiobank docker://onekenken/ukbkings:0.2.3 Rscript /chrislo/ukb_gwas/data/biofield/exe/biofield.R

# Doing it interactively
#singularity run --bind /scratch/prj/ukbiobank/usr/chrislo:/chrislo,/datasets/ukbiobank:/ukbiobank docker://onekenken/ukbkings:0.2.3


# Remove lock file after extraction
rm "$lock_file"
