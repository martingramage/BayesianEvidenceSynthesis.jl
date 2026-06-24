# Official Julia image
FROM julia:1.10-bookworm

# Work directory
WORKDIR /app

# Copy project files
COPY . .

# Install dependencies
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.develop(PackageSpec(path=".")); Pkg.precompile()'

# Hugging Face port 7860
EXPOSE 7860

# Start the server normally
CMD ["julia", "--project=.", "server.jl"]