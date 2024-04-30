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

load_check0, load_check1= 0,0
for i in eachindex(df_load.load_check)
    if df_load.load_check[i] == 0
        load_check0 += 1
    else
        load_check1 += 1
    end
end

wind_check0, wind_check1= 0,0
for i in eachindex(df_wind.wind_check)
    if df_wind.wind_check[i] == 0
        wind_check0 += 1
    else
        wind_check1 += 1
    end
end
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


horizon = 24;
k = 10; # setting the number of nearest neighbors
initial_time = Dates.DateTime(2019, 1, 1)
i = 1
run_time = initial_time + (i-1)*Minute(5)


year_of_interest = Dates.year(run_time)
month_of_interest = Dates.month(run_time)
day_of_interest = Dates.day(run_time)
hour_of_interest = Dates.hour(run_time)
minute_of_interest = Dates.minute(run_time)
# Data cleaning and processing phase
include("src/Data Prep.jl")
include("src/KNN_code.jl")
hour_1_wind_variance, blocks_wind_train, blocks_wind_test= process_energy_data_variance(df_wind, hour_of_interest, minute_of_interest, horizon);
hour_1_solar_variance, blocks_solar_train, blocks_solar_test = process_energy_data_variance(df_solar, hour_of_interest, minute_of_interest, horizon);
hour_1_load_variance, blocks_load_train, blocks_load_test = process_energy_data_variance(df_load, hour_of_interest, minute_of_interest, horizon);

hour_1_wind_quantile = process_energy_data_quantile(df_wind, hour_of_interest, minute_of_interest, horizon);
hour_1_solar_quantile = process_energy_data_quantile(df_solar, hour_of_interest, minute_of_interest, horizon);
hour_1_load_quantile = process_energy_data_quantile(df_load, hour_of_interest, minute_of_interest, horizon);

p_knn = scatter(hour_1_load_quantile, hour_1_wind_quantile, hour_1_solar_quantile, 
                xlabel="Load", 
                ylabel="Wind", 
                zlabel="Solar", 
                title="Hour 1 Quantile", 
                legend=false)

p_knn = scatter(hour_1_load_variance, hour_1_wind_variance, hour_1_solar_variance, 
                xlabel="Load", 
                ylabel="Wind", 
                zlabel="Solar", 
                title="Hour 1 Variance", 
                legend=false)

#---------------------------------KNN---------------------------------#
# Data Prep for knn
kd_tree_quantile = data_prep_knn_quantile(hour_1_load_quantile, hour_1_wind_quantile, hour_1_solar_quantile);

kd_tree_variance = data_prep_knn_variance(hour_1_load_variance, hour_1_wind_variance, hour_1_solar_variance);

kd_tree_combined = data_prep_knn_combined([hour_1_load_quantile hour_1_wind_quantile hour_1_solar_quantile], [hour_1_load_variance hour_1_wind_variance hour_1_solar_variance]);

#filtering the data for a specific date.
# filter 7/18 date from df_wind
df_wind_718 = filter_by_datetime_range(df_wind, :LocalDateTime, run_time, horizon);
df_solar_718 = filter_by_datetime_range(df_solar, :LocalDateTime, run_time, horizon);
df_load_718 = filter_by_datetime_range(df_load, :LocalDateTime, run_time, horizon);

current_point_variance, index_variance, distance_variance = knn_variance(df_load_718, df_wind_718, df_solar_718, kd_tree_variance, k, run_time);
current_point_quantile, index_quantile, distance_quantile = knn_quantile(df_load_718, df_wind_718, df_solar_718, kd_tree_quantile, k, run_time);
current_point_combined, index_combined, distance_combined = knn_combined(df_load_718, df_wind_718, df_solar_718, kd_tree_combined, k, run_time);
current_point = [extract_first_point(df_load_718), extract_first_point(df_wind_718), extract_first_point(df_solar_718)]; # load, wind, solar


#plot nearest neighbors in scatter plot
wind_knn_quantile = [hour_1_wind_quantile[i] for i in index_quantile];
load_knn_quantile = [hour_1_load_quantile[i] for i in index_quantile];
solar_knn_quantile = [hour_1_solar_quantile[i] for i in index_quantile];

q_knn = scatter(hour_1_load_quantile, hour_1_wind_quantile, hour_1_solar_quantile, xlabel="Load", ylabel="Wind", zlabel="Solar", title="Hour 1 Quantile", legend=false)
scatter!([current_point_quantile[1]], [current_point_quantile[2]], [current_point_quantile[3]], color = :red, markersize = 10)
scatter!(load_knn_quantile, wind_knn_quantile, solar_knn_quantile, color= :yellow, alpha=0.5, markersize=10)

