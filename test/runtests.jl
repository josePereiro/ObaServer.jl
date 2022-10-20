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
        jlfile = joinpath(vault, "startup.oba.md")
        tfile1 = joinpath(vault, "test_file1")
        write(jlfile, 
            """
            ```julia #!Oba -s
            # test run
            write("$tfile1", "$rstr1")
            # show stuff
            ObaServer.show_server_state()
            ```
            """
        )

        # mdfile
        rstr2 = string(rand(10))
        mdfile = joinpath(vault, "file.md")
        tfile2 = joinpath(vault, "test_file2")
        tfile3 = joinpath(vault, "test_file3")
        write(mdfile, 
            """
            %% 
            ```julia #!Oba
            # test run
            write("$tfile2", "$rstr2")
            # show stuff
            ObaServer.show_server_state()
            # Test macros
            dir = @__DIR__()
            file = @Base.__FILE__
            line = Base.@__LINE__()
            write("$tfile3", 
                string("%%", dir , "%%", file, "%%", line, "%%")
            )
            ```
            %%
            """
        )

        # run server
        run_server(vault; niters = 1, force_trigger = true, note_ext = ".md")

        # tests
        @test read(tfile1, String) == rstr1
        @test read(tfile2, String) == rstr2

        # macros
        txt3 = read(tfile3, String)
        @test contains(txt3, string("%", dirname(mdfile), "%"))
        @test contains(txt3, string("%", mdfile, "%"))
        @test contains(txt3, string("%", 1, "%"))

    finally
        _rm(vault)
    end

end
