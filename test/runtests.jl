using ObaServer
using Test

_rm(dir) = rm(dir; force = true, recursive = true)

@testset "ObaServer.jl" begin
    
    vault = joinpath(@__DIR__, "test_vault")
    _rm(vault); mkpath(vault);

    try

        # test file
        
        # startup.oba.jl
        rstr1 = string(rand(10))
        jlfile = joinpath(vault, "startup.oba.jl")
        tfile1 = joinpath(vault, "test_file1")
        write(jlfile, 
            """
            write("$tfile1", "$rstr1")
            """
        )

        # mdfile
        rstr2 = string(rand(10))
        mdfile = joinpath(vault, "file.md")
        tfile2 = joinpath(vault, "test_file2")
        write(mdfile, 
            """
            %% #!Oba
            ```julia
            write("$tfile2", "$rstr2")
            ```
            %%
            """
        )

        # run server
        run_server(vault; niters = 1, force = true)

        # tests
        @test read(tfile1, String) == rstr1
        @test read(tfile2, String) == rstr2

    finally
        _rm(vault)
    end

end
