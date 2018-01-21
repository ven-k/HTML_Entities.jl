using HTML_Entities

@static VERSION < v"0.7.0-DEV" ? (using Base.Test) : (using Test)

# Test the functions lookupname, matches, longestmatches, completions
# Check that characters from all 3 tables (BMP, non-BMP, string) are tested

HE = HTML_Entities

he_matchchar(ch)       = HE.matchchar(HE.default, ch)
he_lookupname(nam)     = HE.lookupname(HE.default, nam)
he_longestmatches(str) = HE.longestmatches(HE.default, str)
he_matches(str)        = HE.matches(HE.default, str)
he_completions(str)    = HE.completions(HE.default, str)


@testset "HTML_Entities" begin
@testset "lookupname" begin
    @test he_lookupname(SubString("My name is Spock", 12)) == ""
    @test he_lookupname("foobar") == ""
    @test he_lookupname("nle")    == "\u2270"
    @test he_lookupname("Pscr")   == "\U1d4ab"
    @test he_lookupname("lvnE")   == "\u2268\ufe00"
end

@testset "matches" begin
    @test isempty(he_matches(""))
    @test isempty(he_matches("\u201f"))
    @test isempty(he_matches(SubString("This is \u201f", 9)))
    for (chrs, exp) in (("\u2270", ["nle", "nleq"]),
                        ("\U1d4ab", ["Pscr"]),
                        ("\U1d51e", ["afr"]),
                        ("\u2268\ufe00", ["lvertneqq", "lvnE"]))
        res = he_matches(chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "longestmatches" begin
    @test isempty(he_longestmatches("\u201f abcd"))
    @test isempty(he_longestmatches(SubString("This is \U201f abcd", 9)))
    for (chrs, exp) in (("\u2270 abcd", ["nle", "nleq"]),
                        ("\U1d4ab abcd", ["Pscr"]),
                        ("\u2268\ufe00 silly", ["lvertneqq", "lvnE"]))
        res = he_longestmatches(chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "completions" begin
    @test isempty(he_completions("ScottPaulJones"))
    @test isempty(he_completions(SubString("My name is Scott", 12)))
    for (chrs, exp) in (("and", ["and", "andand", "andd", "andslope", "andv"]),
                        ("um", ["umacr", "uml"]))
        res = he_completions(chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end
end
