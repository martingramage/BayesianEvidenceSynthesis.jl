# Official Julia image
FROM julia:1.10-bookworm

# Work directory
WORKDIR /app

# Copy project files
COPY . .

# 1 thread for package operations
ENV JULIA_NUM_PRECOMPILE_TASKS=1

# Instantiate the environment specifically for the current directory
RUN julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Expose the port
EXPOSE 8080

# Explicitly use the project environment when starting the server (deleting unused RAM)
CMD ["julia", "--project=.", "--heap-size-hint=350M", "server.jl"]