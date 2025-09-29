
using Leap #must be in Project mode start terminal by:  julia --project=.
using CSV
using DataFrames
using CairoMakie 
using MultivariateStats
using ColorSchemes
using Statistics

#Grab the processed KHULA sample csv data 
dataset = CSV.read("data/HIVmetadata_and_abundance_ZYM.csv", DataFrame)

#filter 3 mo 
filter!(row -> row.timepoint_id == "3mo", dataset) #99 rows for 3mo, 111 rows for 6mo, 105 rows for 12mo 

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

# Sum up species columns based on same genus #286 genera names 

for genus in genera
    # Find all species columns that belong to this genus
    species_columns = [species for species in keys(genus_mapping) if genus_mapping[species] == genus]
    #print(species_columns)

    # Extract select species columns 
    species_extracted = genus_dataset[!, species_columns]

    # Remove select species columns 
    genus_dataset = select(genus_dataset, Not(species_columns))

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

# Changes missing values to 0 
#genus_dataset.mom_arv_selfreport .= coalesce.(genus_dataset.mom_arv_selfreport, 0)


#Isolate the abundance data...in genus_dataset
#Find the DataType of columns in dataframe 
column_types = eltype.(eachcol(genus_dataset))

column_types .<: Number #boolean vector 
#Filter using boolean vector so you only have Numerical columns (abundance data)  
abundance_genus_data = genus_dataset[:,column_types .<: Number]
abundance_genus_data = select(abundance_genus_data, Not(:medhx_mom___1_selfreport)) # yes, 286 columns 

row_sums = [sum(row) for row in eachrow(abundance_genus_data)]
filter(x -> x < 99.99, row_sums)

# Compute mean abundance for each timepoimt category (group by time months)
mean_abundance = combine(groupby(genus_dataset, :mom_arv_selfreport)) do df
    DataFrame([mean(df[:, col]) for col in genera]', genera)  # compute the means 
end

mean_abundance_only = select(mean_abundance, Not(:mom_arv_selfreport))

# Sum each row to check abundances 
row_sums = [sum(row) for row in eachrow(mean_abundance_only)]

# Print or inspect how close each row sum is to 1
println(row_sums)  # should be all ≈ 1.0

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

# Sum each row
row_sums = [sum(row) for row in eachrow(mean_abundance)]

#########################
# Create stacked bar plot 
    # x = stratified by ARV use 
    # y = relative abundances colored by genera 

# Define empty lists for x-axis, y-axis, and stacking coordinates 
xs = Float64[] #age month indexes for each mean abundance 
ys = Float64[] #list of mean abundance 
stk = Int64[] #genera indexes for each mean abundance 

# Manually generate coordinate inputs for bar plot 
for i in 1:nrow(mean_abundance)
    for j in 1:ncol(mean_abundance[:,:])
        push!(xs, i) 
        push!(stk, j)
        push!(ys, mean_abundance[i,j])
    end
end 

unique(genus_dataset.mom_arv_selfreport)

# Create figure and axis
fig = Figure(size=(700,500)) #size = choose height and width of fig 
ax = Axis(fig[1,1], 
          xticks = (1:2, ["No ART use", "ART use"]),  # Set x-axis labels for maternal ART
          title = "Bacterial Genus Abundance by Maternal ART use 12mo",
          ylabel = "Relative Abundance")

# Define colors for each bacterial genera 
#colors = Makie.wong_colors()[1:length(genera)]  # generate default 'wong' colors 
colors = get(ColorSchemes.seaborn_colorblind6, range(0, 1, length=length(genera)))# generate sum cool colors 

# Assign inputs for barplot 
age = xs # 1... 2...
abundance = ys # mean abundances 
genera_stk = stk # we want 33 elements 

# Create stacked bar plot
barplot!(
    ax,
    age,
    abundance,
    stack = genera_stk,  # Stack the y order for same x coordinate
    color = [colors[i] for i in genera_stk] # Assign colors for each genera 
)  
# Create legend
labels = genera
elements = [PolyElement(polycolor = colors[i]) for i in 1:length(genera)]
Legend(fig[1,2], elements, labels, title = "Bacterial Genera", nbanks=1) #nbanks = divide legend up into 3 columns 

# Save the figure
save("data_figures/plot_genus_abundances_by_arv_12mo.png", fig)

