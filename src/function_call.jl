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
        hour_1[i] = blocks[i][1,:quantile];
    end
    return hour_1
end

# disecting hours based on the hour of the day (variance)
function hour_disection_variance(hour, blocks)
    hour_1 = zeros(size(blocks)[1]);
    for i in 1:size(blocks)[1]
        hour_1[i] = blocks[i][1,:variance];
    end
    return hour_1
end