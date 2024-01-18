include("Kboot.jl")

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

wind_plot1, solar_plot1, load_plot1, q_knn1, v_knn1, wind_scenario_blocks_final_variance1, solar_scenario_blocks_final_variance1, load_scenario_blocks_final_variance1 = scenario_generation(df_wind, df_solar, df_load, wind_event_quantile, solar_event_quantile, load_event_quantile, month_of_interest, day_of_interest, horizon, hour_of_interest, k);

t = scenario_generation(df_wind, df_solar, df_load, wind_event_quantile, solar_event_quantile, load_event_quantile, month_of_interest, day_of_interest, horizon, hour_of_interest, k)


data_to_hdf5("wind_scenario_blocks_hour_0", wind_scenario_blocks_final_variance1)
data_to_hdf5("solar_scenario_blocks_hour_0", solar_scenario_blocks_final_variance1)
data_to_hdf5("load_scenario_blocks_hour_0", load_scenario_blocks_final_variance1)

file_wind = "wind_scenario_blocks_hour_0.h5"
file_solar = "solar_scenario_blocks_hour_0.h5"
file_load = "load_scenario_blocks_hour_0.h5"

wind_scenario = load_scenarios(file_wind, "DateTimeTexas")
solar_scenario = load_scenarios(file_solar, "DateTimeTexas")
load_scenario = load_scenarios(file_load, "DateTimeTexas")