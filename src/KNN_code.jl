# Data Prep for p_knn

function data_prep_knn_quantile(hour_load_quantile, hour_wind_quantile, hour_solar_quantile)
    combined_set_quantile = [hour_load_quantile hour_wind_quantile hour_solar_quantile]
    kd_tree_quantile = KDTree(permutedims(combined_set_quantile))
    return kd_tree_quantile
end

function data_prep_knn_variance(hour_load_variance, hour_wind_variance, hour_solar_variance)
    combined_set_variance = [hour_load_variance hour_wind_variance hour_solar_variance]
    kd_tree_variance = KDTree(permutedims(combined_set_variance))
    return kd_tree_variance
end

function data_prep_knn_combined(combined_set_quantile, combined_set_variance)
    combined_set = hcat(combined_set_quantile, combined_set_variance)
    kd_tree_combined = KDTree(permutedims(combined_set))
    return kd_tree_combined
end

# extract hour 1
# filter_time_df(df, run_time) = filter(row -> 
#     Dates.hour(row[:LocalDateTime]) == hour(run_time) && Dates.minute(row[:LocalDateTime]) == minute(run_time), df);
filter_time_df(df, run_time) = filter(row -> row[:LocalDateTime] == run_time, df);

function knn_quantile(df_load_date, df_wind_date, df_solar_date, kd_tree_quantile, k, current_time)
    current_point_quantile = [filter_time_df(df_load_date, current_time).quantile[1], filter_time_df(df_wind_date, current_time).quantile[1], filter_time_df(df_solar_date, current_time).quantile[1]] # load, wind, solar
    index_knn_quantile, distance_quantile = knn(kd_tree_quantile, current_point_quantile, k, true);
    return current_point_quantile, index_knn_quantile, distance_quantile
end

function knn_variance(df_load_date, df_wind_date, df_solar_date, kd_tree_variance, k, current_time)
    current_point_variance = [filter_time_df(df_load_date, current_time).variance[1], filter_time_df(df_wind_date, current_time).variance[1], filter_time_df(df_solar_date, current_time).variance[1]] # load, wind, solar
    index_knn_variance, distance_variance = knn(kd_tree_variance, current_point_variance, k, true);
    return current_point_variance, index_knn_variance, distance_variance
end

function knn_combined(df_load_date, df_wind_date, df_solar_date, kd_tree_combined, k, current_time)
    current_point_combined = [filter_time_df(df_load_date, current_time).quantile[1], filter_time_df(df_wind_date, current_time).quantile[1], filter_time_df(df_solar_date, current_time).quantile[1], filter_time_df(df_load_date, current_time).variance[1], filter_time_df(df_wind_date, current_time).variance[1], filter_time_df(df_solar_date, current_time).variance[1]] # load, wind, solar
    index_knn_combined, distance_combined = knn(kd_tree_combined, current_point_combined, k, true);
    return current_point_combined, index_knn_combined, distance_combined
end

function extract_first_point(df)
    return [df.BA_total[1]]
end

function filter_by_datetime_range(df::DataFrame, datetime_col::Symbol, start_datetime::DateTime, horizon_length::Int)
    # Calculate the start and end datetime of interest
    # end_datetime = start_datetime + Hour(horizon_hours)
    end_datetime = start_datetime + Minute(5*horizon_length)
    
    # Filter the DataFrame based on the datetime range
    filtered_df = filter(row -> begin
        datetime_val = row[datetime_col]
        datetime_val >= start_datetime && datetime_val < end_datetime
    end, df)
    
    return filtered_df
end

