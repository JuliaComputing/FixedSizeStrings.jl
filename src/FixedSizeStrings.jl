module FixedSizeStrings

export FixedSizeString

import Base: endof, next, getindex, sizeof, convert, read, write

struct FixedSizeString{N} <: DirectIndexString
    data::NTuple{N,UInt8}
    FixedSizeString{N}(itr) where {N} = new(totuple(NTuple{N,UInt8}, itr, start(itr)))
end

FixedSizeString(t::NTuple{N}) where {N} = FixedSizeString{N}(t)
FixedSizeString(itr) = FixedSizeString{length(itr)}(itr)

@inline function totuple(T, itr, s)
    done(itr, s) && error("too few values")
    n = next(itr, s)
    v = getfield(n, 1)
    s = getfield(n, 2)
    (convert(Base.tuple_type_head(T), v), totuple(Base.tuple_type_tail(T), itr, s)...)
end

@inline totuple(::Type{Tuple{}}, itr, s) = ()

endof(s::FixedSizeString{N}) where {N} = N
next(s::FixedSizeString, i::Int) = (Char(s.data[i]), i+1)
getindex(s::FixedSizeString, i::Int) = Char(s.data[i])
sizeof(s::FixedSizeString) = sizeof(s.data)

convert(::Type{FixedSizeString}, s::AbstractString) = FixedSizeString{length(s)}(s)
convert(::Type{FixedSizeString{N}}, s::AbstractString) where {N} = FixedSizeString{N}(s)
convert(::Type{FixedSizeString{N}}, s::FixedSizeString{N}) where {N} = s

function read(io::IO, T::Type{FixedSizeString{N}}) where N
    temp = Ref{FixedSizeString{N}}()
    Base.unsafe_read(io, convert(Ptr{UInt8}, Base.unsafe_convert(Ptr{Void}, temp)), N)
    return temp[]
end

function write(io::IO, s::FixedSizeString{N}) where N
    Base.unsafe_write(io, convert(Ptr{UInt8}, pointer_from_objref(s)), N)
end

end
