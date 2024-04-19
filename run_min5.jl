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

function  read_event_quantiles_min(filename::AbstractString; issolar::Bool=false)::DataFrame
    forecast = h5open(filename, "r") do file
        return read(file)
    end
    header = ["p_$i" for i in 1:99]
    if issolar
        forecast["forecasts"] = hcat(forecast["forecasts"][:, 1:40], forecast["forecasts"][:, 81:end])
    end
    matrix = forecast["forecasts"][:, 2:2:end]
    matrix = repeat(matrix, inner=(1,3))
    df = DataFrame(transpose(matrix), header)
    fcst_time = range(DateTime(2019, 1, 1, 0, 0, 0), stop = DateTime(2019, 12, 31, 23, 55, 0), step = Minute(5))
    insertcols!(df, 1, :forecast_time => fcst_time)
    return df
end



include("data_process_min5.jl")
df_wind, df_solar, df_load = process_forecast_quantiles(df_wind, df_solar, df_load, df_wind_forecast_quantiles, df_solar_forecast_quantiles, df_load_forecast_quantiles, df_wind_forecast, df_solar_forecast, df_load_forecast)
# correction LocalDateTime
df_wind.LocalDateTime = df_wind.DateTime .- Hour(4);
df_solar.LocalDateTime = df_solar.DateTime .- Hour(4);
df_load.LocalDateTime = df_load.DateTime .- Hour(4);
# correcting extracted_hour
df_wind.extracted_hour = hour.(df_wind.LocalDateTime);
df_solar.extracted_hour = hour.(df_solar.LocalDateTime);
df_load.extracted_hour = hour.(df_load.LocalDateTime);

wind_event_quantile = read_event_quantiles_min(wind_fcst_file)
solar_event_quantile = read_event_quantiles_min(solar_fcst_file; issolar = true)
load_event_quantile = read_event_quantiles_min(load_fcst_file)


horizon = 48;
k = 10; # setting the number of nearest neighbors
initial_time = Dates.DateTime(2019, 1, 1)
output_dir = "/Users/hanshu/Desktop/Price_formation/Data/generate_fr_KBoot/NYISO/Min5/"

for i in 1:(8760*12-horizon+1)
    run_time = initial_time + (i-1)*Minute(5)
    if i%100 == 0
        @info "generate $run_time"
    end
    wind_plot1, solar_plot1, load_plot1, q_knn1, v_knn1, wind_scenario_blocks_final_variance1, solar_scenario_blocks_final_variance1, load_scenario_blocks_final_variance1 = scenario_generation(df_wind, df_solar, df_load, wind_event_quantile, solar_event_quantile, load_event_quantile, run_time, horizon, k);
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

