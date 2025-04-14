using Leap #must be in Project mode start terminal by:  julia --project=.
using CSV
using DataFrames
using CairoMakie 
using MultivariateStats
using ColorSchemes
using Statistics

#Grab the processed KHULA sample csv data 
dataset = CSV.read("data/HIVmetadata_and_abundance_ZYM.csv", DataFrame)


abundance_data = select(dataset, Not(:subject_id,:uid, :zymo_code, :timepoint_id, :mom_arv_selfreport, :baby_arv_selfreport, :medhx_mom___1_selfreport, :mother_hiv_status_phdc))

genus_mapping = Dict() 
for col in names(abundance_data)
    if occursin("_", col)
        genus = split(col, "_")[1]  # extract genus (first part)
        genus_mapping[col] = genus  # makes it so that species -> genus
    end
end 



# New dataframe for sex, genus abundance dataset (later add genus abundance)
genus_dataset = dataset  # want to keep subject and sex col

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

# Compute mean abundance for each timepoimt category (group by time months)
mean_abundance = combine(groupby(genus_dataset, :timepoint_id)) do df
    DataFrame([mean(df[:, col]) for col in genera]', genera)  # compute the means 
end

mean_abundance_only = select(mean_abundance, Not(:timepoint_id))

percent = 5 # get 5% of abundance 
counts = [sum(col) for col in eachcol(mean_abundance_only)] # sum the mean abundances of genera in total 
bool_filter = counts .> percent
mean_abundance_filter50 = mean_abundance_only[:, bool_filter]

# Couple all other mean abundances in OTHER category 
other_mean_abundance = mean_abundance_only[:, Not(bool_filter)]
other = []
for row in 1:nrow(other_mean_abundance)
    push!(other, sum(other_mean_abundance[row, :]))
end 

# Add other column to filtered mean abundance data 
mean_abundance_filter50.Other = other

mean_abundance = mean_abundance_filter50
genera = names(mean_abundance)


