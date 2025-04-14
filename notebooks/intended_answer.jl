# Task due June 7th: Build a table from two random csv data files 
## Include: subject (participant ID), uid (SEQ ID), subject_age, project 

using CSV 
using BiobakeryUtils
using DataFrames
using Microbiome


## What I expected to be done:

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
## table 01 has ....

table02 = CSV.read("data_ext/SequencingPrep.csv", DataFrame; stringtype = String)
## table 02 has uid, loolks like a bunch of SEQ IDs, they look like SEQXXXXX. I do now know what a SEQID is, but i need it (!!!)
## table 02 has subject (! i need subject !)
## table 02 has project (project is a string, and has ["resonance", "lake_waban", missing, "khula", "march"] ), I dont know what any onf those names mean. Not: ask.
## tabke 02 has subject_age. already numerical.
## table 02 has collection. it is a bunch on integer numbers. Values are [missing, 2, 1, 4, 3, 9, 5, 12, 6, 8, 7, 10, 11, 13]. I dont know what it means.
## table 02 has seqprer, loolks like a bunch of IDs, they lookf like SEQXXXXX. I do now know what a seqprer is, but i need it (!!!)
## table 02 has aliases, its a string, it has a bunch of character notations, loks like IDS, i still dont know what the IDs mean.
## table 01 has visit. It looks like it encodes the time of collection, like "3 months". "6 months" and so on.
## table 01 has ....

#####
# NEVER ASSUME IF YOU CAN TEST
#####

seqids_in_table_01 = table01.var"sequencing_batch (from seqprep)"
seqids_in_table_02 = table02.uid

set(seqids_in_table_01) .∈ Ref(set(seqids_in_table_02))


function process_Biospecimens_csv(pathname::String)::DataFrame
    #Load data
    data = CSV.read(pathname, DataFrame)

    #Filter only malawi samples in sample_site collumn
    filtered_data = subset(data, :sample_site => ByRow(sample_site -> sample_site == "malawi"); skipmissing=true)
    
    #Grab the selected columns: 
    selected_data = select(filtered_data, :uid, :subject, :subject_age, :sample_site)
    
    return selected_data
    
end

function process_SequencingPrep_csv(pathname::String)::DataFrame
    #Load data
    data = CSV.read(pathname, DataFrame)

    #Change name of sample_site column so that it can be filtered by malawi 
    fixing_columns!(data, "sample_site", "sample_site ")

    #Filter only malawi samples
    filtered_data = subset(data, :sample_site => ByRow(sample_site -> sample_site == "malawi"); skipmissing=true)

    #Fixing colun names so that they are consistent across all data frames
    fixing_columns!(filtered_data, "subject", "subject ")
    fixing_columns!(filtered_data, "subject_age", "subject_age ")

    #Grab the selected columns: 
    selected_data = select(filtered_data, :uid, :subject, :subject_age, :sample_site)
    
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

#Process the data
table_01 = process_Biospecimens_csv("data_ext/Biospecimens.csv")
table_02 = process_SequencingPrep_csv("data_ext/SequencingPrep.csv")
#Combine all the processed dataframes into one 
#concatenated_data = outerjoin(table_01, table_02, on = [:uid => :uid])
concatenated_data = vcat(table_01, table_02)

#Save the dataframe into output csv file 
CSV.write("data_ext/processed_output.csv", concatenated_data)


#=
function process_csv(pathname::String)::DataFrame
    data = CSV.read("data_ext/SequencingPrep.csv", DataFrame)
    #print(names(data))

    #Filter only malawi samples
    filtered_data = subset(data, :sample_site => ByRow(sample_site -> sample_site == "malawi"); skipmissing=true)

    #Fix column names 
    fixing_columns!(filtered_data, "subject", "subject ")
    fixing_columns!(filtered_data, "subject_age", "subject_age ")
    fixing_columns!(filtered_data, "sample_site", "sample_site ")

    # subject_columns = [name => "subject" for name in names(filtered_data) if startswith(name, "subject ")]
    # Throw an error if there are 
    # if length(subject_columns) > 1
    #     throw(ArgumentError("There are multiple columns that start with subject. Unclear subject column"))
    # end
    # rename!(filtered_data, subject_columns)
 
    # #List of columns that start with "subject_age " 
    # subject_age_columns = [name => "subject_age" for name in names(filtered_data) if startswith(name, "subject_age ")]
    # if length(subject_age_columns) > 1
    #     throw(ArgumentError("There are multiple columns that start with subject_age. Unclear subject_age column"))
    # end
    # rename!(filtered_data, subject_age_columns)
 
    #Grab the selected columns: 
    selected_data = select(filtered_data, :uid, :subject, :subject_age, :sample_site)
    
    #Change the format so the the begining "???-" is removed from subject id values
    #result = transform(selected_data, :subject => ByRow(row_string -> split(row_string, "-")[2]) => :subject)
    return result

end

#Load all the data from csv files in the directiory data_ext 
csv_files = filter(f -> endswith(f, ".csv"), readdir("data_ext"))

#Process each CSV file and store in dataframe
dataframes = []
for file in csv_files
    file_path = joinpath("data_ext/", file)
    try
        result_dataframe = process_csv(file_path)
        push!(dataframes, result_dataframe)  # Add the processed DataFrame to the list
        println("done")
    catch e
        println("Error processing $file_path: $e")
    end
end

#Combine all the processed dataframes into one 
concatenated_data = vcat(dataframes)
#Save the dataframe into output csv file 
CSV.write("data_ext/processed_output.csv", concatenated_data)



