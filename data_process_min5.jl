using StatsBase, CSV, DataFrames, Plots, StatsPlots, Distributions, Random, KernelDensity, Dates, NearestNeighbors, Statistics, TimeZones
using HDF5
gr(size=(600, 600))
include("src/quantile_conversion.jl")

# Funtions to read arpa-e-perform h5 files into DataFrame
function read_actuals_min5(filename::AbstractString; isload = false)::DataFrame
    df = DataFrame(DateTime = DateTime[], hour = Int64[], minute = Int64[], BA_total = Float64[])
    data = h5open(filename, "r") do file
        return read(file, "actuals")
    end
    init_time = DateTime(2019, 1, 1, 0, 0, 0)
    for i in 1:8760*12
        curr_time = init_time + Minute(5)*(i-1)
        hour = Dates.hour(curr_time)
        min = Dates.minute(curr_time)
        if isload
            val = data[8760*12+i]
        else
            val = data[i]
        end
        push!(df, [curr_time hour min val])
    end
    return df
end

function  read_forecast_quantiles_min5(filename::AbstractString; issolar::Bool=false)::DataFrame
    forecast = h5open(filename, "r") do file
        return read(file)
    end
    header = ["x$i" for i in 1:99]
    date_time_format = "yyyy-mm-dd HH:MM:SS+zzzz"
    if issolar
        forecast["forecasts"] = hcat(forecast["forecasts"][:, 1:40], forecast["forecasts"][:, 81:end])
    end
    issue_times = [DateTime(dt_str, date_time_format) for dt_str in forecast["issue_time"]]
    matrix = forecast["forecasts"][:, 2:2:end]
    matrix = repeat(matrix, inner=(1,3))
    df = DataFrame(transpose(matrix), header)
    df.datetime = range(DateTime(2019, 1, 1, 0, 0, 0), stop = DateTime(2019, 12, 31, 23, 55, 0), step = Minute(5))
    df.datetime_issue = repeat([issue_times[2*i] for i in 1:35040], inner = 3)
    return df
end

function  read_forecast_hour_min(filename::AbstractString; issolar = false)::DataFrame
    forecast = h5open(filename, "r") do file
        return read(file)
    end
    if issolar
        forecast["forecasts"] = hcat(forecast["forecasts"][:, 1:40], forecast["forecasts"][:, 81:end])
    end
    header = range(DateTime(2019, 1, 1, 0, 0, 0), stop = DateTime(2019, 12, 31, 23, 55, 0), step = Minute(5))
    formatted_header = [Dates.format(dt, "yyyy-mm-dd HH:MM:SS") for dt in header]
    # header = [forecast["forecast_time"][2*i] for i in 1:35040]
    matrix = forecast["forecasts"][:, 2:2:end]
    matrix = repeat(matrix, inner=(1,3))
    df = DataFrame(matrix, formatted_header)
    return df
end

#---------------------------File Location---------------------------#
data_dir = "/Users/hanshu/Desktop/Price_formation/Data/ARPAE_NYISO"
solar_fcst_file = joinpath(data_dir, "BA_Existing_solar_intra-hour_fcst_2019.h5")
wind_fcst_file = joinpath(data_dir, "BA_Existing_wind_intra-hour_fcst_2019.h5")
load_fcst_file = joinpath(data_dir, "BA_load_intra-hour_fcst_2019.h5")
solar_actual_file = joinpath(data_dir, "BA_solar_actuals_2019.h5")
wind_actual_file = joinpath(data_dir, "BA_wind_actuals_2019.h5")
load_actual_file = joinpath(data_dir, "BA_load_actuals_min5_2019.h5")


#---------------------------Data Loading---------------------------#
df_wind = read_actuals_min5(wind_actual_file)
df_solar = read_actuals_min5(solar_actual_file)
df_load = read_actuals_min5(load_actual_file; isload = true)

df_wind_forecast_quantiles = read_forecast_quantiles_min5(wind_fcst_file)
df_solar_forecast_quantiles = read_forecast_quantiles_min5(solar_fcst_file; issolar = true)
df_load_forecast_quantiles = read_forecast_quantiles_min5(load_fcst_file)



#---------------------------Preprocessing---------------------------#
x = df_wind_forecast_quantiles.datetime .- Hour(4);
df_wind_forecast_quantiles = insertcols!(df_wind_forecast_quantiles, 1, :LocalDateTime => x);
df_solar_forecast_quantiles = insertcols!(df_solar_forecast_quantiles, 1, :LocalDateTime => x);
df_load_forecast_quantiles = insertcols!(df_load_forecast_quantiles, 1, :LocalDateTime => x);
x = df_wind.DateTime .- Hour(4);
df_wind = insertcols!(df_wind, 1, :LocalDateTime => x);
df_solar = insertcols!(df_solar, 1, :LocalDateTime => x);
df_load = insertcols!(df_load, 1, :LocalDateTime => x);

df_wind = df_wind[df_wind.DateTime .>= DateTime(2019, 01, 01, 0, 0, 0), :];
df_solar = df_solar[df_solar.DateTime .>= DateTime(2019, 01, 01, 0, 0, 0), :];
df_load = df_load[df_load.DateTime .>= DateTime(2019, 01, 01, 0, 0, 0), :];

df_wind_forecast = read_forecast_hour_min(wind_fcst_file)
df_solar_forecast = read_forecast_hour_min(solar_fcst_file; issolar = true)
df_load_forecast = read_forecast_hour_min(load_fcst_file)
