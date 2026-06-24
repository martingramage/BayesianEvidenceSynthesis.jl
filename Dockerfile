# Julia image
FROM julia:1.10-bookworm

# Working directory
WORKDIR /app

# Copy project files into the container
COPY . .

# Instantiate the environment to install all required packages
RUN julia -e 'using Pkg; Pkg.instantiate()'

# Port Oxygen server is using
EXPOSE 8080

# Start the server
CMD ["julia", "--project=.", "server.jl"]