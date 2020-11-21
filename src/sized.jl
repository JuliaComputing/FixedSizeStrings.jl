## Construction

_szerr(N::Integer, sz::Integer) = throw(ArgumentError(
    "cannot construct a SizedString{$N} from a $sz byte input"))

const UIntOrChar = Union{Unsigned, AbstractChar}

struct SizedString{N} <: AbstractString
    data::NTuple{N,UInt8}

    SizedString{N}(t::NTuple{M,UIntOrChar}) where {N, M} = N == M ? new{N}(t) : _szerr(N, M)
    function SizedString{N}(s::String) where {N}
        N == sizeof(s) ? new{N}(NTuple{N,UInt8}(s)) : _szerr(N, sizeof(s))
    end
end

SizedString{N}(cs::UIntOrChar...) where {N, M} = SizedString{N}(cs)
SizedString{N}(v::Vector{<:UIntOrChar}) where {N} = SizedString{N}(v...)
SizedString{N}(fs::SizedString{N}) where {N} = fs

# Fallback
SizedString{N}(s) where {N} = SizedString{N}(String(s))

macro sized_str(s)
    :(SizedString{length($(esc(s)))}($(esc(s))))
end

## AbstractString Implementation

ncodeunits(s::SizedString{N}) where {N} = N

sizeof(s::SizedString) = sizeof(s.data)

length(s::SizedString) = ncodeunits(s)
length(S::Type{SizedString{N}}) where {N} = N

lastindex(s::SizedString{N}) where {N} = N

function iterate(s::SizedString{N}, i::Int = 1) where {N}
    i > N && return nothing
    return Char(s.data[i]), i+1
end

codeunit(::SizedString) = UInt8
@propagate_inbounds codeunit(s::SizedString, i::Integer) = s.data[i]
@propagate_inbounds getindex(s::SizedString, i::Integer)::Char = s.data[i]

isvalid(s::SizedString, i::Integer) = checkbounds(Bool, s, i)


## IO

function read(io::IO, T::Type{SizedString{N}}) where N
    return read!(io, Ref{T}())[]::T
end

function write(io::IO, s::SizedString{N}) where N
    return write(io, Ref(s))
end
