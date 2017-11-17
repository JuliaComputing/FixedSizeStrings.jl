abstract type AbstractFixedSizeString{N} <: DirectIndexString end


@inline function totuple(T, itr, s)
    done(itr, s) && error("too few values")
    n = next(itr, s)
    v = getfield(n, 1)
    s = getfield(n, 2)
    (convert(Base.tuple_type_head(T), v), totuple(Base.tuple_type_tail(T), itr, s)...)
end

@inline totuple(::Type{Tuple{}}, itr, s) = ()

endof{N}(s::FixedSizeString{N}) = length(s)
next(s::FixedSizeString, i::Int) = (Char(s.data[i]), i+1)
getindex(s::FixedSizeString, i::Int) = Char(s.data[i])
sizeof(s::FixedSizeString) = sizeof(s.data)

function convert{N}(::Type{T}, s::AbstractString) where T <: AbstractFixedSizeString{N}
    T(s)
end
convert{N}(::Type{T}, s::T) where T <: AbstractFixedSizeString{N} = s

function Base.:(==)(a::AbstractFixedSizeString, b::AbstractFixedSizeString)
    length(a) == length(b) || return false
    for i in 1:length(a)
        a.data[i] == b.data[i] || return false
    end
    return true
end
