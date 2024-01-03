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

# extract hour 1
filter_hour_df(df, hour) = filter(row -> Dates.hour(row[:DateTimeTexas]) == hour, df);

function knn_quantile(df_load_date, df_wind_date, df_solar_date, kd_tree_quantile, k)
    current_point_quantile = [filter_hour_df(df_load_date, 0).quantile[1], filter_hour_df(df_wind_date, 0).quantile[1], filter_hour_df(df_solar_date, 0).quantile[1]] # load, wind, solar
    index_knn_quantile, distance_quantile = knn(kd_tree_quantile, current_point_quantile, k, true);
    output_quantile = [index_knn_quantile distance_quantile];
    return current_point_quantile, output_quantile
end

function knn_variance(df_load_date, df_wind_date, df_solar_date, kd_tree_variance, k)
    current_point_variance = [filter_hour_df(df_load_date, 0).variance[1], filter_hour_df(df_wind_date, 0).variance[1], filter_hour_df(df_solar_date, 0).variance[1]] # load, wind, solar
    index_knn_variance, distance_variance = knn(kd_tree_variance, current_point_variance, k, true);
    output_variance = [index_knn_variance distance_variance];
    return current_point_variance, output_variance
end

function plot_knn(hour_1_wind_quantile, hour_1_solar_quantile, hour_1_load_quantile, current_point_quantile)
    wind_knn_quantile = [hour_1_wind_quantile[i] for i in index_knn_quantile];
    load_knn_quantile = [hour_1_load_quantile[i] for i in index_knn_quantile];
    solar_knn_quantile = [hour_1_solar_quantile[i] for i in index_knn_quantile];

    q_knn = scatter(hour_1_load_quantile, hour_1_wind_quantile, hour_1_solar_quantile, xlabel="Load", ylabel="Wind", zlabel="Solar", title="Hour 1 Quantile", legend=false)

end