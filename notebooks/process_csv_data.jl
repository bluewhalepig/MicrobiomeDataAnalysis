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

    #Grab the selected columns 
    selected_data = select(filtered_data, :uid, :subject, :subject_age, :project)
    result = selected_data.subject = replace.(selected_data.subject, "malawi-" => "") 
    return result

end

#Load all the data from csv files in the directiory data_ext 
csv_files = filter(f -> endswith(f, ".csv"), readdir("data_ext"))

#Process each CSV file and store in dataframe
dataframes = []
for file in csv_files
    file_path = joinpath("data_ext/", file)
    try
        df = process_csv(file_path)
        push!(dataframes, df)  # Add the processed DataFrame to the list
    catch e
        println("Error processing $file_path: $e")
    end
end


