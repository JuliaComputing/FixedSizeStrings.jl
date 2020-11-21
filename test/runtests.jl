using Test
using SizedStrings


@testset "SizedStrings.jl" begin

    @testset "Constructors" begin
        @test SizedString{0}() == SizedString{0}("")
        @test SizedString{4}(NTuple{4, UInt8}(('w', 'h', 'o', 'm'))) == SizedString{4}("whom")
        @test SizedString{5}('B', 'u', 'z', 'z', '!') == SizedString{5}("Buzz!")
        @test SizedString{6}(UInt8['u', 'v', 'w', 'x', 'y', 'z']) == SizedString{6}("uvwxyz")
        @test SizedString{7}(b"abcdefg") == SizedString{7}("abcdefg")

        s = SizedString{3}("foo")
        @test SizedString{3}(s) === s

        @test_throws ArgumentError SizedString{3}("ab")
        @test_throws ArgumentError SizedString{4}(NTuple{5, UInt8}(('!', '(', '/', '%', ')')))
        @test_throws ArgumentError SizedString{5}('B', 'u', 'z', 'z')
        @test_throws ArgumentError SizedString{6}(UInt8['t', 'u', 'v', 'w', 'x', 'y', 'z'])
        @test_throws ArgumentError SizedString{7}(b"abcdef")

        @test_throws InexactError SizedString{3}("Σi")

        @test sized"bar" == SizedString{3}("bar")
    end

    @testset "AbstractString Interface" begin
        N = rand(3:9)
        s = rand(Char(32):Char(126), N)

        ss = SizedString{N}(s)

        @test ncodeunits(ss) == N

        @test codeunit(ss) == UInt8

        @test isvalid(ss, rand(eachindex(s))) == true
        @test isvalid(ss, N+1) == false

        @test sizeof(ss) == N

        @test firstindex(ss) == 1
        @test lastindex(ss) == N

        s0 = SizedString{0}("")
        @test isempty(s0)
        @test !isempty(ss)
    end

    @testset "Iteration" begin
        N = 9
        s = rand(Char(32):Char(126), N)

        ss = SizedString{N}(s)

        for c in ss
            @test c isa Char
            @test c == popfirst!(s)
        end

        @test length(s) == 0

        @test Base.IteratorSize(typeof(ss)) == Base.HasLength()
        @test length(ss) == length(typeof(ss)) == N

        @test Base.IteratorEltype(typeof(ss)) == Base.HasEltype()
        @test eltype(ss) == eltype(typeof(ss)) == Char
    end


    @testset "Indexing" begin
        N = 7
        s = String(rand(Char(32):Char(126), N))

        ss = SizedString{N}(s)

        # Not sure how to test that inbounds actually works
        inbound_codeunit(i) = (local s = ss; @inbounds codeunit(s, i))
        @test_broken inbound_codeunit(0) isa UInt8

        inbound_getindex(i) = (local s = ss; @inbounds s[i])
        @test_broken inbound_getindex(0) isa Char

        for i in eachindex(s)
            @test codeunit(ss, i) === codeunit(s, i)
            @test inbound_codeunit(i) === codeunit(s, i)

            @test ss[i] === s[i]
            @test inbound_getindex(i) === s[i]

            @test ss[1:i] == s[1:i]
            @test ss[collect(i:N)] == s[collect(i:N)]
        end
    end

    let e = SizedString{0}("")
        @test e == ""
        @test length(e) == 0
        @test convert(String, e) === ""
        @test isa(convert(String, e), String)
        @test convert(SizedString{0}, "") == e
    end

    let s = SizedString{3}("xyZ")
        @test s == "xyZ"
        @test isless(s, "yyZ")
        @test isless("xyY", s)
        @test length(s) == sizeof(s) == 3
        @test collect(s) == ['x', 'y', 'Z']
        @test convert(String, s) == "xyZ"
        @test convert(SizedString{3}, "xyZ") == s
        @test isa(convert(SizedString{3}, "xyZ"), SizedString)
    end

    let b = IOBuffer()
        write(b, "a tEst str1ng")
        seekstart(b)
        @test read(b, SizedString{4}) == "a tE"
        @test read(b, SizedString{2}) == "st"
        b = IOBuffer()
        data = "\0Te\$t\0_"
        write(b, SizedString{length(data)}(data))
        @test String(take!(b)) == data
    end

end # outer testset
