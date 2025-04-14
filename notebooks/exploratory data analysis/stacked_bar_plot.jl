#############################################

# Script for a stacked bar plot of genus abundance data 
# want to do this before filtering genera 

#############################################

using Leap #must be in Project mode start terminal by:  julia --project=.
using CSV
using DataFrames
using CairoMakie 
using MultivariateStats
using ColorSchemes
using Statistics

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

# Compute mean abundance for each sex category (group by sex)
mean_abundance = combine(groupby(genus_dataset, :sex)) do df
    DataFrame([mean(df[:, col]) for col in genera]', genera)  # compute the means 
end


#########################
# Create stacked bar plot 
    # x = stratified by sex 
    # y = relative abundances colored by genera 

# Define empty lists for x-axis, y-axis, and stacking coordinates 
xs = Float64[] #sex indexes for each mean abundance 
ys = Float64[] #list of mean abundance 
stk = Int64[] #genera indexes for each mean abundance 

# Manually generate coordinate inputs for bar plot 
for i in 1:nrow(mean_abundance)
    for j in 1:ncol(mean_abundance[:,2:end])
        push!(xs, i) 
        push!(stk, j)
        push!(ys, mean_abundance[i,j+1])
    end
end 

# Create figure and axis
fig = Figure(size=(1200,800)) #size = choose height and width of fig 
ax = Axis(fig[1,1], 
          xticks = (1:2, ["Male", "Female"]),  # Set x-axis labels for sex
          title = "Bacterial Genus Abundance by Sex",
          ylabel = "Relative Abundance")

# Define colors for each bacterial genera 
#colors = Makie.wong_colors()[1:length(genera)]  # generate default 'wong' colors 
colors = get(ColorSchemes.seaborn_colorblind6, range(0, 1, length=length(genera)))# generate sum cool colors 

# Assign inputs for barplot 
sex = xs # 1... 2...
abundance = ys # mean abundances 
genera_stk = stk # 1-60 genera for sex1... 1-60 genera for sex2...

# Create stacked bar plot
barplot!(
    ax,
    sex,
    abundance,
    stack = genera_stk,  # Stack the y order for same x coordinate
    color = [colors[i] for i in genera_stk] # Assign colors for each genera 
)  

# Create legend
labels = genera
elements = [PolyElement(polycolor = colors[i]) for i in 1:length(genera)]
Legend(fig[1,2], elements, labels, title = "Bacterial Genera", nbanks=3) #nbanks = divide legend up into 3 columns 

# Save the figure
save("data_ext/bacterial_abundance_by_sex.png", fig)




#########################
# Filter top 50% mean abundnace genera 

# Check first 6 rows of dataset 
first(genus_dataset, 6)

# Compute mean abundance for each sex category (group by sex)
mean_abundance = combine(groupby(genus_dataset, :sex)) do df
    DataFrame([mean(df[:, col]) for col in genera]', genera)  # compute the means 
end

# Filter out sex column since first row is sex1, second row is sex2 mean abundances 
mean_abundance = select(mean_abundance, Not(:sex))
percent = 5 # get 5% of abundance 
counts = [sum(col) for col in eachcol(mean_abundance)] # sum the mean abundances of genera in total 
bool_filter = counts .> percent
mean_abundance_filter50 = mean_abundance[:, bool_filter]

# Couple all other mean abundances in OTHER category 
other_mean_abundance = mean_abundance[:, Not(bool_filter)]
other = []
for row in 1:nrow(other_mean_abundance)
    push!(other, sum(other_mean_abundance[row, :]))
end 

# Add other column to filtered mean abundance data 
mean_abundance_filter50.Other = other

mean_abundance = mean_abundance_filter50
genera = names(mean_abundance)
#########################
# Create stacked bar plot 
    # x = stratified by sex 
    # y = relative abundances colored by genera 
    # only show top abundance genera, categorize low abundance in OTHER category 

# Define empty lists for x-axis, y-axis, and stacking coordinates 
xs = Float64[] #sex indexes for each mean abundance 
ys = Float64[] #list of mean abundance 
stk = Int64[] #genera indexes for each mean abundance 

# Manually generate coordinate inputs for bar plot 
for i in 1:nrow(mean_abundance)
    for j in 1:ncol(mean_abundance[:,1:end])
        push!(xs, i) 
        push!(stk, j)
        push!(ys, mean_abundance[i,j])
    end
end 



# Define colors for each bacterial genera 
#colors = Makie.wong_colors()[1:length(genera)]  # generate default 'wong' colors 
colors = get(ColorSchemes.seaborn_colorblind6, range(0, 1, length=length(genera)))# generate sum cool colors 

# Assign inputs for barplot 
sex = xs # 1... 2...
abundance = ys # mean abundances 
genera_stk = stk # 1-60 genera for sex1... 1-60 genera for sex2...

# Create figure and axis
fig = Figure(size=(1200,800)) #size = choose height and width of fig 
ax = Axis(fig[1,1], 
          xticks = (1:2, ["Male", "Female"]),  # Set x-axis labels for sex
          title = "Bacterial Genus Abundance(5% filter) by Sex",
          ylabel = "Relative Abundance")

# Create stacked bar plot
barplot!(
    ax,
    sex,
    abundance,
    stack = genera_stk,  # Stack the y order for same x coordinate
    color = [colors[i] for i in genera_stk] # Assign colors for each genera 
)  

# Create legend
labels = genera
elements = [PolyElement(polycolor = colors[i]) for i in 1:length(genera)]
Legend(fig[1,2], elements, labels, title = "Bacterial Genera") #nbanks = divide legend up into 3 columns 



# Save the figure
save("data_ext/filtered_abundance_by_sex.png", fig)

