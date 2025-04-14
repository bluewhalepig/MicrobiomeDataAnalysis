# We need to know the SEQ IDs of the samples we are working with on this project.

# Context: We change all project-specific Biospecimen IDs to SEQ00000-form IDs internally. However, metadata refers to the project-specific ID.

# Intended output: a dataframe with 3 columns:

# Timepoint_id: { 3mo, 6mo, 12mo, 18mo, 24mo }
# SEQ_id: a collection of IDs of the form SEQ00000
# Zymo_code: a collection of IDs of the form ZXMO-00000

# Spoilers
# There are 5 columns (zymo_code_3mo, zymo_code_6mo).... That you will have to collect and concatenate
# Hint: This is a good moment to append the Timpoint_id to the table

#Select the adequate rows of the SEQPREP table
##Perform a join
#Remember the case problem with the lowercase/uppercase letters
#QC the join
#Are there duplicates in any column?
#If yes, gather a list of duplicates to discuss 

# Load libraries 
using CSV
using DataFrames 
using CairoMakie 

#####
# STEP 1: organize the relationship table between subject, zymocode, timepoint and sample ID.
#####

# Import Sequencing metadata and datarequest table from KHULA 

datarequest = CSV.read("data_ext/2025-03-07-KhulaDataRequest - Sheet1.csv", DataFrame) # ask about password protection

# Select zymo code columns 
zymo_df = select(datarequest, :zymo_code_3m, :zymo_code_6m,:zymo_code_18m, :zymo_code_12m,:zymo_code_24m)

# select id and biospecimen columns
seqprep_df = select(seqdata, :uid, :biospecimen, :exclude)

# #Data summary 
    # length(unique(datarequest.subject_id)) #394
    # total_number_of_infants =nrow(datarequest) #394 infants 

    # # number of mothers with HIV medhx_mom 
    # unique(datarequest.medhx_mom___1_selfreport)
    # number_of_infants_with_maternalHIV = count(status -> status == 1, skipmissing(datarequest.unique(datarequest.medhx_mom___1_selfreport)))
    # percent = number_of_infants_with_maternalHIV / total_number_of_infants #.358
    #     #33.7% infants with HIV+ mothers (selfreport)

    # #number of mothers with HIV-1 
    # number_of_HIV1 = count(status -> status == 1, skipmissing(datarequest.hiv_mom_diagnosed_selfreport))
    #     #92 which means 65.2% of the HIV+ mothers have strain 1 
    #     number_of_HIV1 / number_of_infants_with_maternalHIV
    # number_of_HIV2 = count(status -> status == 2, skipmissing(datarequest.hiv_mom_diagnosed_selfreport))
    #     #16 which means 11.3% 
    #     number_of_HIV2 / number_of_infants_with_maternalHIV
    # number_of_HIV3 =count(status -> status == 3, skipmissing(datarequest.hiv_mom_diagnosed_selfreport))
    #     #3 which means 
    #     number_of_HIV3 / number_of_infants_with_maternalHIV
    # unique(datarequest.hiv_mom_diagnosed_selfreport)
    # (3+16+92)/394

# Merged zymo dataframe
zyme_merged = stack(zymo_df, Not([]), variable_name = "timepoint", value_name = "zymo_code")

map_time = Dict(
    "zymo_code_3m" => "3mo",
    "zymo_code_6m" => "6mo",
    "zymo_code_12m" => "12mo",
    "zymo_code_18m" => "18mo",
    "zymo_code_24m" => "24mo"
)

# Apply this mapping to the timepoint column
zyme_merged[!, :timepoint_id] = map(t -> get(map_time, t, t), zyme_merged.timepoint)

#Drop missing zymo_code 
zyme_merged = dropmissing(zyme_merged, :zymo_code)
# Standardize zymo_code to uppercase 
zyme_merged[!, :zymo_code] = uppercase.(zyme_merged.zymo_code)

#Drop missing
seqprep_df = dropmissing(seqprep_df, :biospecimen)
# Standardize biospecimen column to uppercase
seqprep_df[!, :biospecimen] = uppercase.(seqprep_df.biospecimen) # the same biospecimen tube can be sequenced multipletimes, repeated 

# check for unique 
unique(seqprep_df.biospecimen) # some of the biospecimen tubes were sequenced twice one for metatranscriptomics and metagenomics 
unique(seqprep_df.exclude)

#3671
#3777 # 

# Do inner join on zymo_code and biospecimen to get common ids 
common_ids = innerjoin(zyme_merged, seqprep_df, on = [:zymo_code => :biospecimen]) # the '=>' is a pair. sample and specimenID are the two header names that you are comparing 

# Get rid of timepoint column 
output_df = select(common_ids, Not(:timepoint))

# Export output df into csv? 

CSV.write()
