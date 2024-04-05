using KBoot
using HDF5
using CSV, DataFrames, Plots, StatsPlots, Distributions, Random, KernelDensity, Dates, NearestNeighbors, Statistics, TimeZones, HDF5

function covert2array(vec_df::Vector{Any})::Array{Float64, 2}
    array = zeros(Float64, length(vec_df[1].BA_total), length(vec_df))
    for (i, df) in enumerate(vec_df)
        array[:, i] = df.BA_total
    end
    return array
end


function  read_event_quantiles(filename::AbstractString; isload = false)::DataFrame
    forecast = h5open(filename, "r") do file
        return read(file)
    end
    header = ["p_$i" for i in 1:99]
    if isload
        ncols = size(forecast["forecasts"], 2)
        new_matrix = zeros(Float32, size(forecast["forecasts"], 1), Int(ncols/2))
        for col in 1:2:ncols
            new_matrix[:, cld(col, 2)] = mean(forecast["forecasts"][:, col:col+1], dims=2)
        end
        df = DataFrame(transpose(new_matrix), header)
    else
        qunatile_matrix = [parse(Float32, element) for element in forecast["forecasts"]]
        df = DataFrame(transpose(qunatile_matrix), header)
    end
    insertcols!(df, 1, :forecast_time => ["h$i" for i in 0:8759]);
    return df
end

include("data_process.jl")
df_wind, df_solar, df_load = process_forecast_quantiles(df_wind, df_solar, df_load, df_wind_forecast_quantiles, df_solar_forecast_quantiles, df_load_forecast_quantiles, df_wind_forecast, df_solar_forecast, df_load_forecast)
# correction DateTimeNY
df_wind.DateTimeNY = df_wind.DateTime .- Hour(4);
df_solar.DateTimeNY = df_solar.DateTime .- Hour(4);
df_load.DateTimeNY = df_load.DateTime .- Hour(4);
# correcting extracted_hour
df_wind.extracted_hour = hour.(df_wind.DateTimeNY);
df_solar.extracted_hour = hour.(df_solar.DateTimeNY);
df_load.extracted_hour = hour.(df_load.DateTimeNY);

wind_event_quantile = read_event_quantiles(wind_fcst_file)
solar_event_quantile = read_event_quantiles(solar_fcst_file)
load_event_quantile = read_event_quantiles(load_fcst_file; isload = true)


horizon = 48;
k = 10; # setting the number of nearest neighbors
initial_time = Dates.DateTime(2019, 1, 1)

output_dir = "/Users/hanshu/Desktop/Price_formation/Data/generate_fr_KBoot/NYISO/"

for i in 1:(8760-horizon+1)
    run_time = initial_time + Hour(i - 1)
    month_of_interest = Dates.month(run_time)
    day_of_interest = Dates.day(run_time)
    hour_of_interest = Dates.hour(run_time)
    wind_plot1, solar_plot1, load_plot1, q_knn1, v_knn1, wind_scenario_blocks_final_variance1, solar_scenario_blocks_final_variance1, load_scenario_blocks_final_variance1 = scenario_generation(df_wind, df_solar, df_load, wind_event_quantile, solar_event_quantile, load_event_quantile, month_of_interest, day_of_interest, horizon, hour_of_interest, k);
    load_scenarios_array = covert2array(load_scenario_blocks_final_variance1)
    h5open(output_dir*"load_scenarios.h5", "cw") do file
        write(file, string(run_time), load_scenarios_array)
    end
    solar_scenarios_array = covert2array(solar_scenario_blocks_final_variance1)
    h5open(output_dir*"solar_scenarios.h5", "cw") do file
        write(file, string(run_time), solar_scenarios_array)
    end
    wind_scenarios_array = covert2array(wind_scenario_blocks_final_variance1)
    h5open(output_dir*"wind_scenarios.h5", "cw") do file
        write(file, string(run_time), wind_scenarios_array)
    end
end

