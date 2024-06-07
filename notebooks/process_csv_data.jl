# Task due June 7th: Build a table from two random csv data files 
## Include: subject (participant ID), uid (SEQ ID), subject_age, project 

using CSV 
using BiobakeryUtils
using DataFrames
using Microbiome

function process_csv(pathname::String)::DataFrame

    data = CSV.read(pathname, DataFrame)
    #Filter only malawi samples
    filtered_data = subset(data, :project => ByRow(project -> project == "malawi"); skipmissing=true)

    #List of columns that start with "subject " 
    subject_columns = [name => "subject" for name in names(filtered_data) if startswith(name, "subject ")]
    if length(subject_columns) > 1
        throw(ArgumentError("There are multiple columns that start with subject. Unclear subject column"))
    end
    rename!(filtered_data, subject_columns)
 
    #List of columns that start with "subject_age " 
    subject_age_columns = [name => "subject_age" for name in names(filtered_data) if startswith(name, "subject_age ")]
    if length(subject_age_columns) > 1
        throw(ArgumentError("There are multiple columns that start with subject_age. Unclear subject_age column"))
    end
    rename!(filtered_data, subject_age_columns)
 
    #Grab the selected columns: 
    selected_data = select(filtered_data, :uid, :subject, :subject_age, :project)
    
    #Change the format so the the begining "???-" is removed from subject id values
    result = transform(selected_data, :subject => ByRow(row_string -> split(row_string, "-")[2]) => :subject)
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

