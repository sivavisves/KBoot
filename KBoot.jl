include("src/Kboot_summary_call.jl")

# open file containing quantiles and save them into a dataframe
df_wind = CSV.read("Historical Quantiles/df_wind_2018_historical_quantiles.csv", DataFrame);
df_solar = CSV.read("Historical Quantiles/df_solar_2018_historical_quantiles.csv", DataFrame);
df_load = CSV.read("Historical Quantiles/df_load_2018_historical_quantiles.csv", DataFrame);

hour_1_wind_variance = process_energy_data_variance(df_wind, 0, 48);
hour_1_solar_variance = process_energy_data_variance(df_solar, 0, 48);
hour_1_load_variance = process_energy_data_variance(df_load, 0, 48);

hour_1_wind_quantile = process_energy_data_quantile(df_wind, 0, 48);
hour_1_solar_quantile = process_energy_data_quantile(df_solar, 0, 48);
hour_1_load_quantile = process_energy_data_quantile(df_load, 0, 48);

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

kd_tree_quantile = data_prep_knn_quantile(hour_1_load_quantile, hour_1_wind_quantile, hour_1_solar_quantile);

kd_tree_variance = data_prep_knn_variance(hour_1_load_variance, hour_1_wind_variance, hour_1_solar_variance);

# filter 7/18 date from df_wind
df_wind_718 = filter(row -> Dates.month(row[:DateTimeTexas]) == 7 && Dates.day(row[:DateTimeTexas]) == 18, df_wind);
df_solar_718 = filter(row -> Dates.month(row[:DateTimeTexas]) == 7 && Dates.day(row[:DateTimeTexas]) == 18, df_solar);
df_load_718 = filter(row -> Dates.month(row[:DateTimeTexas]) == 7 && Dates.day(row[:DateTimeTexas]) == 18, df_load);


current_point_quantile, output_quantile = knn_quantile(df_load_718, df_wind_718, df_solar_718, kd_tree_quantile, 17);
current_point_variance, output_variance = knn_variance(df_load_718, df_wind_718, df_solar_718, kd_tree_variance, 17);