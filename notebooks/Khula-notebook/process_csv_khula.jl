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
seqdata = CSV.read("data_ext/SequencingPrep-HIV-Samples.csv", DataFrame)

datarequest = CSV.read("data_ext/2025-03-07-KhulaDataRequest - Sheet1.csv", DataFrame) # ask about password protection

function nonunique4(x::AbstractArray{T}) where T
    status = Dict{T, Bool}()
    duplicatedvector = Vector{T}()
    for i in x
        if haskey(status, i)
            if status[i]
                push!(duplicatedvector, i)
                status[i] = false
            end
        else
            status[i] = true
        end
    end
    duplicatedvector
end


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

# Select zymo code columns into long format
zymo_df = select(datarequest, :subject_id, :zymo_code_3m, :zymo_code_6m,:zymo_code_18m, :zymo_code_12m,:zymo_code_24m)

# select id and biospecimen columns
seqprep_df = select(seqdata, :uid, :biospecimen)

# Filter out exclude == "checked" 
# ismissing_exclude = map(e-> ismissing(e), seqprep_df.exclude)

# seqprep_df = seqprep_df[ismissing_exclude, :]

# Stack dataframe based on zymo codes 
zymo_merged = stack(zymo_df, Not(:subject_id), variable_name = "timepoint", value_name = "zymo_code")
# Create mapping dictionary to make timepoint_id 
map_time = Dict(
    "zymo_code_3m" => "3mo",
    "zymo_code_6m" => "6mo",
    "zymo_code_12m" => "12mo",
    "zymo_code_18m" => "18mo",
    "zymo_code_24m" => "24mo"
)

# Apply mapping dictionary to dataframe 
zymo_merged[!, :timepoint_id] = map(t -> get(map_time, t, t), zymo_merged.timepoint)

# Drop missing zymo_code 
zymo_merged = dropmissing(zymo_merged, :zymo_code)
# Standardize zymo_code to uppercase letters 
zymo_merged[!, :zymo_code] = uppercase.(zymo_merged.zymo_code)

# Drop the rows missing biospecimen ids 
seqprep_df = dropmissing(seqprep_df, :biospecimen)
# Standardize biospecimen column to uppercase
seqprep_df[!, :biospecimen] = uppercase.(seqprep_df.biospecimen) # the same biospecimen tube can be sequenced multipletimes, repeated 

# Check for unique biospecimens 
unique(seqprep_df.biospecimen) # some of the biospecimen tubes were sequenced twice one for metatranscriptomics and metagenomics 
#923 unique biospecimen in seqprep_df but 925 total 

# Must get rid of duplicates... one of them is malawi and other is sa 
# "KMZ43460"
## Get rid of both tose rows, since it is pending resolution.
subset!(seqprep_df, :biospecimen => x -> x .!= "KMZ43460")
# "Z3MO-95875"
## Get rid of this sample for SEQPREP SEQ00467
subset!(seqprep_df, :uid => x -> x .!= "SEQ00467")

# Do inner join on zymo_code and biospecimen to get common ids 
common_ids = innerjoin(zyme_merged, seqprep_df, on = [:zymo_code => :biospecimen]) # the '=>' is a pair. sample and specimenID are the two header names that you are comparing 

# Get rid of timepoint column 
output_df = select(common_ids, Not(:timepoint))

# Export output df into csv? 

CSV.write()
