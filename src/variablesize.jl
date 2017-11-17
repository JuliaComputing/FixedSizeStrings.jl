"""
Static storage size, variable length strings
"""
struct FixedStorageString{N} # Size is a static type parameter
    length::UInt32
    data::NTuple{N, UInt8} # Immutable statically sized tuple

    FixedStorageString(t::NTuple{N}) where N = new{N}(t)
    function (::Type{FixedStorageString{N}})(v::AbstractArray) where N
        n = lenght(v)
        new{N}(
            n,
            ntuple(Val{N}) do i
                UInt8(ifelse(i <= n, x[i], 0))
            end
        )
    end
    function (::Type{FixedStorageString{N}})(itr) where N
        new{N}(to_0pad_tuple(totuple(NTuple{N,UInt8}, itr, start(itr))))
    end
end

Base.length(x::FixedStorageString) = Int(x.length)

"""
Creates an ntuple, padding it with 0 when iter is done.
"""
@inline function to_0pad_tuple(T, itr, s)
    ET = Base.tuple_type_head(T)
    v = ET(0)
    if !done(itr, s)
        n = next(itr, s)
        v = ET(getfield(n, 1))
        s = getfield(n, 2)
    end
    (v, totuple(Base.tuple_type_tail(T), itr, s)...)
end

@inline to_0pad_tuple(::Type{Tuple{}}, itr, s) = ()


# some constructors
function Base.convert(::Type{FixedString{N}}, x::String) where N
    FixedString
end
Base.convert(::Type{String}, x::FixedString) =
    String([x.data[1:x.length]...])
Base.show(io::IO, x::FixedString) = show(io, String(x))

endof{N}(s::FixedSizeString{N}) = N
next(s::FixedSizeString, i::Int) = (Char(s.data[i]), i+1)
getindex(s::FixedSizeString, i::Int) = Char(s.data[i])
sizeof(s::FixedSizeString) = sizeof(s.data)

convert(::Type{FixedSizeString}, s::AbstractString) = FixedSizeString{length(s)}(s)
convert{N}(::Type{FixedSizeString{N}}, s::AbstractString) = FixedSizeString{N}(s)
convert{N}(::Type{FixedSizeString{N}}, s::FixedSizeString{N}) = s
