#!/usr/bin/env Rscript

##############################################################
# Date Modified: 20240123
# Author: Chris Lo (chris.lowh@kcl.ac.uk)
# This bash/R script contains codes used to extract UKB biofield and genotype data with ukbkings, and maintaining a repository for variables extracated
# Note (20230928):
	# ukbkings can not be loaded in R session because of deprecation in dependencies. 
	# Need a separate script for extracting UKB biofield data
##############################################################

# print starting time
cat('The starting time for running this script is', format(Sys.time(), format = "%Y-%m-%d %H:%M:%S"), '\n')

# Load packages
# Load libraries
library(ukbkings)
library(dplyr)
library(stringr)

#----Define directories for project----
proj_dir <- "/ukbiobank/ukb82087/"
config_dir <- "/chrislo/ukb_gwas/data/biofield/config/"
data_dir <- "/chrislo/ukb_gwas/data/biofield/"
job_log_dir <- "/chrislo/ukb_gwas/data/job_logs/"

# Take out list of variables available under the project directory
f <- bio_field(proj_dir)

# Categories of variables
setwd(config_dir)
var_cat <- gsub('.txt', '', list.files(pattern='.txt'))

### --- Read in .csv file that contains variables that have already been extracted --- ###
setwd(data_dir)

if (file.exists("biofield_ukb.csv")) {
	existing <- read.csv("biofield_ukb.csv", header = TRUE)
} else {
	# create one if not
	col_df = c("name", "field_id", "variable_type", "sub_id", "txt_path", "rds_path")
	existing <- data.frame(matrix(ncol = length(col_df), nrow = 0))
	colnames(existing) = col_df
}

### --- Read in configuration files that contains variables that need to be extracted --- ###
setwd(config_dir)

for (cat in var_cat) {

	# read in configuration files
	df <- read.table(paste0(cat, ".txt"), sep = " ", header = TRUE) 

	# add one column for variable_types, if records exist
	if (nrow(df) > 0) {df$variable_type = cat}

	# assign
	assign(paste0(cat, "_new"), df)
}


### --- Pull out variables are within the list of variables we have --- ###
var_extract <- NULL

for (cat in var_cat) {

	# get configuration file
	df <- get(paste0(cat , "_new"))
	# get list of field IDs for variables that have already been extracted
	exist_id <- existing$field_id

	# only runs with there are variables, i.e.: nrow(df) > 1
	if (nrow(df) > 0) {
	for (row in 1:nrow(df)) {
	
	var_name = df[row, "name"]
	var_id = df[row, "field_id"]
	var_type = df[row, "variable_type"]
	
			# add the information to var_extract data.frame if it is not listed
			# otherwise, print warning message
			if (!(var_id %in% exist_id)) {

			var_extract <- rbind(var_extract, data.frame(name = var_name,
														 field_id = var_id,
														 variable_type = var_type))
			} else {
			print(paste0("Warning message: The variable '", var_name, "' has already been extracted with field ID ", var_id, "."))
			}
		}
	}
}


### --- Extract data from ukbkings --- ###
# empty matrix 
data_extract <- matrix(ncol = 6, nrow = 0)										

# set directory
setwd(data_dir)

	for (i in var_extract[, which(colnames(var_extract) == 'field_id')]) {
		# select which row contains respective field_id
		row = which(var_extract[, which(colnames(var_extract) == 'field_id')] == i)	

		# path for .txt holding all the biofield_id under the broad field_id										
		txt = paste0('txt/' ,var_extract[row, which(colnames(var_extract) == 'name')])
		# path for .rds file
		rds = paste0('rds/' ,var_extract[row, which(colnames(var_extract) == 'name')])
		# variable name
		name = var_extract[row, which(colnames(var_extract) == 'name')]
		# type
		type = var_extract[row, which(colnames(var_extract) == 'variable_type')]

		# print message: extracting variable
		print(paste0("Extracting variable '", name ,"' with field ID ", i, "."))
		# extract biofield using the field_id and add as .txt
		f %>%
    	select(field, name) %>%
    	filter(str_detect(field, paste0("^", i ,"-"))) %>%		# string match by field_id
    	bio_field_add(paste0(txt, '.txt'))		# add to biofield as .txt file, all stored in same directory
 			
 		# from the txt.files extract the .rds files
    	bio_phen(proj_dir, field = paste0(txt, '.txt'), out = rds)


		### --- additional check: if variable cannot be extracted, print warning message instead of reading --- ###
		rel_path = paste0(rds, '.rds')
		
		if (file.exists(rel_path)) {

    	# read .rds file
		df <- readRDS(paste0(rds, '.rds'))

		# extract column names (except eid), and merge them together
		# this variable (sub_id) contains all bio_field_ids under the broad field_id
		sub_id <- paste(colnames(df)[!grepl('eid', colnames(df))] , collapse = ';')

    # dataframe representing field_id and the path for .txt biofield file
    c <- data.frame(name = name,
					field_id = i,
					variable_type = type,
    				sub_id = sub_id,
    				txt_path = paste0("/scratch/prj/ukbiobank/usr/chrislo/ukb_gwas/data/biofield/", txt, '.txt'),			# absolute path
    				rds_path = paste0("/scratch/prj/ukbiobank/usr/chrislo/ukb_gwas/data/biofield/", rds, '.rds')			# absolute path
    				)
    # bind with empty matrix
    data_extract <- rbind(data_extract, c)

		} else {
		# print warning message if rds object does not exist
		print(paste0("Failed extraction of variable '", name, "' with field ID ", i, ". Please check your configuration files and try again."))
		}

	}

# inner join with var_extract
# var_extract <- inner_join(var_extract, path, by = 'field_id')

# Update .csv file
existing_update <- rbind(existing, data_extract)

write.csv(existing_update, 'biofield_ukb.csv', row.names = FALSE)


cat(paste0("Variable extraction done! Please check the respective log files at ", job_log_dir, "biofield.log for errors."))

# print ending time
cat('The ending time for running this script is', format(Sys.time(), format = "%Y-%m-%d %H:%M:%S"), '\n')

# quit R and clean up dockers image
q()