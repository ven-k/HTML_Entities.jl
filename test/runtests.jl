using HTML_Entities
using Base.Test

# Test the functions lookupname, matches, longestmatches, completions
# Check that characters from all 3 tables (BMP, non-BMP, string) are tested

HE = HTML_Entities

@testset "HTML_Entities" begin
@testset "lookupname" begin
    @test HE.lookupname(SubString("My name is Spock", 12)) == ""
    @test HE.lookupname("foobar") == ""
    @test HE.lookupname("nle")    == "\u2270"
    @test HE.lookupname("Pscr")   == "\U1d4ab"
    @test HE.lookupname("lvnE")   == "\u2268\ufe00"
end

@testset "matches" begin
    @test isempty(HE.matches(""))
    @test isempty(HE.matches("\u201f"))
    @test isempty(HE.matches(SubString("This is \u201f", 9)))
    for (chrs, exp) in (("\u2270", ["nle", "nleq"]),
                        ("\U1d4ab", ["Pscr"]),
                        ("\U1d51e", ["afr"]),
                        ("\u2268\ufe00", ["lvertneqq", "lvnE"]))
        res = HE.matches(chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "longestmatches" begin
    @test isempty(HE.longestmatches("\u201f abcd"))
    @test isempty(HE.longestmatches(SubString("This is \U201f abcd", 9)))
    for (chrs, exp) in (("\u2270 abcd", ["nle", "nleq"]),
                        ("\U1d4ab abcd", ["Pscr"]),
                        ("\u2268\ufe00 silly", ["lvertneqq", "lvnE"]))
        res = HE.longestmatches(chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "completions" begin
    @test isempty(HE.completions("ScottPaulJones"))
    @test isempty(HE.completions(SubString("My name is Scott", 12)))
    for (chrs, exp) in (("and", ["and", "andand", "andd", "andslope", "andv"]),
                        ("um", ["umacr", "uml"]))
        res = HE.completions(chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end
end
