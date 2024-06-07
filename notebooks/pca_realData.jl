using MultivariateStats
using CairoMakie
using RDatasets
using CSV
using Microbiome
using Distances

#Load the data into matrix (data format that PCA takes)
directory_path = "/grace/sequencing/processed/mgx/metaphlan"
profile_files = glob("*.tsv", directory_path)


for file in profile_files
    abundance_df = CSV.read(file, DataFrame, delim='\t',header=3) 
    abundance_df.claude_name #bacteria name
    abundance_df.relative_abundance #relative abundance 
end



