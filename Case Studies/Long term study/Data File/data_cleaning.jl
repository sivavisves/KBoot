using StatsBase, CSV, DataFrames, Plots, StatsPlots, Distributions, Random, KernelDensity, Dates, NearestNeighbors, Statistics, TimeZones
gr(size=(600, 600))
# include the function call
include("../../../src/function_call.jl")

#---------------------------Data Loading and Preprocessing---------------------------#
# Load data
wind_event_quantile= CSV.read("Case Studies/Long term study/Data File/wind_forecast_conversion.csv", DataFrame);
solar_event_quantile= CSV.read("Case Studies/Long term study/Data File/solar_forecast_conversion.csv", DataFrame);
load_event_quantile= CSV.read("Case Studies/Long term study/Data File/load_forecast_conversion.csv", DataFrame);

wind_event_quantile_clean = event_quantile_clean(wind_event_quantile)
solar_event_quantile_clean = event_quantile_clean(solar_event_quantile)
load_event_quantile_clean = event_quantile_clean(load_event_quantile)

# save the cleaned data
CSV.write("Case Studies/Long term study/Data File/wind_forecast_conversion_clean.csv", wind_event_quantile_clean)
CSV.write("Case Studies/Long term study/Data File/solar_forecast_conversion_clean.csv", solar_event_quantile_clean)
CSV.write("Case Studies/Long term study/Data File/load_forecast_conversion_clean.csv", load_event_quantile_clean)