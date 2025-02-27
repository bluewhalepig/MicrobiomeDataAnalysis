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

