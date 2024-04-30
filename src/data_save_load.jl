using HDF5

export data_to_hdf5, load_scenarios, load_price_scenarios

function data_to_hdf5(name::String, df::Vector{Any})
    filename = name * ".h5"  # Assign the filename with the extension
    h5open(filename, "w") do file
        for (i, df) in enumerate(df)
            groupname = "scenario_$i"  # Name of the group for each dataframe
            g = create_group(file, groupname)
    
            # Convert DataFrame to a format suitable for HDF5 storage
            for colname in names(df)
                coldata = df[!, colname]
                if colname == "LocalDateTime"  # Assuming this is your datetime column
                    coldata = string.(coldata)  # Convert datetime to string for storage
                end
                g[colname] = coldata
            end
        end
    end
end

function load_scenarios(file_path, DateTimeColumn)
    scenarios = []
    h5open(file_path, "r") do file
        keys_cache = collect(keys(file))  # Cache the keys to avoid repeated computation
        for scenario_name in keys_cache
            scenario_group = file[scenario_name]
            data_cols = Dict{Symbol, Vector{Any}}()
            for dataset_name in keys(scenario_group)
                dataset = read(scenario_group[dataset_name])
                sym_name = Symbol(dataset_name)
                if dataset_name == DateTimeColumn
                    # Convert to DateTime in a more efficient way
                    data_cols[sym_name] = DateTime.(string.(dataset), "yyyy-mm-ddTHH:MM:SS")
                else
                    data_cols[sym_name] = dataset
                end
            end
            # Construct DataFrame from dictionary
            df = DataFrame(data_cols)
            push!(scenarios, df)
        end
    end
    return scenarios
end

function load_price_scenarios(file_path)
    scenarios = []
    h5open(file_path, "r") do file
        for scenario_name in keys(file)
            scenario_group = file[scenario_name]
            df = DataFrame()
            for dataset_name in keys(scenario_group)
                dataset = read(scenario_group[dataset_name])
                df[!, dataset_name] = dataset
            end
            push!(scenarios, df)
        end
    end
    return scenarios
end