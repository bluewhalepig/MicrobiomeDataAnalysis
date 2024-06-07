using CSV, DataFrames, CairoMakie

# Load the data of samples that were recovered
recovered_data = CSV.read("sample_data.csv", DataFrame)


#Plot a histogram of the ages column 
# ages = select(recovered_data, "ageMonths") #dataframe 
ages = recovered_data[:, :ageMonths] #--> returns same values in vector form 
# recovered_data.ageMonths #returns same value vector

hist(ages, bins = 15, normalization = :none) # histogram expects vector value 

#Plot a histogram of cogScores 
cogScores = recovered_data[:, "cogScore"]
hist(bar_labels= "Counts of CogScores", cogScores, bins = 15, normalization = :none)

#Plot a scatterplot of cogScores vs age 
scatter(ages, cogScores, title ="Cognitive Scores vs Age", xlabel="Age (months)", ylabel="Cognitive Scores")

