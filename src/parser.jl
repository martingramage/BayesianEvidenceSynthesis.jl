#src/parser.jl
using DataFrames, CSV

struct ClinicalStudyInput
    endpoint_type::Symbol
    data::DataFrame
end

const REQUIRED_COLUMNS = Dict(
    :binary => [:r, :n],
    :normal => [:mean, :sd, :n]
)

function validate_columns!(df::DataFrame, endpoint_type::Symbol)
    # Convert dataframe column names to Symbols to match the dictionary
    df_cols = Symbol.(names(df))
    
    required = get(REQUIRED_COLUMNS, endpoint_type, nothing)
    if isnothing(required)
        error("Unsupported endpoint type: $endpoint_type")
    end
    
    # Check for missing columns
    missing_cols = setdiff(required, df_cols)
    if !isempty(missing_cols)
        error("Missing columns for $endpoint_type endpoint: $missing_cols. Found: $df_cols")
    end
end

function parse_input_file(filepath::String)
    open(filepath, "r") do io
        line = readline(io)
        endpoint_type = Symbol(strip(line))
        
        # Read the rest of the file directly
        content = read(io, String)
        df = CSV.read(IOBuffer(content), DataFrame)
        
        # Ensure column names are clean and symbols
        rename!(df, Symbol.(strip.(string.(names(df)))))
        
        validate_columns!(df, endpoint_type)
        return ClinicalStudyInput(endpoint_type, df)
    end
end