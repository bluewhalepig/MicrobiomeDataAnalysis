#############################################

# Script for applying linear regression models to microbial taxa data 

#############################################
using CairoMakie
using DataFrames
using GLM

## What do I need for a machine learning probem?

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

######################
# Results: Most significant bug? Sort by r^2 value 
######################

sort!(linear_regression_results_df, :r_squared, rev=true)
linear_regression_results_df

### END 
