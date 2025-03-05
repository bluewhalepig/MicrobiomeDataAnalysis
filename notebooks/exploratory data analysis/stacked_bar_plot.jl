#############################################

# Script for a stacked bar plot of genus abundance data 
# want t o do this bfre filtering genera 

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

first(genus_dataset, 6)
#first(genus_dataset.sex, 6)


# Compute mean abundance for each sex category (group by sex)
mean_abundance = combine(groupby(genus_dataset, :sex)) do df
    DataFrame([mean(df[:, col]) for col in genera]', genera)  # compute the means 
end

# Convert to a format suitable for plotting
#sex = mean_abundance.sex 
#genera_repeat = repeat(1:length(genera), outer = 2)  # cycle through 1-length of genera 
#abundance = vec(Matrix(mean_abundance[:, Not(:sex)])) # flatten abundance matrix


for row in 1:nrow(genus_dataset)
    @show((sum(genus_dataset[row, 3:end])))
end

####################### PRACTICE w/ 4 GENUS  ###########################
p_mean_abundance = select(mean_abundance, :sex, :"Bifidobacterium",  :"Faecalibacterium",  :"Prevotella", :"Ruminococcus")
genera = names(select(p_mean_abundance, Not(:sex)))


genera_repeat = repeat(1:length(genera), inner = 2)  # cycle through 1-length of genera 
abundance = vec(Matrix(p_mean_abundance[:, Not(:sex)])) # flatten abundance matrix

sex = repeat([1, 2], outer = length(genera))


#########################
# Create stacked bar plot 
    # x value = sex 
    # y value = relative abundances colored by genera

# Define colors for each bacterial species
colors = Makie.wong_colors()[1:length(genera)]  # use default 'wong' colors 
colors = get(ColorSchemes.seaborn_colorblind6, range(0, 1, length=length(genera)))# generate sum cool colors 

# Create figure and axis
fig = Figure()
ax = Axis(fig[1,1], 
          xticks = (1:2, ["Male", "Female"]),  # Set x-axis labels for sex
          title = "Bacterial Genus Abundance by Sex",
          ylabel = "Relative Abundance")

# Create stacked bar plot
barplot!(
    ax,
    sex,
    abundance,
    stack = genera_repeat,  # Stack the y order for same x coordinate
    color = [colors[i] for i in genera_repeat]
)  # Assign colors to genera

# Create legend
labels = genera
elements = [PolyElement(polycolor = colors[i]) for i in 1:length(genera)]
Legend(fig[1,2], elements, labels, title = "Bacterial Genera")

# Save the figure
save("data_ext/bacterial_abundance_by_sex.png", fig)


xs = Float64[]
ys = Float64[]
stk = Int64[] #stack 

for i in 1:nrow(mean_abundance)
    for j in 1:ncol(mean_abundance[:,2:end])
        push!(xs, i)
        push!(stk, j)
        push!(ys, mean_abundance[i,j+1])
    end
end 

sex = xs
abundance = ys
genera_repeat = stk


colors = get(ColorSchemes.seaborn_colorblind6, range(0, 1, length=length(genera)))#
# Create figure and axis
fig = Figure(size=(1200,800))
ax = Axis(fig[1,1], 
          xticks = (1:2, ["Male", "Female"]),  # Set x-axis labels for sex
          title = "Bacterial Genus Abundance by Sex",
          ylabel = "Relative Abundance")

# Create stacked bar plot
barplot!(
    ax,
    sex,
    abundance,
    stack = genera_repeat,  # Stack the y order for same x coordinate
    color = [colors[i] for i in genera_repeat]
)  # Assign colors to genera

# Create legend
labels = genera
elements = [PolyElement(polycolor = colors[i]) for i in 1:length(genera)]
Legend(fig[1,2], elements, labels, title = "Bacterial Genera", nbanks=3)

# Save the figure
save("data_ext/bacterial_abundance_by_sex.png", fig)



# Only show the top genera and couple all others in Other category 
# Stratify by months 

# Find reasonable cut off % of abundance 

# 