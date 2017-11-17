"""
Fixed size string type.
"""
immutable FixedSizeString{N} <: AbstractFixedSizeString{N}
    data::NTuple{N,UInt8}
    FixedSizeString(t::NTuple{N}) = new(t)
    FixedSizeString(itr) = new(totuple(NTuple{N,UInt8}, itr, start(itr)))
end
length(s::FixedSizeString{N}) = N
convert(::Type{FixedSizeString}, s::AbstractString) = FixedSizeString{length(s)}(s)

function read{N}(io::IO, T::Type{AbstractFixedSizeString{N}})
    temp = Ref{FixedSizeString{N}}()
    Base.unsafe_read(io, convert(Ptr{UInt8}, Base.unsafe_convert(Ptr{Void}, temp)), N)
    return temp[]
end

function write{N}(io::IO, s::AbstractFixedSizeString{N})
    Base.unsafe_write(io, convert(Ptr{UInt8}, pointer_from_objref(s)), N)
end
