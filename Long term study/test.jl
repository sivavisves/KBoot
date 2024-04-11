using KBoot
using Test
using CSV, DataFrames, Plots, StatsPlots, Distributions, Random, KernelDensity, Dates, NearestNeighbors, Statistics, TimeZones, HDF5


function quantile_data_prep(df)
    # permute the dimension of the quantile data
    df = permutedims(df);
    #rename the columns x1 to p_1
    for i in 1:99
        rename!(df, Symbol("x$i") => Symbol("p_$i"));
    end
    insertcols!(df, 1, :forecast_time => ["h$i" for i in 0:8759]);
    return df
end

function covert2array(vec_df::Vector{Any})::Array{Float64, 2}
    array = zeros(Float64, length(vec_df[1].BA_total), length(vec_df))
    for (i, df) in enumerate(vec_df)
        array[:, i] = df.BA_total
    end
    return array
end

# load historical quantiles
df_wind = CSV.read("./Historical Quantiles/df_wind_2018_historical_quantiles.csv", DataFrame);
df_solar = CSV.read("./Historical Quantiles/df_solar_2018_historical_quantiles.csv", DataFrame);
df_load = CSV.read("./Historical Quantiles/df_load_2018_historical_quantiles.csv", DataFrame);

# correction DateTimeTexas
df_wind.DateTimeTexas = df_wind.DateTime .- Hour(6);
df_solar.DateTimeTexas = df_solar.DateTime .- Hour(6);
df_load.DateTimeTexas = df_load.DateTime .- Hour(6);

# correcting extracted_hour
df_wind.extracted_hour = hour.(df_wind.DateTimeTexas);
df_solar.extracted_hour = hour.(df_solar.DateTimeTexas);
df_load.extracted_hour = hour.(df_load.DateTimeTexas);

# load quantile data
wind_event_quantile = CSV.read("./Long term study/Data File/wind_forecast_conversion.csv", DataFrame);
solar_event_quantile = CSV.read("./Long term study/Data File/solar_forecast_conversion.csv", DataFrame);
load_event_quantile = CSV.read("./Long term study/Data File/load_forecast_conversion.csv", DataFrame);

wind_quantile = quantile_data_prep(wind_event_quantile)
solar_quantile = quantile_data_prep(solar_event_quantile)
load_quantile = quantile_data_prep(load_event_quantile)

hour_of_interest = 0;
horizon = 48;
k = 10;

output_dir = "./Long term study/Scenario Data/"

function select_hours_range(df::DataFrame, start_hour::Int, hours_range::Int)
    # Generate the column symbols dynamically based on the starting hour and the range
    col_symbols = Symbol.("h" .* string.(start_hour:(start_hour + hours_range - 1)))
    
    # Filter the DataFrame to select only the generated columns
    selected_df = select(df, col_symbols)
    
    return selected_df
end

# Example usage
# Assuming wind_event_quantile is your DataFrame and you want to start from hour 5 for the next 48 hours
# Note: Make sure your DataFrame has the columns you are trying to select
start_hour = 2
hours_range = 48 # Adjusted for the example to match h5 to h13, change to 48 for your actual use case

selected_columns_df = select_hours_range(wind_event_quantile, start_hour, hours_range)

# Now selected_columns_df contains only the columns from h5 to h13


# filter specific columns in wind_event_quantile from h5 - h13
x = select(wind_event_quantile, :h5, :h6, :h7, :h8, :h9, :h10, :h11, :h12, :h13);

month_of_interest = 1
day_of_interest = 1
hour_of_interest = 0

function filter_by_datetime_range(df::DataFrame, datetime_col::Symbol, year_of_interest::Int, month_of_interest::Int, day_of_interest::Int, hour_of_interest::Int, horizon_hours::Int)
    # Calculate the start and end datetime of interest
    start_datetime = DateTime(year_of_interest, month_of_interest, day_of_interest, hour_of_interest)
    end_datetime = start_datetime + Hour(horizon_hours)
    
    # Filter the DataFrame based on the datetime range
    filtered_df = filter(row -> begin
        datetime_val = row[datetime_col]
        datetime_val >= start_datetime && datetime_val < end_datetime
    end, df)
    
    return filtered_df
end

df_wind_718 = filter_by_datetime_range(df_wind, :DateTimeTexas, 2018, 7, 18, 3, 48)


function extract_first_point(df)
    return [df.BA_total[1]]
end
current_point = [extract_first_point(df_load_718), extract_first_point(df_wind_718), extract_first_point(df_solar_718)]

new_df = permutedims(wind_event_quantile);

new_headers = Symbol.(Vector(new_df[1, :]))

wind_event_quantile_clean = event_quantile_clean(wind_event_quantile);
solar_event_quantile_clean = event_quantile_clean(solar_event_quantile);
load_event_quantile_clean = event_quantile_clean(load_event_quantile);
