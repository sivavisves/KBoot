using DataFrames, Dates

function block_disection(df_set::DataFrame, current_hour::Int, block_size::Int)
    # Convert the DateTimeTexas column to a DateTime object
    #df_set[!, :DateTimeObj] = DateTime.(df_set[!, :DateTimeTexas], "yyyy-mm-ddTHH:MM:SS.sss")
    df_set[!, :extracted_hour] = hour.(df_set[!, :DateTimeTexas])

    # Find the index of the first occurrence of current_hour in the dataset
    start_index = findfirst(isequal(current_hour), df_set[!, :extracted_hour])
    if isnothing(start_index)  # If the current_hour is not found in the dataset, return an empty array
        return []
    end

    # Extract blocks starting from the start_index
    stride = 24
    blocks = []
    idx = start_index

    while idx + block_size - 1 <= nrow(df_set)
        push!(blocks, df_set[idx:idx+block_size-1, :])
        idx += stride
    end

    return blocks
end


# splitting dataset into training and testing sets
function split_train_test(blocks)
    # Define the training set size
    train_size = 0.8

    # Calculate the number of training blocks
    num_train = Int(round(train_size * length(blocks)))

    # Extract the training blocks
    train = blocks[1:num_train]

    # Extract the testing blocks
    test = blocks[(num_train+1):end]

    return train, test
end

# disecting hours based on the hour of the day (quantile)
function hour_disection_quantile(hour, blocks)
    hour_1 = zeros(size(blocks)[1]);
    for i in 1:size(blocks)[1]
        hour_1[i] = blocks[i][2,:quantile];
    end
    return hour_1
end

# disecting hours based on the hour of the day (variance)
function hour_disection_variance(hour, blocks)
    hour_1 = zeros(size(blocks)[1]);
    for i in 1:size(blocks)[1]
        hour_1[i] = blocks[i][2,:variance];
    end
    return hour_1
end

# get blocks based on index_knn
function get_blocks(index_knn, blocks)
    blocks_knn = [];
    for i in 1:length(index_knn)
        push!(blocks_knn, blocks[index_knn[i]])
    end
    return blocks_knn
end

function event_quantile_clean(df)
    new_df = permutedims(df)
    # Convert the first row to a vector of symbols
    new_headers = Symbol.(Vector(new_df[1, :]))

    # Rename columns
    rename!(new_df, new_headers)

    # Delete the first row
    df = new_df[2:end, :]

    # Convert all columns to Float64
    for col in names(df)
        df[!, col] = convert(Vector{Float64}, df[!, col])
    end
    return df
end

function determine_actual_value(marginals::Vector{Float64}, quantile_value::Float64)
    # If quantile value is at the extremes
    if quantile_value <= 0.01
        dif_marginals = marginals[2] - marginals[1]
        ratio_cal = dif_marginals/0.01
        return marginals[1] - (0.01 - quantile_value) * ratio_cal
    elseif quantile_value >= 0.99
        dif_marginals = marginals[end] - marginals[end-1]
        ratio_cal = dif_marginals/0.01
        return marginals[end] + (quantile_value - 0.99) * ratio_cal
    end

    # If the quantile is within the range
    for i in 1:(length(marginals)-1)
        quantile_lower = 0.01 + (i-1)*0.01
        quantile_upper = 0.01 + i*0.01

        if quantile_lower <= quantile_value <= quantile_upper
            # Linear interpolation
            weight = (quantile_value - quantile_lower) / (quantile_upper - quantile_lower)
            return marginals[i] + weight * (marginals[i+1] - marginals[i])
        end
    end
end

function determine_actual_value(marginals::Vector{Float64}, quantile_value::Float64)
    # If quantile value is at the extremes
    if quantile_value <= 0.01
        dif_marginals = marginals[2] - marginals[1]
        ratio_cal = dif_marginals/0.01
        return marginals[1] - (0.01 - quantile_value) * ratio_cal
    elseif quantile_value >= 0.99
        dif_marginals = marginals[end] - marginals[end-1]
        ratio_cal = dif_marginals/0.01
        return marginals[end] + (quantile_value - 0.99) * ratio_cal
    end

    # If the quantile is within the range
    for i in 1:(length(marginals)-1)
        quantile_lower = 0.01 + (i-1)*0.01
        quantile_upper = 0.01 + i*0.01

        if quantile_lower <= quantile_value <= quantile_upper
            # Linear interpolation
            weight = (quantile_value - quantile_lower) / (quantile_upper - quantile_lower)
            return marginals[i] + weight * (marginals[i+1] - marginals[i])
        end
    end
end

function get_actual_scenarios(scenarios, event_quantile)
    actual_scenarios = DataFrame(DateTimeTexas = DateTime[], block = Int64[], BA_total = Float64[])
    for i in 1:length(scenarios)
        for j in 1:length(scenarios[i].quantile)
            push!(actual_scenarios, [scenarios[i].DateTimeTexas[j] i determine_actual_value(event_quantile[!, Symbol("h"*string(j))], scenarios[i].quantile[j])])
        end
    end
    return actual_scenarios
end

# seperate actual_wind_scenarios into different blocks
function seperate_blocks(df, k)
    blocks = []
    for i in 1:k
        push!(blocks, filter(row -> row[:block] == i, df))
    end
    return blocks
end

function plotting_scenarios(scenario_blocks_final, title, horizon)
    x = plot(1:horizon, scenario_blocks_final[1].BA_total, 
                color=:black, 
                alpha=0.5, 
                linewidth=2, 
                label="Scenario 1", 
                title=title, xlabel="Hour", ylabel="Output (MW)", 
                legend=:outerbottom, legendcolumns=4,
                xticks=0:4:horizon)

    for i in 2:length(scenario_blocks_final)
        plot!(1:horizon, scenario_blocks_final[i].BA_total, alpha=0.5, linewidth=2, label="Scenario $(i)")
    end
    return x
end
