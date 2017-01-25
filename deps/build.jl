# License is MIT: https://github.com/JuliaString/LaTeX_Entities/LICENSE.md
#
# Mapping from HTML entities to the corresponding Unicode codepoint.

println("Running HTML entity build in ", pwd())

using StrTables

VER = UInt32(1)

include("htmlnames.jl")

const disp = [false]

const fname = "html.dat"
const datapath = joinpath(Pkg.dir(), "HTML_Entities", "data")

const empty_str = ""

function sortsplit!{T}(index::Vector{UInt16}, vec::Vector{Tuple{T, UInt16}}, base)
    sort!(vec)
    len = length(vec)
    valvec = Vector{T}(len)
    indvec = Vector{UInt16}(len)
    for (i, val) in enumerate(vec)
        valvec[i], ind = val
        indvec[i] = ind
        index[ind] = UInt16(base + i)
    end
    base += len
    valvec, indvec, base
end

function make_tables()
    symnam = Vector{String}()
    symval = Vector{String}()

    for pair in htmlonechar
        push!(symnam, pair[1])
        push!(symval, string(Char(pair[2])))
    end
    for pair in htmlnonbmp
        push!(symnam, pair[1])
        push!(symval, string(Char(0x10000+pair[2])))
    end
    for pair in htmltwochar
        push!(symnam, pair[1])
        p = pair[2]
        push!(symval, string(Char(p[1]), Char(p[2])))
    end

    # We want to build a table of all the names, sort them, then create a StrTable out of them
    srtnam = sortperm(symnam)
    srtval = symval[srtnam] # Values, sorted the same as srtnam

    # BMP characters
    l16 = Vector{Tuple{UInt16, UInt16}}()
    # non-BMP characters (in range 0x10000 - 0x1ffff)
    l32 = Vector{Tuple{UInt16, UInt16}}()
    # two characters packed into UInt32, first character in high 16-bits
    l2c = Vector{Tuple{UInt32, UInt16}}()

    for i in eachindex(srtnam)
        chrs = convert(Vector{Char}, srtval[i])
        length(chrs) > 2 && error("Too long sequence of characters $chrs")
        if length(chrs) == 2
            (chrs[1] > '\uffff' || chrs[2] > '\uffff') &&
                error("Character $(chrs[1]) or $(chrs[2]) > 0xffff")
            push!(l2c, (chrs[1]%UInt32<<16 | chrs[2]%UInt32, i))
        elseif chrs[1] > '\U1ffff'
            error("Character $(chrs[1]) too large: $(UInt32(chrs[1]))")
        elseif chrs[1] > '\uffff'
            push!(l32, ((chrs[1]-0x10000)%UInt32, i))
        else
            push!(l16, (chrs[1]%UInt16, i))
        end
    end

    # We now have 3 vectors, for single BMP characters, for non-BMP characters, and for 2 BMP chars
    # each has the value and a index into the name table
    # We need to create a vector the same size as the name table, that gives the index
    # of into one of the three tables, in order to go from names to 1 or 2 output characters
    # We also need, for each of the 3 tables, a sorted vector that goes from the indices
    # in each table to the index into the name table (so that we can find multiple names for
    # each character)

    indvec = Vector{UInt16}(length(srtnam))
    vec16, ind16, base32 = sortsplit!(indvec, l16, 0)
    vec32, ind32, base2c = sortsplit!(indvec, l32, base32)
    vec2c, ind2c, basefn = sortsplit!(indvec, l2c, base2c)

    (VER, string(now()), "loaded from htmlnames.jl",
     base32%UInt32, base2c%UInt32, StrTable(symnam[srtnam]), indvec,
     vec16, ind16, vec32, ind32, vec2c, ind2c)
end

println("Creating tables")
tup = make_tables()
savfile = joinpath(datapath, fname)
println("Saving tables to ", savfile)
StrTables.save(savfile, tup)
println("Done")
