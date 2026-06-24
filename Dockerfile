# Official Julia image
FROM julia:1.10-bookworm

# Work directory
WORKDIR /app

# Copy project files
COPY . .

# Instantiate the environment specifically for the current directory
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# Expose the port
EXPOSE 8080

# Explicitly use the project environment when starting the server
CMD ["julia", "--project=.", "server.jl"]