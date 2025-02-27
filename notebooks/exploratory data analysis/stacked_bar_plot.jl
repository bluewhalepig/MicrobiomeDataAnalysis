#############################################

# Script for a stacked bar plot of genus abundance data 

#############################################

using Leap #must be in Project mode start terminal by:  julia --project=.
using CSV
using DataFrames
using Distances
using CairoMakie 
using MultivariateStats
using ColorSchemes

# Load the csv data into matrix 
data = CSV.read("data_ext/sample_data.csv", DataFrame) 

# Select subject, sex, and abundances for dataset
dataset = select(data, Not(:cogScore, :timepoint, :education, :ageMonths)) #168 columns 


# Store the species and genus associated with species in a dictionary: 
genus_mapping = Dict() 
for col in names(dataset)
    if occursin("_", col)
        genus = split(col, "_")[1]  # extract genus (first part)
        genus_mapping[col] = genus  # makes it so that species -> genus
    end
end
    # keys are species 
    # values are genus 

# New dataframe for sex, genus abundance dataset (later add genus abundance)
genus_dataset = select(dataset, [:subject, :sex])  # want to keep subject and sex col

# Get unique genera names 
genera = unique(values(genus_mapping)

# Sum up species columns based on same genus 

for genus in genera
    # Find all species columns that belong to this genus
    species_columns = [species for species in keys(genus_mapping) if genus_mapping[species] == genus]
    #print(species_columns)

    # Extract select species columns 
    species_extracted = dataset[!, species_columns]

    # Transform species data frame into matrix
    species_matrix = Matrix(species_extracted) 
    
    # Sum across species columns 
    genus_sums = sum(species_matrix, dims=2) 
    #print(genus_sums) #all the genus abundances 

    # Make into 1D vector to insert data back into a column
    genus_sums_vector = genus_sums[:, 1]  
    #print(genus_sums_vector) 

    # Store the genus abundances in the genus dataset
    genus_dataset[!, genus] = genus_sums_vector 
end 

