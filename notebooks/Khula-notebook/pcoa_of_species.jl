# Load libraries 
using Leap #must be in Project mode start terminal by:  julia --project=.
using CSV
using DataFrames
using Distances
using CairoMakie 
using MultivariateStats

#####
# STEP 2: gather the metadata and taxprofiles
#####
## First, load the taxonomic profiles. They should have a column that is their SEQID.

## Then, load the Khula HIV metadata. It should have a SUBJECT column.
# From this table, select only what matters to you - HIV status, in this case, but also anything else of interest

## Finally, join the HIV Metadata and the Taxonomic Profiles to the master reltable. You should still have all 549 rows, except if the newer samples were not processed.

# Path to the file of sequencing data is in /grace 
manual_path= "/grace/sequencing/processed/mgx/metaphlan/mpa_v31_CHOCOPhlAn_201901"
#replace patterns is a keyword argument in the function load_raw_metaphlan
replace_pattern = r"profile" #finds all files with "profile" in name

#Load the sequencing files with taxonomic community "profile" 
community_profile = Leap.load_raw_metaphlan(manual_path, ;replace_pattern=replace_pattern)
# has features (row) and samples (col)...

feature_result = features(community_profile) #vector of features with the type Taxon 
#Taxon has 2 fields: (name, rank)

#Filter the vector of features so that we only have species rank 
species_community_profile = filter(feature -> feature.rank === :species, community_profile) 
#....is a CommunityProfile{Float64, Taxon, MicrobiomeSample} with 1071 features in 2965 samples
# all 2965 sample names are unique  
sample_names = samples(species_community_profile) #vector of MicrobiomeSample
#unique_samples = unique(sample_names)

#Grab the processed KHULA sample csv data 
khula_hiv_metadata = CSV.read("data/subject_timepoint_sample_rel.csv", DataFrame)

# Extract the matching sample names from community profile 
for x in samples(species_community_profile)
    x.sample_base = first(split(x.sample_base, "_"))
end

#Compare sample names from species community profile and the khula metadata 
sample_names = map(x -> first(split(x.sample_base, "_")), samples(species_community_profile))
matches_bool = sample_names .∈ Ref(khula_hiv_metadata.uid)
sum(matches_bool) #315 matches!

#Take species_community_profile and index it with matches boolean 
match_community_profile = species_community_profile[:, matches_bool]

# Reformat into dataframe 
community_profile_dataframe = comm2wide(match_community_profile)
community_profile_dataframe= select(community_profile_dataframe, Not(:file, :sample))

#Select necessary metadata

select_metadata = select(khula_hiv_metadata, [:subject_id,:uid, :zymo_code, :timepoint_id, :mom_arv_selfreport, :baby_arv_selfreport, :medhx_mom___1_selfreport, :feeding_type_3m, :feeding_type_6m])
# Innerjoin on sample_base and uid
khula_hiv_all_data = innerjoin(select_metadata, community_profile_dataframe, on = [:uid => :sample_base])

# Export output df into csv
filename = "HIVmetadata_and_abundance_ZYM.csv"
CSV.write(joinpath("data", filename), khula_hiv_all_data)

#Isolate the abundance data...
#Find the DataType of columns in dataframe 
column_types = eltype.(eachcol(community_profile_dataframe))

column_types .<: Number #boolean vector 
#Filter using boolean vector so you only have Numerical columns (abundance data)  
abundance_data_df = community_profile_dataframe[:,column_types .<: Number]

matches_bool =  Ref(khula_hiv_metadata.uid) .∈ sample_names 

#####
# STEP 3: visualize data using pcoa plots 
#####
#Make abundance data in correct matrix format 
abundance_data = Matrix(abundance_data_df)
#Compute dissimilarity matrix (used for microbial data) compare every row (sample) against each other 
dissimilarity_matrix = Distances.pairwise(BrayCurtis(), abundance_data, dims=1) #expects matrix data 
#Apply PCoA to dissimilarity matrix 
model = fit(MDS, dissimilarity_matrix; maxoutdim=20, distances=true)

###################
# COLOR BY FEEDING
###################



###################
# COLOR BY HIV 
###################
#### gathering the plot properties (color, etc
unique(khula_hiv_metadata.medhx_mom___1_selfreport)
#need to get rid of missing values and make categories 
color_group = map(x -> x==0 ? "HIV-" : "HIV+", khula_hiv_metadata.medhx_mom___1_selfreport)

# Manually map string labels to colors
color_map = Dict("HIV-" => :blue, "HIV+" => :red)

# Create actual color vector for plotting
color_vector = map(x -> color_map[x], color_group)

#Create figure 
fig = Figure(size = (1200, 800))

#Create axis and label them 
ax11 = Axis(fig[1,1],
    xlabel = "MDS1",
    ylabel = "MDS2"
)

sc11 = scatter!(ax11, model.U[:,1], model.U[:,2], color = color_vector, alpha=0.5)

ax12 = Axis(fig[1,2],
    xlabel = "MDS1",
    ylabel = "MDS3"
)
sc12 = scatter!(ax12, model.U[:,1], model.U[:,3], color = color_vector, alpha=0.5)

