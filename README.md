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

Description on directories

1. exe: Bash script executables, and R script responsible for biofield extraction.

2. config: Configuration .txt files in which variable names and field ids can be added. Note they have to be separated in space, i.e.: " ". 
	   The names of .txt files will be 'variable categories' that were shown on the biofield_ukb.csv file.
	   If new variable category descriptions are required, create new .txt file with same format on first row as others.

3. rds: RDS object files containing variables extracted using ukbkings. Can be read into R workspace directly.

4. txt: .txt files containing sub biofield IDs within each biofield id.

5. job_logs: Job execution logs for variable extraction.
