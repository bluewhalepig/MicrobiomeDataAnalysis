# Task due June 7th: Build a table from two random csv data files 
## Include: subject (participant ID), uid (SEQ ID), subject_age, project 

using CSV 
using BiobakeryUtils
using DataFrames
using Microbiome

# First: read and figure out what is in both files.269x269

table01 = CSV.read("data_ext/Biospecimens.csv", DataFrame; stringtype = String)
## table 01 has uid, loolks like a bunch of Biospeimen IDs, they lookf like FEXXXXX. I do now know wha t a Biospecimen is. note: ask what a Biospecimen is..269x269
## table 01 has subject (! i need subject !)
## table 01 has project (project is a string, and has ["resonance", "lake_waban", missing, "khula", "march"] ), I dont know what any onf those names mean. Not: ask.
## tabke 01 has subject_age. already numerical.
## table 01 has collection. it is a bunch on integer numbers. Values are [missing, 2, 1, 4, 3, 9, 5, 12, 6, 8, 7, 10, 11, 13]. I dont know what it means.
## table 01 has seqprer, loolks like a bunch of IDs, they lookf like SEQXXXXX. I do now know what a seqprer is, but i need it (!!!)
## table 01 has aliases, its a string, it has a bunch of character notations, loks like IDS, i still dont know what the IDs mean.
## table 01 has visit. It looks like it encodes the time of collection, like "3 months". "6 months" and so on.


table02 = CSV.read("data_ext/SequencingPrep.csv", DataFrame; stringtype = String)
## table 02 has uid, loolks like a bunch of SEQ IDs, they look like SEQXXXXX. I do now know what a SEQID is, but i need it (!!!)
## table 02 has subject (! i need subject !)
## table 02 has project (project is a string, and has ["resonance", "lake_waban", missing, "khula", "march"] ), I dont know what any onf those names mean. Not: ask.
## tabke 02 has subject_age. already numerical.
## table 02 has collection. it is a bunch on integer numbers. Values are [missing, 2, 1, 4, 3, 9, 5, 12, 6, 8, 7, 10, 11, 13]. I dont know what it means.
## table 02 has seqprep, loolks like a bunch of IDs, they lookf like SEQXXXXX. I do now know what a seqprer is, but i need it (!!!)
## table 02 has aliases, its a string, it has a bunch of character notations, loks like IDS, i still dont know what the IDs mean.
## table 01 has visit. It looks like it encodes the time of collection, like "3 months". "6 months" and so on.


#Store the seqids in both files in their own tables 
seqids_in_table01 = table01.seqprep 
seqids_in_table02 = table02.uid

#Find all the seqids that are in both tables
sum(Set(seqids_in_table01) .∈ Ref(Set(seqids_in_table02))) #number of things that are in both tables
#There are 3079 seqids that are in both 


function process_Biospecimens_csv(table01)::DataFrame
    data = table01  

    #Filter only malawi samples in sample_site column 
    filtered_data = subset(data, :sample_site => ByRow(sample_site -> sample_site == "malawi"); skipmissing=true)
    
    #Fixing colun names so that they are consistent across all data frames
    fixing_columns!(filtered_data, "seqid", "seqprep")
    fixing_columns!(filtered_data, "biospecimen_id", "uid")
    dropmissing!(filtered_data, :seqid)
    dropmissing!(filtered_data, :biospecimen_id)
    #Grab the selected columns  
    selected_data = select(filtered_data, :seqid, :biospecimen_id)
    
    return selected_data
end


function process_SequencingPrep_csv(table02)::DataFrame
    data = table02

    #Change name of sample_site column so that it can be filtered by malawi 
    fixing_columns!(data, "sample_site", "sample_site ")

    #Filter only malawi samples
    filtered_data = subset(data, :sample_site => ByRow(sample_site -> sample_site == "malawi"); skipmissing=true)

    #Fixing colun names so that they are consistent across all data frames
    fixing_columns!(filtered_data, "subject", "subject ")
    fixing_columns!(filtered_data, "subject_age", "subject_age ")
    fixing_columns!(filtered_data, "seqid", "uid")
    dropmissing!(filtered_data, :seqid)

    #Grab the selected columns: 
    selected_data = select(filtered_data, :seqid, :subject, :subject_age, :sample_site)
    
    return selected_data
end

function fixing_columns!(filtered_data::DataFrame, new_column_name, old_column_prefix)::DataFrame
    columns = [name => new_column_name for name in names(filtered_data) if startswith(name, old_column_prefix)]
    #Throw an error if there are 
    if length(columns) > 1
        throw(ArgumentError("There are multiple columns that start with $old_column_prefix. Unclear $new_column_name column"))
    end
    rename!(filtered_data, columns)
    return filtered_data
end

#Process loaded datatables with functions created
processed_table01 = process_Biospecimens_csv(table01) 
#526 rows 

processed_table02 = process_SequencingPrep_csv(table02)
#535 rows

#Number of same seqids that are in both sets: 517
sum(Set(processed_table01.seqid) .∈ Ref(Set(processed_table02.seqid)))

#Combine all the processed dataframes into one on seqid 
concatenated_data = innerjoin(processed_table01, processed_table02, on = :seqid)


#Checking concatenated_data..it has 517 elements and all are unique
unique(concatenated_data.seqid)

#Save the dataframe into output csv file 
CSV.write("data_ext/processed_output.csv", concatenated_data)

