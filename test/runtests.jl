# test/runtests.jl
using Test
using BayesianEvidenceSynthesis

@testset "BayesianEvidenceSynthesis.jl Pipeline Tests" begin

   @testset "Binary Endpoint (MCMC & Turing)" begin
        filepath = tempname() * ".txt"
        open(filepath, "w") do io
            write(io, "binary\n")
            write(io, "r,n\n")
            write(io, "2,10\n")
            write(io, "5,20\n")
            write(io, "3,15\n")
        end
        
        result = run_inference_pipeline(filepath)
        @test isapprox(sum(result.posterior.weights), 1.0, atol=1e-5)
        @test result.ess > 0
        rm(filepath)
    end

    @testset "Normal Endpoint (Numerical Integration)" begin
        filepath = tempname() * ".txt"
        open(filepath, "w") do io
            println(io, "normal")
            println(io, "mean,sd,n")
            println(io, "0.5,0.1,10")
            println(io, "0.6,0.12,15")
        end

        result = run_inference_pipeline(filepath)

        @test isapprox(sum(result.posterior.weights), 1.0, atol=1e-5)
        @test isapprox(sum(result.robustified_posterior.weights), 1.0, atol=1e-5)
        @test result.ess > 0
        
        rm(filepath)
    end
end