ax21 = Axis(fig[2,1],
    xlabel = "MDS2",
    ylabel = "MDS3"
)
sc21 = scatter!(ax21, model.U[:,2], model.U[:,3], color = color_vector, alpha=0.5)

ax22 = Axis(fig[2,2],
    xlabel = "MDS4",
    ylabel = "MDS5"
)
sc22 = scatter!(ax22, model.U[:,4], model.U[:,5], color = color_vector, alpha=0.5)

Legend(
    fig[:,3],
    [
        # PolyElement(color = color_map["HIV-"]), # Blue Square
        # PolyElement(color = color_map["HIV+"])  # Red Square
        MarkerElement(marker = :circle, color = color_map["HIV-"]), # Blue dot (circle marker)
        MarkerElement(marker = :circle, color = color_map["HIV+"])  # Red dot (circle marker)
    ],
    [
        "HIV-", # Labels 
        "HIV+"
    ],
    tellheight = false,
    tellwidth = false
)

colsize!(fig.layout, 1, Relative(0.45))
colsize!(fig.layout, 2, Relative(0.45))
colsize!(fig.layout, 3, Relative(0.1))

#Save data in png file to display
save("data_figures/pcoa_HIV_status.png", fig)


#### PCoA colored by ART use 
#Create figure 
fig = Figure()
#Create axis and label them 
ax = Axis(fig[1,1],
    title = "PCoA of South Africa abundance data colored by Maternal ART use",
    xlabel = "MDS1",
    ylabel = "MDS2"
)

color_group = map(x -> ismissing(x) ? "no ARV" : "taking ARV", khula_hiv_metadata.mom_arv_selfreport)

# Manually map string labels to colors
color_map = Dict("no ARV" => :green, "taking ARV" => :red)

# Create actual color vector for plotting
color_vector = map(x -> color_map[x], color_group)

sc = scatter!(ax, model.U[:,1], model.U[:,2], color = color_vector, alpha=0.5)

#Save data in png file to display
save("data_figures/pcoa_ARV_use.png", fig)

###################
# COLOR BY SPECIES 
###################
#### PCoA colored by B.longum
#Create figure 
fig = Figure()
#Create axis and label them 
ax = Axis(fig[1,1],
    title = "PCoA of South Africa abundance data colored by B.longum",
    xlabel = "MDS1",
    ylabel = "MDS2"
)

sc = scatter!(ax, model.U[:,1], model.U[:,2], color = abundance_data_df.Bifidobacterium_longum, alpha=0.5)

save("data_figures/pcoa_B_longum.png", fig)

#### PCoA colored by B.breve
#Create figure 
fig = Figure()
#Create axis and label them 
ax = Axis(fig[1,1],
    title = "PCoA of South Africa abundance data colored by B.breve",
    xlabel = "MDS1",
    ylabel = "MDS2"
)

sc = scatter!(ax, model.U[:,1], model.U[:,2], color = abundance_data_df.Bifidobacterium_breve, alpha=0.5)

save("data_figures/pcoa_B_breve.png", fig)

#### PCoA colored by E.coli
#Create figure 
fig = Figure()
#Create axis and label them 
ax = Axis(fig[1,1],
    title = "PCoA of South Africa abundance data colored by E.coli",
    xlabel = "MDS1",
    ylabel = "MDS2"
)

sc = scatter!(ax, model.U[:,1], model.U[:,2], color = abundance_data_df.Escherichia_coli, alpha=0.5)

save("data_figures/pcoa_E_coli.png", fig)

#### PCoA colored by P.copri
#Create figure 
fig = Figure()
#Create axis and label them 
ax = Axis(fig[1,1],
    title = "PCoA of South Africa abundance data colored by P.copri",
    xlabel = "MDS1",
    ylabel = "MDS2"
)

sc = scatter!(ax, model.U[:,1], model.U[:,2], color = abundance_data_df.Prevotella_copri, alpha=0.5)

save("data_figures/pcoa_P_copri.png", fig)

#### PCoA colored by P.copri
#Create figure 
fig = Figure()
#Create axis and label them 
ax = Axis(fig[1,1],
    title = "PCoA of South Africa abundance data colored by F.prausnitzii",
    xlabel = "MDS1",
    ylabel = "MDS2"
)

sc = scatter!(ax, model.U[:,1], model.U[:,2], color = abundance_data_df.Faecalibacterium_prausnitzii, alpha=0.5)

save("data_figures/pcoa_F_prausnitzii.png", fig)


#### PCoA colored by ages
#Create figure 
fig = Figure()
#Create axis and label them 
ax = Axis(fig[1,1],
    title = "PCoA of South Africa abundance data colored by ages",
    xlabel = "MDS1",
    ylabel = "MDS2"
)


color_group = map(x -> ismissing(x) ? "no ARV" : "taking ARV", khula_hiv_metadata.timepoint_id)

# Manually map string labels to colors
color_map = Dict("no ARV" => :green, "taking ARV" => :red)

# Create actual color vector for plotting
color_vector = map(x -> color_map[x], color_group)

sc = scatter!(ax, model.U[:,1], model.U[:,2], color = color_vector, alpha=0.5)

#Save data in png file to display
save("data_figures/pcoa_ages.png", fig)



