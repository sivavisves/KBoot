using StatsBase, CSV, DataFrames, Plots, StatsPlots, Distributions, Random, KernelDensity, Dates, NearestNeighbors, Statistics, TimeZones
using HDF5
gr(size=(600, 600))
include("src/quantile_conversion.jl")

# Funtions to read arpa-e-perform h5 files into DataFrame
function read_actuals(filename::AbstractString; isload = false)::DataFrame
    df = DataFrame(DateTime = DateTime[], hour = Int64[], BA_total = Float64[])
    data = h5open(filename, "r") do file
        return read(file, "actuals")
    end
    init_time = DateTime(2019, 1, 1, 0, 0, 0)
    for i in 1:8760
        curr_time = init_time + Hour(i - 1)
        hour = (i-1)%24
        if isload
            val = mean(data[8760+i])
        else
            val = mean(data[(i-1)*12+1:i*12])
        end
        push!(df, [curr_time hour val])
    end
    return df
end

function  read_forecast_quantiles(filename::AbstractString; isload = false)::DataFrame
    forecast = h5open(filename, "r") do file
        return read(file)
    end
    header = ["x$i" for i in 1:99]
    date_time_format = "yyyy-mm-dd HH:MM:SS+zzzz"
    forecast_times = [DateTime(dt_str, date_time_format) for dt_str in forecast["forecast_time"]]
    issue_times = [DateTime(dt_str, date_time_format) for dt_str in forecast["issue_time"]]
    if isload
        ncols = size(forecast["forecasts"], 2)
        new_matrix = zeros(Float32, size(forecast["forecasts"], 1), Int(ncols/2))
        for col in 1:2:ncols
            new_matrix[:, cld(col, 2)] = mean(forecast["forecasts"][:, col:col+1], dims=2)
        end
        df = DataFrame(transpose(new_matrix), header)
        df.datetime = [forecast_times[2*i] for i in 1:8760]
        df.datetime_issue = [issue_times[2*i] for i in 1:8760]
    else
        qunatile_matrix = [parse(Float32, element) for element in forecast["forecasts"]]
        df = DataFrame(transpose(qunatile_matrix), header)
        df.datetime = forecast_times
        df.datetime_issue = issue_times
    end
    return df
end

function  read_forecast_8760(filename::AbstractString; isload = false)::DataFrame
    forecast = h5open(filename, "r") do file
        return read(file)
    end
    header = ["h$i" for i in 1:8760]
    if isload
        ncols = size(forecast["forecasts"], 2)
        new_matrix = zeros(Float32, size(forecast["forecasts"], 1), Int(ncols/2))
        for col in 1:2:ncols
            new_matrix[:, cld(col, 2)] = mean(forecast["forecasts"][:, col:col+1], dims=2)
        end
        df = DataFrame(new_matrix, header)
    else
        qunatile_matrix = [parse(Float32, element) for element in forecast["forecasts"]]
        df = DataFrame(qunatile_matrix, header)
    end
    return df
end

#---------------------------File Location---------------------------#
data_dir = "/Users/hanshu/Desktop/Price_formation/Data/ARPAE_NYISO"
solar_fcst_file = joinpath(data_dir, "BA_solar_1day-ahead_fcst_2019.h5")
wind_fcst_file = joinpath(data_dir, "BA_wind_1day-ahead_fcst_2019.h5")
load_fcst_file = joinpath(data_dir, "BA_load_1day-ahead_fcst_2019.h5")
solar_actual_file = joinpath(data_dir, "BA_solar_actuals_2019.h5")
wind_actual_file = joinpath(data_dir, "BA_wind_actuals_2019.h5")
load_actual_file = joinpath(data_dir, "BA_load_actuals_2019.h5")

#---------------------------Data Loading---------------------------#
df_wind = read_actuals(wind_actual_file)
df_solar = read_actuals(solar_actual_file)
df_load = read_actuals(load_actual_file; isload = true)

df_wind_forecast_quantiles = read_forecast_quantiles(wind_fcst_file)
df_solar_forecast_quantiles = read_forecast_quantiles(solar_fcst_file)
df_load_forecast_quantiles = read_forecast_quantiles(load_fcst_file; isload = true)

#---------------------------Preprocessing---------------------------#
x = df_wind_forecast_quantiles.datetime .- Hour(6);

df_wind_forecast_quantiles = insertcols!(df_wind_forecast_quantiles, 1, :LocalDateTime => x);
df_solar_forecast_quantiles = insertcols!(df_solar_forecast_quantiles, 1, :LocalDateTime => x);
df_load_forecast_quantiles = insertcols!(df_load_forecast_quantiles, 1, :LocalDateTime => x);
df_wind = insertcols!(df_wind, 1, :LocalDateTime => x);
df_solar = insertcols!(df_solar, 1, :LocalDateTime => x);
df_load = insertcols!(df_load, 1, :LocalDateTime => x);

df_wind = df_wind[df_wind.DateTime .>= DateTime(2019, 01, 01, 0, 0, 0), :];
df_solar = df_solar[df_solar.DateTime .>= DateTime(2019, 01, 01, 0, 0, 0), :];
df_load = df_load[df_load.DateTime .>= DateTime(2019, 01, 01, 0, 0, 0), :];

df_wind_forecast = read_forecast_8760(wind_fcst_file)
df_solar_forecast = read_forecast_8760(solar_fcst_file)
df_load_forecast = read_forecast_8760(load_fcst_file; isload = true)

