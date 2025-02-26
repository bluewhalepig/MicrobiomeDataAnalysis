# Learning Linear Regression
using CairoMakie
using DataFrames
using GLM

## What do I need for a machine leraning probem?

## Data
## Model
## Train the model
## Test the model

## 1. Get data
## 2. Make sure data is in the right format - Table (rows/columns) - data types, NaN, NA, missing values, strings/factors, blabalblablabal
## 3. Elect a Model
##      - mathematical, equation model (parametric model) output = a*columns 1 + b*columns 2 + c
##      - nonmaparametric model (nearest neighbor, random forest kind of thing)

### We are starting with mathematical models today.

## 3. Mathematical models (PARAMETRIC MODELS)

## For example
xs = [ 1; 2; 3; 4 ]

using Random
Random.seed!(0)

ys = [ (el .* (2 .+ randn()*0.5))  .+ 1.0 .+ randn()*0.5 for el in xs ]

fig, ax, plt = scatter(xs, ys, color = :blue)

points_df = DataFrame(:x => xs, :y => ys)
linearmodel = lm(@formula(y ~ x + 1), points_df)

slope = coef(linearmodel)[1]
intercept = coef(linearmodel)[2]

ablines!(ax, [ slope ], [ intercept ])

## We can do this with microbiome data as well!

using CSV 

#Load the data into matrix (data format that PCA takes)
data = CSV.read("data_ext/sample_data.csv", DataFrame)
abundance_data = select(data, Not(:cogScore, :subject, :timepoint, :sex, :education, :ageMonths))
#abundance_data = Matrix(abundance_data)
meta_data = select(data, [:cogScore, :subject, :timepoint, :sex, :education, :ageMonths])

## Ask how does each species affect age, in a linear hypothesis.

# Conduct linear regression on the age metadata and abundance data
## Ask how does each species affect age, in a linear hypothesis.
# Make a DataFrame: bug_name, slope, intercept, p-value, R^2_value (need to process this with function)
bug_names = names(abundance_data)
linear_regression_results_df = DataFrame(:bug_name => String[], :slope =>Float64[], :intercept =>Float64[]
	, :p_value_slope => Float64[], :p_value_intercept =>Float64[], :r_squared =>Float64[]) #empty df 

for each_bug in bug_names
	regression_df = DataFrame(:age => meta_data.ageMonths,  :bug => abundance_data[:, each_bug])
	linear_model = lm(@formula(age ~ bug + 1), regression_df) #@formula value informs structure of the line 
	slope = coef(linear_model)[2]
	intercept = coef(linear_model)[1]
	p_value_slope = coeftable(linear_model).cols[4][2]
	p_value_intercept = coeftable(linear_model).cols[4][1]
	r_squared = r2(linear_model) #r2() function gives r squared value 
	#push values onto dataframe 
	push!(linear_regression_results_df, [each_bug, slope, intercept, p_value_slope, p_value_intercept, r_squared]) 
end 

linear_regression_results_df
# How to find most significant bug?
	# We want the highest R^2 value, closer to 1 = bug abundance more predictive of age 
	# p value of <0.05
	# largest magnitude of slope 
sort(linear_regression_results_df, :r_squared, rev=true)
# Mulivariable regression model: 

## Compoments we need:
	# 1. Access libraries: MLJ, DecisionTree 
	using MLJ
	using MLJDecisionTreeInterface
	using DecisionTree
	using StatsBase
	# 2. Load the model of decision tree that you want
	RandomForestRegressor = MLJ.@load RandomForestRegressor pkg=DecisionTree

	# Instantiate a RandomForest Regressor and use to build machine with input (X) and output (y)
	reg = RandomForestRegressor()
	X = abundance_data # multivariate input: abundance data 
	y = meta_data.ageMonths # univariate output: age in months 
	mach = machine(reg, X, y) 

	# 3. Partition the indexes of the rows into train and test groups 
	train, test = partition(eachindex(y), 0.7)

	# 4. Train the data at train indexes 
	MLJ.fit!(mach, rows = train)

	# 5. Test the model using text indexes of the abundance data 
	yhat_test = MLJ.predict(mach, X[test, :]) #outputs are predicted ages (yhat) 
	yhat_train = MLJ.predict(mach, X[train, :])

	# 6. Calculate the mean abs error for training set and test set
	mae_test = mean(abs.(yhat_test - y[test])) 
	mae_train = mean(abs.(yhat_train-y[train]))


