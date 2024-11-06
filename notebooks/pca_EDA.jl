### My attempt at PCA in julia! 

using MultivariateStats
using CairoMakie
using RDatasets
using CSV
using Microbiome
using Distances #PlotlyJS doesn't install...

#Load the data into matrix (data format that PCA takes)
data = CSV.read("data_ext/sample_data.csv", DataFrame) 
abundance_data = select(data, Not(:cogScore, :subject, :timepoint, :sex, :education, :ageMonths))
abundance_data = Matrix(abundance_data)



#cog_data = select(data, :cogScore)

#Preprocessing the data...
#### PCA input is "horizontal data" so, each row is a feature and each column is a sample 
##its already horizontal so no need to preprocess! 


#Compute dissimilarity matrix (used for microbial data) 
dissimilarity_matrix = Distances.pairwise(BrayCurtis(), abundance_data, dims=1) #expects matrix data 
#dimensions = 1 --> compares every row against every row 
#result: 269x269 matrix 

#Generate the PCA model for the data #not what we want...
model = fit(PCA, dissimilarity_matrix; maxoutdim=20)
    #maxoutdim --> input of 2 dimensions, output is 1 dimension
    #result: 7 PCs 

#Scree plot to determine how many PC we need
lines(model.prinvars ./sum(model.prinvars))
    #find elbow, in this case @3

#NMDS PCoA (principal coordinate analysis)
model = fit(MDS, dissimilarity_matrix; maxoutdim=20, distances=true)

#Sree plot 
lines(model.λ ./sum(model.λ)) #result: elbow at 3


#Plotting PC1 and PC2 of PCoA result
#model.U contains the scores of the samples on the principal components
#Create figure
fig = Figure()

#Create axis and label them 
ax = Axis(fig[1,1],
    title = "PCoA of abundance data",
    xlabel = "MDS1",
    ylabel = "MDS2"
)

#Modifies the axis to contain data 
sc_age = scatter!(ax, model.U[:,1], model.U[:,2], color = data.ageMonths, alpha=0.5)

#Coloring plot by cognitive scores
scatter(model.U[:,1], model.U[:,2], color = data.cogScore, alpha=0.5)
#Layout(title="relationship between samples based on taxa abundances and colored by child cognitive scores", yaxis_title="MDS2", xaxis_title="MDS1")

#Coloring plot by sex
scatter(model.U[:,1], model.U[:,2], color = data.sex, alpha=0.5)

#Can save image in data file 
save("data_ext/scatter_plot.png", fig)

##
##
##
##
