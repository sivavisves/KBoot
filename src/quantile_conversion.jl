
export within_quantile_check, determine_quantile, quantile_interpolation, process_forecast_quantiles


function within_quantile_check(df, lower, upper)
    df_quantile_array = zeros(size(df, 1));
    for i in 1:size(df, 1)
        if df[i, :BA_total] >= lower[i] && df[i, :BA_total] <= upper[i]
            df_quantile_array[i] = 1;
        else
            df_quantile_array[i] = 0;
        end
    end
    return df_quantile_array
end

function determine_quantile(marginals, actual_value::Float64)
    # If actual value is below the minimum or above the maximum of the marginals
    if actual_value <= marginals[1]
        dif_marginals = marginals[2] - marginals[1]
        ratio_cal = dif_marginals/0.01
        final_q = 0.01 - ratio_cal*(marginals[1] - actual_value)
        if final_q < 0
            return 0
        else
            return final_q
        end
    elseif actual_value >= marginals[end]
        dif_marginals = marginals[end] - marginals[end-1]
        ratio_cal = dif_marginals/0.01
        final_q = 0.99 + ratio_cal*(actual_value - marginals[end])
        if final_q > 1
            return 1
        else
            return final_q
        end
    else
        # If the value is within the range of the marginals
        for i in 1:(length(marginals)-1)
            if marginals[i] <= actual_value && actual_value <= marginals[i+1]
                # Linear interpolation
                quantile_lower = 0.01 + (i-1)*0.01
                quantile_upper = 0.01 + i*0.01
                weight = (actual_value - marginals[i]) / (marginals[i+1] - marginals[i])
                return quantile_lower + weight * (quantile_upper - quantile_lower)
            end
        end
    end
end

function quantile_interpolation(df_forecast, actuals)
    test_x = zeros(size(df_forecast)[2])
    for i in 1:size(df_forecast)[2]
        test_x[i] = determine_quantile(Float64.(df_forecast[!, i]), actuals[i, :BA_total])
    end
    return test_x
end

function process_forecast_quantiles(df_wind, df_solar, df_load, df_wind_forecast_quantiles, df_solar_forecast_quantiles, df_load_forecast_quantiles, df_wind_forecast, df_solar_forecast, df_load_forecast) 
    # Extract quantiles
    lower_wind = df_wind_forecast_quantiles[:, :x1]
    upper_wind = df_wind_forecast_quantiles[:, :x99]
    lower_solar = df_solar_forecast_quantiles[:, :x1]
    upper_solar = df_solar_forecast_quantiles[:, :x99]
    lower_load = df_load_forecast_quantiles[:, :x1]
    upper_load = df_load_forecast_quantiles[:, :x99]

    df_wind_copy = deepcopy(df_wind)
    df_solar_copy = deepcopy(df_solar)
    df_load_copy = deepcopy(df_load)
    
    # Check if within quantiles
    wind_check = within_quantile_check(df_wind_copy, lower_wind, upper_wind)
    solar_check = within_quantile_check(df_solar_copy, lower_solar, upper_solar)
    load_check = within_quantile_check(df_load_copy, lower_load, upper_load)
    
    # Add check results to dataframes
    df_wind_copy = insertcols!(df_wind_copy, :wind_check => wind_check, :lower_wind => lower_wind, :upper_wind => upper_wind)
    df_solar_copy = insertcols!(df_solar_copy, :solar_check => solar_check, :lower_solar => lower_solar, :upper_solar => upper_solar)
    df_load_copy = insertcols!(df_load_copy, :load_check => load_check, :lower_load => lower_load, :upper_load => upper_load)
    
    # Convert quantiles
    df_wind_converted_historical = quantile_interpolation(df_wind_forecast, df_wind_copy)
    df_solar_converted_historical = quantile_interpolation(df_solar_forecast, df_solar_copy)
    df_load_converted_historical = quantile_interpolation(df_load_forecast, df_load_copy)
    
    # Add converted quantiles to dataframes
    df_wind_copy[!, :quantile] = df_wind_converted_historical
    df_solar_copy[!, :quantile] = df_solar_converted_historical
    df_load_copy[!, :quantile] = df_load_converted_historical

    variance_load = compute_sample_variance(df_load_forecast);
    variance_solar = compute_sample_variance(df_solar_forecast);
    variance_wind = compute_sample_variance(df_wind_forecast);

    # replace variance in df_wind to variance_wind
    df_wind_copy[!, :variance] = variance_wind;
    df_solar_copy[!, :variance] = variance_solar;
    df_load_copy[!, :variance] = variance_load;
    
    return df_wind_copy, df_solar_copy, df_load_copy
end

function compute_variance(df::DataFrame)
    num_columns = size(df, 2)
    variances = zeros(num_columns)

    for i in 1:num_columns
        kde_fit = kde(df[! , i])
        E_X = sum(kde_fit.x .* kde_fit.density) * step(kde_fit.x)
        E_X2 = sum(kde_fit.x .^ 2 .* kde_fit.density) * step(kde_fit.x)
        variance = E_X2 - E_X^2
        variances[i] = variance
    end

    return variances
end

function compute_sample_variance(df::DataFrame)
    num_columns = size(df, 2)
    variances = zeros(num_columns)

    for i in 1:num_columns
        column_data = df[!, i]  # Extract the column
        n = length(column_data)
        mean_value = mean(column_data)  # Calculate the mean
        variance = sum((column_data .- mean_value).^2) / (n - 1)  # Sample variance
        variances[i] = variance
    end

    return variances
end