#connect test point with nearest neighbors
for i in 1:k
    plot!([current_point_quantile[1], load_knn_quantile[i]], [current_point_quantile[2], wind_knn_quantile[i]], [current_point_quantile[3], solar_knn_quantile[i]], color=:black, alpha=0.5, linewidth=2)
end

q_knn

#plot nearest neighbors in scatter plot
wind_knn_variance = [hour_1_wind_variance[i] for i in index_variance];
load_knn_variance = [hour_1_load_variance[i] for i in index_variance];
solar_knn_variance = [hour_1_solar_variance[i] for i in index_variance];

v_knn = scatter(hour_1_load_variance, hour_1_wind_variance, hour_1_solar_variance, xlabel="Load", ylabel="Wind", zlabel="Solar", title="Hour 1 Variance", legend=false)
scatter!([current_point_variance[1]], [current_point_variance[2]], [current_point_variance[3]], color = :red, markersize = 10)
scatter!(load_knn_variance, wind_knn_variance, solar_knn_variance, color= :yellow, alpha=0.5, markersize=10)

#connect test point with nearest neighbors
for i in 1:k
    plot!([current_point_variance[1], load_knn_variance[i]], [current_point_variance[2], wind_knn_variance[i]], [current_point_variance[3], solar_knn_variance[i]], color=:black, alpha=0.5, linewidth=2)
end

v_knn

wind_scenario_quantile = get_blocks(index_quantile, blocks_wind_train);
solar_scenario_quantile = get_blocks(index_quantile, blocks_solar_train);
load_scenario_quantile = get_blocks(index_quantile, blocks_load_train);

wind_scenario_variance = get_blocks(index_variance, blocks_wind_train);
solar_scenario_variance = get_blocks(index_variance, blocks_solar_train);
load_scenario_variance = get_blocks(index_variance, blocks_load_train);

wind_scenario_combined = get_blocks(index_combined, blocks_wind_train);
solar_scenario_combined = get_blocks(index_combined, blocks_solar_train);
load_scenario_combined = get_blocks(index_combined, blocks_load_train);

#---------------------------------Quantile data---------------------------------#

wind_event_quantile_clean = event_quantile_clean(wind_event_quantile);
solar_event_quantile_clean = event_quantile_clean(solar_event_quantile);
load_event_quantile_clean = event_quantile_clean(load_event_quantile);

actual_wind_scenarios_variance = get_actual_scenarios(wind_scenario_variance, wind_event_quantile_clean, run_time);
actual_solar_scenarios_variance = get_actual_scenarios(solar_scenario_variance, solar_event_quantile_clean, run_time);
actual_load_scenarios_variance = get_actual_scenarios(load_scenario_variance, load_event_quantile_clean, run_time);

actual_wind_scenarios_combined = get_actual_scenarios(wind_scenario_combined, wind_event_quantile_clean, run_time);
actual_solar_scenarios_combined = get_actual_scenarios(solar_scenario_combined, solar_event_quantile_clean, run_time);
actual_load_scenarios_combined = get_actual_scenarios(load_scenario_combined, load_event_quantile_clean, run_time);

wind_scenario_blocks_final_combined = seperate_blocks(actual_wind_scenarios_combined, k);
solar_scenario_blocks_final_combined = seperate_blocks(actual_solar_scenarios_combined, k);
load_scenario_blocks_final_combined = seperate_blocks(actual_load_scenarios_combined, k);

wind_scenario_blocks_final_variance = seperate_blocks(actual_wind_scenarios_variance, k);
solar_scenario_blocks_final_variance = seperate_blocks(actual_solar_scenarios_variance, k);
load_scenario_blocks_final_variance = seperate_blocks(actual_load_scenarios_variance, k);

for i in 1:k
    load_scenario_blocks_final_combined[i][1,:].BA_total = current_point[1][1];
    wind_scenario_blocks_final_combined[i][1,:].BA_total = current_point[2][1];
    solar_scenario_blocks_final_combined[i][1,:].BA_total = current_point[3][1];
end

wind_plot = plotting_scenarios(wind_scenario_blocks_final_combined, "Wind Scenario Blocks", horizon);
solar_plot = plotting_scenarios(solar_scenario_blocks_final_combined, "Solar Scenario Blocks", horizon);
load_plot = plotting_scenarios(load_scenario_blocks_final_combined, "Load Scenario Blocks", horizon);
