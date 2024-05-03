using KBoot
using CSV, DataFrames, Plots, StatsPlots, Distributions, Random, KernelDensity, Dates, NearestNeighbors, Statistics, TimeZones, HDF5
using Base.Threads: @threads, ReentrantLock


function quantile_data_prep(df)
    # permute the dimension of the quantile data
    df = permutedims(df);
    #rename the columns x1 to p_1
    for i in 1:99
        rename!(df, Symbol("x$i") => Symbol("p_$i"));
    end
    insertcols!(df, 1, :forecast_time => ["h$i" for i in 0:8759]);
    return df
end

function covert2array(vec_df::Vector{Any})::Array{Float64, 2}
    array = zeros(Float64, length(vec_df[1].BA_total), length(vec_df))
    for (i, df) in enumerate(vec_df)
        array[:, i] = df.BA_total
    end
    return array
end

# load historical quantiles
df_wind = CSV.read("./Historical Quantiles/df_wind_2018_historical_quantiles.csv", DataFrame);
df_solar = CSV.read("./Historical Quantiles/df_solar_2018_historical_quantiles.csv", DataFrame);
df_load = CSV.read("./Historical Quantiles/df_load_2018_historical_quantiles.csv", DataFrame);

# correction LocalDateTime
df_wind.LocalDateTime = df_wind.DateTime .- Hour(6);
df_solar.LocalDateTime = df_solar.DateTime .- Hour(6);
df_load.LocalDateTime = df_load.DateTime .- Hour(6);

# correcting extracted_hour
df_wind.extracted_hour = hour.(df_wind.LocalDateTime);
df_solar.extracted_hour = hour.(df_solar.LocalDateTime);
df_load.extracted_hour = hour.(df_load.LocalDateTime);

# load quantile data
wind_event_quantile = CSV.read("Case Studies/Long term study/Data File/wind_forecast_conversion_clean.csv", DataFrame);
solar_event_quantile = CSV.read("Case Studies/Long term study/Data File/solar_forecast_conversion_clean.csv", DataFrame);
load_event_quantile = CSV.read("Case Studies/Long term study/Data File/load_forecast_conversion_clean.csv", DataFrame);

# wind_quantile = quantile_data_prep(wind_event_quantile)
# solar_quantile = quantile_data_prep(solar_event_quantile)
# load_quantile = quantile_data_prep(load_event_quantile)


horizon = 48;
k = 10;

# Single threaded version

output_dir = "./Long term study/Scenario Data/";

@time for i in 1:(8760-horizon+1)

    initial_time = Dates.DateTime(2017, 12, 31, 18)
    run_time = initial_time + Hour(i - 1)
    wind_scenario_blocks_final_variance1, solar_scenario_blocks_final_variance1, load_scenario_blocks_final_variance1 = scenario_generation(df_wind, df_solar, df_load, wind_event_quantile, solar_event_quantile, load_event_quantile, run_time, horizon, k);
    load_scenarios_array = covert2array(load_scenario_blocks_final_variance1)
    solar_scenarios_array = covert2array(solar_scenario_blocks_final_variance1)
    wind_scenarios_array = covert2array(wind_scenario_blocks_final_variance1)


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
    println("Hour $i done")
end


# Multi threading version

const load_output_file = "Case Studies/Long term study/Scenario Data/load_scenarios_multi.h5"
const solar_output_file = "Case Studies/Long term study/Scenario Data/solar_scenarios_multi.h5"
const wind_output_file = "Case Studies/Long term study/Scenario Data/wind_scenarios_multi.h5"
const file_lock = ReentrantLock()

@time Threads.@threads for i in 1:(8760-horizon+1)
    initial_time = Dates.DateTime(2017, 12, 31, 18)
    run_time = initial_time + Hour(i - 1)

    wind_scenario_blocks_final_variance1, solar_scenario_blocks_final_variance1, load_scenario_blocks_final_variance1 = scenario_generation(df_wind, df_solar, df_load, wind_event_quantile, solar_event_quantile, load_event_quantile, run_time, horizon, k);

    load_scenarios_array = covert2array(load_scenario_blocks_final_variance1)
    solar_scenarios_array = covert2array(solar_scenario_blocks_final_variance1)
    wind_scenarios_array = covert2array(wind_scenario_blocks_final_variance1)

    # Serialize file writes with a lock
    lock(file_lock) do
        h5open(load_output_file, "cw") do file
            write(file, "load_$run_time", load_scenarios_array)
        end

        h5open(solar_output_file, "cw") do file
            write(file, "solar_$run_time", solar_scenarios_array)
        end

        h5open(wind_output_file, "cw") do file
            write(file, "wind_$run_time", wind_scenarios_array)
        end
        println("$run_time done")
    end
end
