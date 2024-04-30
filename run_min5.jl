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
    # matrix = repeat(matrix, inner=(1,3))
    matrix = interpolate_matrix(matrix)
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

save_dir = "/Users/hanshu/Desktop/Price_formation/Data/generate_fr_KBoot/Input_NYISO/"
CSV.write(save_dir*"df_wind_2019_historical_quantiles.csv", df_wind)
CSV.write(save_dir*"df_solar_2019_historical_quantiles.csv", df_solar)
CSV.write(save_dir*"df_load_2019_historical_quantiles.csv", df_load)

CSV.write(save_dir*"wind_forecast_conversion.csv", wind_event_quantile)
CSV.write(save_dir*"solar_forecast_conversion.csv", solar_event_quantile)
CSV.write(save_dir*"load_forecast_conversion.csv", load_event_quantile)

horizon = 24;
k = 10; # setting the number of nearest neighbors
initial_time = Dates.DateTime(2019, 1, 1)
output_dir = "/Users/hanshu/Desktop/Price_formation/Data/generate_fr_KBoot/NYISO/Min5_2/"

for i in 1:(8760*12-horizon+1)
    run_time = initial_time + (i-1)*Minute(5)
    @info "generate data for $run_time"
    if i > 200
        break
    end
    one_run_time = @elapsed begin
    kbbot_time = @elapsed begin
    wind_scenario_blocks_final_variance1, solar_scenario_blocks_final_variance1, load_scenario_blocks_final_variance1 = scenario_generation(df_wind, df_solar, df_load, wind_event_quantile, solar_event_quantile, load_event_quantile, run_time, horizon, k);
    end
    println("KBoot time: $kbbot_time")
    h5_save_time = @elapsed begin
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
    println("H5 save time: $h5_save_time")
end
    @info "Percentage of time consumed by KBoot: $(kbbot_time/one_run_time*100)% and by H5 save: $(h5_save_time/one_run_time*100)%"
    @info "Time elapsed: $one_run_time seconds"
end

