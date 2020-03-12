module FixedSizeStrings

export FixedSizeString, FixedSizeString16, FixedSizeString32

import Base: iterate, lastindex, getindex, sizeof, length, ncodeunits, codeunit, isvalid, read, write

struct FixedSizeStringGeneric{N,T} <: AbstractString
    data::NTuple{N,T}
    FixedSizeStringGeneric{N,T}(itr) where {N,T} = new(NTuple{N,T}(itr))
end

const FixedSizeString{N} = FixedSizeStringGeneric{N,UInt8} where N
const FixedSizeString16{N} = FixedSizeStringGeneric{N,UInt16} where N
const FixedSizeString32{N} = FixedSizeStringGeneric{N,UInt32} where N

FixedSizeString(s::AbstractString) = FixedSizeString{length(s)}(s)
FixedSizeString16(s::AbstractString) = FixedSizeString16{length(s)}(s)
FixedSizeString32(s::AbstractString) = FixedSizeString32{length(s)}(s)

function iterate(s::FixedSizeStringGeneric{N}, i::Int = 1) where N
    i > N && return nothing
    return (Char(s.data[i]), i+1)
end

lastindex(s::FixedSizeStringGeneric{N}) where {N} = N

getindex(s::FixedSizeStringGeneric, i::Int) = Char(s.data[i])

sizeof(s::FixedSizeStringGeneric) = sizeof(s.data)

length(s::FixedSizeStringGeneric) = length(s.data)

ncodeunits(s::FixedSizeStringGeneric) = length(s.data)

codeunit(::FixedSizeStringGeneric{<:Any,T}) where T = T
codeunit(s::FixedSizeStringGeneric, i::Integer) = s.data[i]

isvalid(s::FixedSizeString, i::Int) = checkbounds(Bool, s, i)
isvalid(s::FixedSizeStringGeneric, i::Int) = checkbounds(Bool, s, i) && isvalid(Char,s.data[i])

function read(io::IO, T::Type{<:FixedSizeStringGeneric{N}}) where N
    return read!(io, Ref{T}())[]::T
end

function write(io::IO, s::FixedSizeStringGeneric{N}) where N
    return write(io, Ref(s))
end

end
