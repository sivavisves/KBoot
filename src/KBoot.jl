module KBoot
    using CSV, DataFrames, Plots, StatsPlots, Distributions, Random, KernelDensity, Dates, NearestNeighbors, Statistics, TimeZones, StatsBase
    include("KBoot_summary_call.jl")

    export scenario_generation

    function scenario_generation(df_wind, df_solar, df_load, wind_event_quantile_clean, solar_event_quantile_clean, load_event_quantile_clean, run_time, horizon::Int64, k::Int64; minute_set::Int=0)
        year_of_interest = Dates.year(run_time)
        month_of_interest = Dates.month(run_time)
        day_of_interest = Dates.day(run_time)
        hour_of_interest = Dates.hour(run_time)
        minute_of_interest = Dates.minute(run_time)
    
        # Data cleaning and processing phase
        hour_1_wind_variance, blocks_wind_train, blocks_wind_test= process_energy_data_variance(df_wind, hour_of_interest, minute_of_interest, horizon, minute_set)
        hour_1_solar_variance, blocks_solar_train, blocks_solar_test = process_energy_data_variance(df_solar, hour_of_interest, minute_of_interest, horizon, minute_set)
        hour_1_load_variance, blocks_load_train, blocks_load_test = process_energy_data_variance(df_load, hour_of_interest, minute_of_interest, horizon, minute_set)
    
        hour_1_wind_quantile = process_energy_data_quantile(df_wind, hour_of_interest, minute_of_interest, horizon, minute_set);
        hour_1_solar_quantile = process_energy_data_quantile(df_solar, hour_of_interest, minute_of_interest, horizon, minute_set);
        hour_1_load_quantile = process_energy_data_quantile(df_load, hour_of_interest, minute_of_interest, horizon, minute_set);

        #---------------------------------KNN---------------------------------#
        # Data Prep for knn
        kd_tree_combined = data_prep_knn_combined([hour_1_load_quantile hour_1_wind_quantile hour_1_solar_quantile], [hour_1_load_variance hour_1_wind_variance hour_1_solar_variance]);

        #filtering the data for a specific date.
        # filter 7/18 date from df_wind
        df_wind_718 = filter_by_datetime_range(df_wind, :LocalDateTime, year_of_interest, month_of_interest, day_of_interest, hour_of_interest, minute_of_interest, horizon, minute_set);
        df_solar_718 = filter_by_datetime_range(df_solar, :LocalDateTime, year_of_interest, month_of_interest, day_of_interest, hour_of_interest, minute_of_interest, horizon, minute_set);
        df_load_718 = filter_by_datetime_range(df_load, :LocalDateTime, year_of_interest, month_of_interest, day_of_interest, hour_of_interest, minute_of_interest, horizon, minute_set);
        
        current_point_combined, index_combined, distance_combined = knn_combined(df_load_718, df_wind_718, df_solar_718, kd_tree_combined, k, hour_of_interest);
        current_point = [extract_first_point(df_load_718), extract_first_point(df_wind_718), extract_first_point(df_solar_718)]; # load, wind, solar
    

        wind_scenario_combined = get_blocks(index_combined, blocks_wind_train);
        solar_scenario_combined = get_blocks(index_combined, blocks_solar_train);
        load_scenario_combined = get_blocks(index_combined, blocks_load_train);

        #---------------------------------Quantile data---------------------------------#

        actual_wind_scenarios_combined = get_actual_scenarios(wind_scenario_combined, wind_event_quantile_clean, run_time, minute_set);
        actual_solar_scenarios_combined = get_actual_scenarios(solar_scenario_combined, solar_event_quantile_clean, run_time, minute_set);
        actual_load_scenarios_combined = get_actual_scenarios(load_scenario_combined, load_event_quantile_clean, run_time, minute_set);

        wind_scenario_blocks_final_combined = seperate_blocks(actual_wind_scenarios_combined, k);
        solar_scenario_blocks_final_combined = seperate_blocks(actual_solar_scenarios_combined, k);
        load_scenario_blocks_final_combined = seperate_blocks(actual_load_scenarios_combined, k);

        for i in 1:k
            load_scenario_blocks_final_combined[i][1,:].BA_total = current_point[1][1];
            wind_scenario_blocks_final_combined[i][1,:].BA_total = current_point[2][1];
            solar_scenario_blocks_final_combined[i][1,:].BA_total = current_point[3][1];
        end


        return wind_scenario_blocks_final_combined, solar_scenario_blocks_final_combined, load_scenario_blocks_final_combined
    end
end
