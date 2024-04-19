using StatsBase, CSV, DataFrames, Plots, StatsPlots, Distributions, Random, KernelDensity, Dates, NearestNeighbors, Statistics, TimeZones
gr(size=(600, 600))
include("../src/quantile_conversion.jl")

#---------------------------Data Loading and Preprocessing---------------------------#
# Load data
df_wind = CSV.read("Data Preparation/Sample Data/Actuals/wind_actuals_2018_hourly_BA.csv", DataFrame);
df_solar = CSV.read("Data Preparation/Sample Data/Actuals/solar_actuals_2018_hourly_BA.csv", DataFrame);
df_load = CSV.read("Data Preparation/Sample Data/Actuals/load_actuals_2018_hourly_BA.csv", DataFrame);

# load forecast data
df_wind_forecast_quantiles = CSV.read("Data Preparation/Sample Data/Quantiles/Forecasts/forecast_2018_wind.csv", DataFrame);
df_solar_forecast_quantiles = CSV.read("Data Preparation/Sample Data/Quantiles/Forecasts/forecast_2018_solar.csv", DataFrame);
df_load_forecast_quantiles = CSV.read("Data Preparation/Sample Data/Quantiles/Forecasts/forecast_2018_load.csv", DataFrame);


x = df_wind_forecast_quantiles.datetime .- Hour(6);

df_wind_forecast_quantiles = insertcols!(df_wind_forecast_quantiles, 1, :LocalDateTime => x);
df_solar_forecast_quantiles = insertcols!(df_solar_forecast_quantiles, 1, :LocalDateTime => x);
df_load_forecast_quantiles = insertcols!(df_load_forecast_quantiles, 1, :LocalDateTime => x);
df_wind = insertcols!(df_wind, 1, :LocalDateTime => x);
df_solar = insertcols!(df_solar, 1, :LocalDateTime => x);
df_load = insertcols!(df_load, 1, :LocalDateTime => x);

# only take DateTime at year 2017-12-31
df_wind = df_wind[df_wind.DateTime .>= DateTime(2018, 01, 01, 0, 0, 0), :];
df_solar = df_solar[df_solar.DateTime .>= DateTime(2018, 01, 01, 0, 0, 0), :];
df_load = df_load[df_load.DateTime .>= DateTime(2018, 01, 01, 0, 0, 0), :];


#---------------------------Function---------------------------#

# Load quantiles for conversion
df_wind_forecast = CSV.read("Data Preparation/Sample Data/Quantiles/Forecasts/wind_forecast_conversion.csv", DataFrame)
df_solar_forecast = CSV.read("Data Preparation/Sample Data/Quantiles/Forecasts/solar_forecast_conversion.csv", DataFrame)
df_load_forecast = CSV.read("Data Preparation/Sample Data/Quantiles/Forecasts/load_forecast_conversion.csv", DataFrame)


x = process_forecast_quantiles(df_wind, df_solar, df_load, df_wind_forecast_quantiles, df_solar_forecast_quantiles, df_load_forecast_quantiles, df_wind_forecast, df_solar_forecast, df_load_forecast);

