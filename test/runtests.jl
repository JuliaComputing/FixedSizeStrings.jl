using Base.Test
using FixedSizeStrings

let e = FixedSizeString{0}("")
    @test e == ""
    @test length(e) == 0
    @test convert(String, e) == ""
    @test isa(convert(String, e), String)
    @test convert(FixedSizeString{0}, "") == e
end

let s = FixedSizeString{3}("xyZ")
    @test s == "xyZ"
    @test isless(s, "yyZ")
    @test isless("xyY", s)
    @test length(s) == sizeof(s) == 3
    @test collect(s) == ['x', 'y', 'Z']
    @test convert(String, s) == "xyZ"
    @test convert(FixedSizeString{3}, "xyZ") == s
    @test isa(convert(FixedSizeString{3}, "xyZ"), FixedSizeString)
end

let b = IOBuffer()
    write(b, "a tEst str1ng")
    seekstart(b)
    @test read(b, FixedSizeString{4}) == "a tE"
    @test read(b, FixedSizeString{2}) == "st"
    b = IOBuffer()
    data = "\0Te\$t\0_"
    write(b, FixedSizeString(data))
    @test String(take!(b)) == data
end

# strings and unicode

s = "普通话/普通話"
p = convert(FixedSizeString, s)
@test p == s
@test repr(p) == repr(s)
@test collect(p) == collect(s)
@test search(p, "通") == search(s, "通")
@test rsearch(p, "通") == rsearch(s, "通")
@test reverse(p) == reverse(s)

# test right-to-left

s = "سلام"
p = convert(FixedSizeString, s)
@test p == s
@test repr(p) == repr(s)
@test collect(p) == collect(s)
@test search(p, "ا") == search(s, "ا")
@test rsearch(p, "ا") == rsearch(s, "ا")
@test reverse(p) == reverse(s)

# test string conversions

@test isbits(p)
@test reverse(p) isa RevString{FixedSizeString{8}}
@test String(p) isa String
@test String(p) == s
@test string(p) isa AbstractString

# test string slices

s = "aye bee sea"
p = convert(FixedSizeString, s)
@test p[5:7] isa SubString{FixedSizeString{11}}
@test p[5:7] == "bee"