# Scatter plot of training and test samples yhat 
fig = Figure()
#Create axis and label them 
ax = Axis(fig[1,1],
	title = "Scatter plot of Training and Test data for age prediction",
	xlabel = "ground truth age in months",
	ylabel = "prediction age in months"
)

sc = scatter!(ax, y[train], yhat_train, color=:blue)
scatter!(ax, y[test], yhat_test, color=:red)


Legend(fig[1,2], 
	[MarkerElement(color = :blue, marker = :circle), MarkerElement(color = :red, marker = :circle)], 
	["Train", "Test"]) # position of legend, markers, label
save("data_ext/scatter.png", fig)



# Calculate correlation between truth and yhat in training and test set 
corr_test = cor(y[test], yhat_test)
corr_train = cor(y[train], yhat_train)



# Scatter plot of training and test samples yhat 
fig = Figure()
save("data_ext/scatterplot_yhat.png", fig)


############################













#############################################

# Make a stacked bar plot of genus abundance data 

using Leap #must be in Project mode start terminal by:  julia --project=.
using CSV
using DataFrames
using Distances
using CairoMakie 
using MultivariateStats
using ColorSchemes

manual_path= "/grace/sequencing/processed/mgx/metaphlan/mpa_v31_CHOCOPhlAn_201901"

#replace patterns is a keyword argument in the function load_raw_metaphlan
replace_pattern = r"profile" #finds all files with "profile" in name

#Load the sequencing files with taxonomic community "profile" 
community_profile = Leap.load_raw_metaphlan(manual_path, ;replace_pattern=replace_pattern)

#Filter the community profile so that only features remain
feature_result = features(community_profile)

#Filter the vector of yfeatures so that we only have species rank 
genera_community_profile = filter(feature -> feature.rank === :genus, community_profile) 
#....is a CommunityProfile{Float64, Taxon, MicrobiomeSample} with 1071 features in 2965 samples
# all 2965 sample names are unique  
sample_names = samples(genera_community_profile) #vector of MicrobiomeSample
#unique_samples = unique(sample_names)

# Combine csv to get metadata??????


#Load the data into matrix 
data = CSV.read("data_ext/sample_data.csv", DataFrame) 
abundance_data_w_sex = select(data, Not(:cogScore, :subject, :timepoint, :education, :ageMonths))

names()

#Reshape into long format?? 
abundance_long = stack(abundance_data_w_sex, Not(:sex), variable_name=:Genus, value_name=:Abundance)

# Group by sex and genus and find TOTAL abundance for each sex 
data_genus = combine(groupby(abundance_long, [:sex, :Genus]), :Abundance => sum => :TotalAbundance)


#Get colors for genera 
genera = unique(data_genus.Genus)
genera_fake = first(genera, 6) # filter only the first six species 
colors = ColorSchemes.seaborn_colorblind6[1:length(genera_fake)] # generate colors 

filter_data_genus = filter(row -> row.Genus in genera_fake, data_genus) # filter only the first six species 

##### Create stacked bar plot figure 
fig = Figure()


ax = Axis(fig[1, 1],
    title = "Stacked Bar Plot: Relative Abundance by Sex",
    xlabel = "Sex",
    ylabel = "Relative Abundance",
    xticks = ([1, 2], ["1", "2"])
)


# what to put in the plot 
xvalue = filter_data_genus.sex 

#Stacked bar plot 
barplot!(ax, xvalue, filter_data_genus.TotalAbundance, stack = filter_data_genus.Genus, color=colors)

# Step 6: Add Legend
Legend(fig[1, 2], colors, genera_fake, title="Genus")


save("data_ext/barplot.png", fig)
