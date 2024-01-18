include("src/Kboot_summary_call.jl")

# load historical quantiles
df_wind = CSV.read("Historical Quantiles/df_wind_2018_historical_quantiles.csv", DataFrame);
df_solar = CSV.read("Historical Quantiles/df_solar_2018_historical_quantiles.csv", DataFrame);
df_load = CSV.read("Historical Quantiles/df_load_2018_historical_quantiles.csv", DataFrame);

# load quantile data
wind_event_quantile = CSV.read("Quantiles/Wind Quantiles.csv", DataFrame);
solar_event_quantile = CSV.read("Quantiles/Solar Quantiles.csv", DataFrame);
load_event_quantile = CSV.read("Quantiles/Load Quantiles.csv", DataFrame);

hour_of_interest = 0;
horizon = 48;
k = 17; # setting the number of nearest neighbors
month_of_interest = 7;
day_of_interest = 18;


function scenario_generation(df_wind, df_solar, df_load, wind_event_quantile, solar_event_quantile, load_event_quantile, month_of_interest, day_of_interest, horizon, hour_of_interest, k)
        # Data cleaning and processing phase
    hour_1_wind_variance, blocks_wind_train, blocks_wind_test= process_energy_data_variance(df_wind, hour_of_interest, horizon);
    hour_1_solar_variance, blocks_solar_train, blocks_solar_test = process_energy_data_variance(df_solar, hour_of_interest, horizon);
    hour_1_load_variance, blocks_load_train, blocks_load_test = process_energy_data_variance(df_load, hour_of_interest, horizon);

    hour_1_wind_quantile = process_energy_data_quantile(df_wind, hour_of_interest, horizon);
    hour_1_solar_quantile = process_energy_data_quantile(df_solar, hour_of_interest, horizon);
    hour_1_load_quantile = process_energy_data_quantile(df_load, hour_of_interest, horizon);

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

    #filtering the data for a specific date.
    # filter 7/18 date from df_wind
    df_wind_718 = filter(row -> Dates.month(row[:DateTimeTexas]) == month_of_interest && Dates.day(row[:DateTimeTexas]) == day_of_interest, df_wind);
    df_solar_718 = filter(row -> Dates.month(row[:DateTimeTexas]) == month_of_interest && Dates.day(row[:DateTimeTexas]) == day_of_interest, df_solar);
    df_load_718 = filter(row -> Dates.month(row[:DateTimeTexas]) == month_of_interest && Dates.day(row[:DateTimeTexas]) == day_of_interest, df_load);

    current_point_quantile, index_quantile, distance_quantile = knn_quantile(df_load_718, df_wind_718, df_solar_718, kd_tree_quantile, k);
    current_point_variance, index_variance, distance_variance = knn_variance(df_load_718, df_wind_718, df_solar_718, kd_tree_variance, k);

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

    #---------------------------------Quantile data---------------------------------#

    wind_event_quantile_clean = event_quantile_clean(wind_event_quantile);
    solar_event_quantile_clean = event_quantile_clean(solar_event_quantile);
    load_event_quantile_clean = event_quantile_clean(load_event_quantile);

    actual_wind_scenarios_variance = get_actual_scenarios(wind_scenario_variance, wind_event_quantile_clean);
    actual_solar_scenarios_variance = get_actual_scenarios(solar_scenario_variance, solar_event_quantile_clean);
    actual_load_scenarios_variance = get_actual_scenarios(load_scenario_variance, load_event_quantile_clean);

    wind_scenario_blocks_final_variance = seperate_blocks(actual_wind_scenarios_variance, k);
    solar_scenario_blocks_final_variance = seperate_blocks(actual_solar_scenarios_variance, k);
    load_scenario_blocks_final_variance = seperate_blocks(actual_load_scenarios_variance, k);

    wind_plot = plotting_scenarios(wind_scenario_blocks_final_variance, "Wind Scenario Blocks");
    solar_plot = plotting_scenarios(solar_scenario_blocks_final_variance, "Solar Scenario Blocks");
    load_plot = plotting_scenarios(load_scenario_blocks_final_variance, "Load Scenario Blocks");

    return wind_plot, solar_plot, load_plot, q_knn, v_knn, wind_scenario_blocks_final_variance, solar_scenario_blocks_final_variance, load_scenario_blocks_final_variance
end

wind_plot1, solar_plot1, load_plot1, q_knn1, v_knn1, wind_scenario_blocks_final_variance1, solar_scenario_blocks_final_variance1, load_scenario_blocks_final_variance1 = scenario_generation(df_wind, df_solar, df_load, wind_event_quantile, solar_event_quantile, load_event_quantile, month_of_interest, day_of_interest, horizon, hour_of_interest, k);

# Data cleaning and processing phase
hour_1_wind_variance, blocks_wind_train, blocks_wind_test= process_energy_data_variance(df_wind, hour_of_interest, horizon);
hour_1_solar_variance, blocks_solar_train, blocks_solar_test = process_energy_data_variance(df_solar, hour_of_interest, horizon);
hour_1_load_variance, blocks_load_train, blocks_load_test = process_energy_data_variance(df_load, hour_of_interest, horizon);

hour_1_wind_quantile = process_energy_data_quantile(df_wind, hour_of_interest, horizon);
hour_1_solar_quantile = process_energy_data_quantile(df_solar, hour_of_interest, horizon);
hour_1_load_quantile = process_energy_data_quantile(df_load, hour_of_interest, horizon);

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

#filtering the data for a specific date.
# filter 7/18 date from df_wind
df_wind_718 = filter(row -> Dates.month(row[:DateTimeTexas]) == month_of_interest && Dates.day(row[:DateTimeTexas]) == day_of_interest, df_wind);
df_solar_718 = filter(row -> Dates.month(row[:DateTimeTexas]) == month_of_interest && Dates.day(row[:DateTimeTexas]) == day_of_interest, df_solar);
df_load_718 = filter(row -> Dates.month(row[:DateTimeTexas]) == month_of_interest && Dates.day(row[:DateTimeTexas]) == day_of_interest, df_load);

current_point_quantile, index_quantile, distance_quantile = knn_quantile(df_load_718, df_wind_718, df_solar_718, kd_tree_quantile, k, hour_of_interest);
current_point_variance, index_variance, distance_variance = knn_variance(df_load_718, df_wind_718, df_solar_718, kd_tree_variance, k, hour_of_interest);

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

#---------------------------------Quantile data---------------------------------#

wind_event_quantile = event_quantile_clean(wind_event_quantile);
solar_event_quantile = event_quantile_clean(solar_event_quantile);
load_event_quantile = event_quantile_clean(load_event_quantile);

actual_wind_scenarios_variance = get_actual_scenarios(wind_scenario_variance, wind_event_quantile);
actual_solar_scenarios_variance = get_actual_scenarios(solar_scenario_variance, solar_event_quantile);
actual_load_scenarios_variance = get_actual_scenarios(load_scenario_variance, load_event_quantile);

wind_scenario_blocks_final_variance = seperate_blocks(actual_wind_scenarios_variance);
solar_scenario_blocks_final_variance = seperate_blocks(actual_solar_scenarios_variance);
load_scenario_blocks_final_variance = seperate_blocks(actual_load_scenarios_variance);

wind_plot = plotting_scenarios(wind_scenario_blocks_final_variance, "Wind Scenario Blocks");
solar_plot = plotting_scenarios(solar_scenario_blocks_final_variance, "Solar Scenario Blocks");
load_plot = plotting_scenarios(load_scenario_blocks_final_variance, "Load Scenario Blocks");

