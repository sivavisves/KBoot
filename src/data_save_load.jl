using HDF5

export data_to_hdf5, load_scenarios

function data_to_hdf5(name::String, df::Vector{Any})
    filename = name * ".h5"  # Assign the filename with the extension
    h5open(filename, "w") do file
        for (i, df) in enumerate(df)
            groupname = "scenario_$i"  # Name of the group for each dataframe
            g = create_group(file, groupname)
    
            # Convert DataFrame to a format suitable for HDF5 storage
            for colname in names(df)
                coldata = df[!, colname]
                if colname == "DateTimeTexas"  # Assuming this is your datetime column
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
        for scenario_name in keys(file)
            scenario_group = file[scenario_name]
            df = DataFrame()
            for dataset_name in keys(scenario_group)
                dataset = read(scenario_group[dataset_name])
                if dataset_name == DateTimeColumn
                    # Convert to DateTime
                    df[!, dataset_name] = [DateTime(String(dt), "yyyy-mm-ddTHH:MM:SS") for dt in dataset]
                else
                    df[!, dataset_name] = dataset
                end
            end
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