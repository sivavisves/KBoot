using KBoot
using Test
using CSV, DataFrames, Plots, StatsPlots, Distributions, Random, KernelDensity, Dates, NearestNeighbors, Statistics, TimeZones, HDF5


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

# correction DateTimeTexas
df_wind.DateTimeTexas = df_wind.DateTime .- Hour(6);
df_solar.DateTimeTexas = df_solar.DateTime .- Hour(6);
df_load.DateTimeTexas = df_load.DateTime .- Hour(6);

# correcting extracted_hour
df_wind.extracted_hour = hour.(df_wind.DateTimeTexas);
df_solar.extracted_hour = hour.(df_solar.DateTimeTexas);
df_load.extracted_hour = hour.(df_load.DateTimeTexas);

# load quantile data
wind_event_quantile = CSV.read("./Data Preparation/Sample Data/Quantiles/Forecasts/wind_forecast_conversion.csv", DataFrame);
solar_event_quantile = CSV.read("./Data Preparation/Sample Data/Quantiles/Forecasts/solar_forecast_conversion.csv", DataFrame);
load_event_quantile = CSV.read("./Data Preparation/Sample Data/Quantiles/Forecasts/load_forecast_conversion.csv", DataFrame);

wind_quantile = quantile_data_prep(wind_event_quantile)
solar_quantile = quantile_data_prep(solar_event_quantile)
load_quantile = quantile_data_prep(load_event_quantile)

hour_of_interest = 0;
horizon = 48;
k = 10;

output_dir = "./Long term study/Scenario Data/"

@time for i in 1:(8760-horizon+1)
    initial_time = Dates.DateTime(2018, 1, 1)
    run_time = initial_time + Hour(i - 1)
    month_of_interest = Dates.month(run_time)
    day_of_interest = Dates.day(run_time)
    hour_of_interest = Dates.hour(run_time)
    wind_plot1, solar_plot1, load_plot1, q_knn1, v_knn1, wind_scenario_blocks_final_variance1, solar_scenario_blocks_final_variance1, load_scenario_blocks_final_variance1 = scenario_generation(df_wind, df_solar, df_load, wind_quantile, solar_quantile, load_quantile, month_of_interest, day_of_interest, horizon, hour_of_interest, k);
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
    println("Hour $i done")
end

  
