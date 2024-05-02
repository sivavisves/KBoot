include("function_call.jl")

function process_energy_data_variance(df_wind::DataFrame, current_hour::Int64, current_min::Int64, horizon::Int64, minute_set)

    blocks_wind = block_disection(df_wind, current_hour, current_min, horizon, minute_set);
    blocks_wind_train, blocks_wind_test = split_train_test(blocks_wind);
    hour_next_wind_variance = hour_disection_variance(blocks_wind_train);

    return hour_next_wind_variance, blocks_wind_train, blocks_wind_test
end

function process_energy_data_quantile(df_wind::DataFrame, current_hour::Int64, current_min::Int64, horizon::Int64, minute_set)
    
    blocks_wind = block_disection(df_wind, current_hour, current_min, horizon, minute_set);
    blocks_wind_train, blocks_wind_test = split_train_test(blocks_wind);
    hour_next_wind_quantile = hour_disection_quantile(blocks_wind_train);

    return hour_next_wind_quantile
end


