# Task due July 15th, Monday 
## Filter the sequencing metaphlan data and process them using process_csv_data script

#GOAL: 
## WE are taking all the LEAP/ECHO project and filtering out the 517 Malawi samples (seqid) that we 
## gathered from processing th csv files and combing the biospecimen and sequencing files. 
##open different version of julia1.10: julia +lts --project=.

using Leap #must be in Project mode start terminal by:  julia --project=.
using CSV
using DataFrames 
using Distances
using CairoMakie 
using MultivariateStats

# Path to the file of sequencing data is in /grace 
manual_path= "/grace/sequencing/processed/mgx/metaphlan"

#replace patterns is a keyword argument in the function load_raw_metaphlan
replace_pattern = r"profile" #finds all files with "profile" in name

#Load the sequencing files with taxonomic community "profile" 
community_profile = Leap.load_raw_metaphlan(manual_path; replace_pattern=replace_pattern)
# has features (row) and samples (col)...
#.... is a CommunityProfile{Float64, Taxon, MicrobiomeSample} with 1626 features in 2965 samples
####Features are taxonomic names of different rank, ie. Bacteria, Eukaryota, Proteobacteria
####Samples are sample file names with well number ie.'S1' ie. SEQ00028_S1
####Taxon has 2 fields: (name, rank)

###What does load_raw_metaphlan do? -grabs which files fit the "description" of profile 


##Filter the features 
#Filter the community profile so that only features remain
feature_result = features(community_profile) #vector of features with the type Taxon 
#Taxon has 2 fields: (name, rank)

# propertynames(feature_result[1])
# feature_result[1].rank #Rank is the "kindgom, phylum, etc classification"  

#Filter the vector of features so that we only have species rank 
species_community_profile = filter(feature -> feature.rank === :species, community_profile) 
#....is a CommunityProfile{Float64, Taxon, MicrobiomeSample} with 1071 features in 2965 samples
# all 2965 sample names are unique  
sample_names = samples(species_community_profile) #vector of MicrobiomeSample
#unique_samples = unique(sample_names)



#Filter the samples on the sample base which omitts the well number 
#We take the sample ids from the malawi data set and only filter out the MicrobiomeSamples that match with those ids. 

#Grad the processed Malawi sample csv data 
malawi_table = CSV.read("data_ext/processed_output.csv", DataFrame)

sample_names[1].sample_base 

#for every row in community profile, grab only malawi samples
#malawi_in_Leap = filter(sample -> sample.sample_base ∈ malawi_table.seqid, community_profile) 
##CAN"T DO!!!
#samples would be rows and features would be columns (not julia)
#but samples are columns and features are rows in JULIA 
#---allows for more faster computing "column major" matrix 


#Manually filter the columns from sample_names and checks malawi_table.seqid 
matches_bool = map(x -> x.sample_base, samples(species_community_profile)) .∈ Ref(malawi_table.seqid)
#map function takes a function and applies to every item in a matrix ... use to filter the 

sum(matches_bool) #331 matches!

#Take species_community_profile and index it with matches boolean 
result = species_community_profile[:, matches_bool]

result_dataframe = comm2wide(result) #formats as dataframe 

#operations for microbiome data... notes from 10/16
#comparing types --> is "type" a subtype of Number?
### Float64 <: Number == true! 


#Isolate the abundance data...
#Find the DataType of columns in dataframe 
column_types = eltype.(eachcol(result_dataframe))

column_types .<: Number #boolean vector 
#Filter using boolean vector so you only have Numerical columns (abundance data)  
abundance_data_df = result_dataframe[:,column_types .<: Number]



#if you want to do PCoA with filtered data: abundance_data = abundance_data_filter10 

#PCA of community profile beta diversity bray curtis 
#Make abundance data in correct matrix format 
abundance_data = Matrix(abundance_data_df)
#Compute dissimilarity matrix (used for microbial data) compare every row (sample) against each other 
dissimilarity_matrix = Distances.pairwise(BrayCurtis(), abundance_data, dims=1) #expects matrix data 
#Apply PCoA to dissimilarity matrix 
model = fit(MDS, dissimilarity_matrix; maxoutdim=20, distances=true)
#Create figure 
fig = Figure()
#Create axis and label them 
ax = Axis(fig[1,1],
    title = "PCoA of Malawi abundance data",
    xlabel = "MDS1",
    ylabel = "MDS2"
)
#Modifies the axis to contain data 
sc = scatter!(ax, model.U[:,1], model.U[:,2], color = abundance_data_df.Bifidobacterium_longum, alpha=0.5)
sc = scatter!(ax, model.U[:,1], model.U[:,2], color = abundance_data_df.Bifidobacterium_breve, alpha=0.5)
sc = scatter!(ax, model.U[:,1], model.U[:,2], color = abundance_data_df.Escherichia_coli , alpha=0.5)
#Save data in png file to display... (for some reason I can't use display function)
save("data_ext/scatter_plot.png", fig)
