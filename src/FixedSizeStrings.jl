module FixedSizeStrings

export FixedSizeString

import Base: endof, next, getindex, sizeof, convert

immutable FixedSizeString{N} <: DirectIndexString
    data::NTuple{N,UInt8}
    FixedSizeString(t::NTuple{N}) = new(t)
    FixedSizeString(itr) = new(totuple(NTuple{N,UInt8}, itr, start(itr)))
end

@inline function totuple(T, itr, s)
    done(itr, s) && error("too few values")
    n = next(itr, s)
    v = getfield(n, 1)
    s = getfield(n, 2)
    (convert(Base.tuple_type_head(T), v), totuple(Base.tuple_type_tail(T), itr, s)...)
end

@inline totuple(::Type{Tuple{}}, itr, s) = ()

endof{N}(s::FixedSizeString{N}) = N
next(s::FixedSizeString, i::Int) = (Char(s.data[i]), i+1)
getindex(s::FixedSizeString, i::Int) = Char(s.data[i])
sizeof(s::FixedSizeString) = sizeof(s.data)

convert(::Type{FixedSizeString}, s::AbstractString) = FixedSizeString{length(s)}(s)
convert{N}(::Type{FixedSizeString{N}}, s::AbstractString) = FixedSizeString{N}(s)

end
