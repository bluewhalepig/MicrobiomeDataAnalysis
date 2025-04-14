#############################################

# Script for a stacked bar plot of genus abundance data 
# Stratified by AGE categories 

#############################################
using Leap #must be in Project mode start terminal by:  julia --project=.
using CSV
using DataFrames
using CairoMakie 
using MultivariateStats
using ColorSchemes
using Statistics

# Load the csv data into matrix 
data = CSV.read("data_ext/sample_data.csv", DataFrame) #contains both metadata and abundance data 

# Select subject, ageMonths, and abundances for dataset
dataset = select(data, Not(:cogScore, :timepoint, :education)) #168 columns 


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
genus_dataset = select(dataset, [:subject])  # want to keep subject and sex col

# Get unique genera names 
genera = unique(values(genus_mapping))

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

# Check first 6 rows of dataset 
first(genus_dataset, 6)

age_categories = String["0-50mo", "50-100mo",">100"]
#ages: min  18.0329, max: 119.526 


# Store the real_age and age_category associated with real_age in a dictionary: 
month_mapping = Dict() 

# !!!!!!!!!! This month_mapping dictionary is not mapping ages to category (values outside of range 18-120 months)
for index in 1:length(dataset.ageMonths)
  if dataset[index,:ageMonths] <= 50 #ages less than 3mo 
    month_mapping[index] = "0-50mo"
  elseif dataset[index,:ageMonths] <= 100
    month_mapping[index] = "50-100mo"
  else 
    month_mapping[index] = ">100mo"
  end
end 

# Sum up genus abundance columns based on same category... iterate through dictionary 
category = age_categories[1]

for category in age_categories
  # Find all ages that belong to this category
  cat_columns = [age for age in keys(month_mapping) if month_mapping[age] == category]

  # Extract select species columns 
  @show age_extracted = dataset[!, cat_columns]

end 


# Compute mean abundance for each sex category (group by sex)
mean_abundance = combine(groupby(genus_dataset, :ageMonths)) do df
    DataFrame([mean(df[:, col]) for col in genera]', genera)  # compute the means 
end
