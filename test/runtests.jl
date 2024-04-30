@time using KBoot
using Test
using CSV, DataFrames, Plots, StatsPlots, Distributions, Random, KernelDensity, Dates, NearestNeighbors, Statistics, TimeZones, HDF5


@time @testset "KBoot.jl" begin

    file_wind = "../test/wind_scenario_blocks_hour_0_test.h5"
    file_solar = "../test/solar_scenario_blocks_hour_0_test.h5"
    file_load = "../test/load_scenario_blocks_hour_0_test.h5"

    wind_scenario_test = load_scenarios(file_wind, "LocalDateTime")
    solar_scenario_test = load_scenarios(file_solar, "LocalDateTime")
    load_scenario_test = load_scenarios(file_load, "LocalDateTime")

    # load historical quantiles
    df_wind = CSV.read("../Historical Quantiles/df_wind_2018_historical_quantiles.csv", DataFrame);
    df_solar = CSV.read("../Historical Quantiles/df_solar_2018_historical_quantiles.csv", DataFrame);
    df_load = CSV.read("../Historical Quantiles/df_load_2018_historical_quantiles.csv", DataFrame);
    
    # correction LocalDateTime
    df_wind.LocalDateTime= df_wind.DateTime .- Hour(6);
    df_solar.LocalDateTime = df_solar.DateTime .- Hour(6);
    df_load.LocalDateTime = df_load.DateTime .- Hour(6);

    # correcting extracted_hour
    df_wind.extracted_hour = hour.(df_wind.LocalDateTime);
    df_solar.extracted_hour = hour.(df_solar.LocalDateTime);
    df_load.extracted_hour = hour.(df_load.LocalDateTime);

    # load quantile data
    wind_event_quantile = CSV.read("../Quantiles/Wind Quantiles.csv", DataFrame);
    solar_event_quantile = CSV.read("../Quantiles/Solar Quantiles.csv", DataFrame);
    load_event_quantile = CSV.read("../Quantiles/Load Quantiles.csv", DataFrame);

    hour_of_interest = 0;
    horizon = 47;
    k = 17; # setting the number of nearest neighbors
    month_of_interest = 7;
    day_of_interest = 18;
    year_of_interest = 2018;

    wind_scenario_blocks_final_variance1, solar_scenario_blocks_final_variance1, load_scenario_blocks_final_variance1 = scenario_generation(df_wind, df_solar, df_load, wind_event_quantile, solar_event_quantile, load_event_quantile, year_of_interest, month_of_interest, day_of_interest, hour_of_interest, horizon,  k, hour_of_interest);

    data_to_hdf5("../test/wind_scenario_blocks_hour_$hour_of_interest", wind_scenario_blocks_final_variance1)
    data_to_hdf5("../test/solar_scenario_blocks_hour_$hour_of_interest", solar_scenario_blocks_final_variance1)
    data_to_hdf5("../test/load_scenario_blocks_hour_$hour_of_interest", load_scenario_blocks_final_variance1)

    file_wind = "../test/wind_scenario_blocks_hour_0.h5"
    file_solar = "../test/solar_scenario_blocks_hour_0.h5"
    file_load = "../test/load_scenario_blocks_hour_0.h5"

    @test wind_scenario = load_scenarios(file_wind, "LocalDateTime") == wind_scenario_test
    @test solar_scenario = load_scenarios(file_solar, "LocalDateTime") == solar_scenario_test
    @test load_scenario = load_scenarios(file_load, "LocalDateTime") == load_scenario_test
end
