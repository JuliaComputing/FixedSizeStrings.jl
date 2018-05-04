__precompile__()

module FixedSizeStrings

export FixedSizeString

struct FixedSizeString{N} <: AbstractString
    data::NTuple{N, UInt8} # Immutable statically sized tuple
    len::Int64 # in bytes
end

# creation

function Base.String(ps::FixedSizeString)
    unsafe_string(convert(Ptr{UInt8}, pointer_from_objref(ps)), ps.len)
end

Base.convert(::Type{FixedSizeString}, x::String) = convert(FixedSizeString{x.len}, x)
Base.convert(::Type{FixedSizeString}, x::FixedSizeString) = x    
function Base.convert(::Type{FixedSizeString{N}}, x::String) where N
    x_ptr = pointer(x)
    FixedSizeString{N}(
        ntuple(Val{N}) do i
            UInt8(i <= x.len ? unsafe_load(x_ptr, i) : 0)
        end,
        x.len
    )
end

function Base.convert(::Type{FixedSizeString{N}}, x::FixedSizeString{M}) where {N, M}
    @assert N >= M
    FixedSizeString{N}(
        ntuple(Val{N}) do i
            i <= x.len ? x.data[i] : 0
        end,
        x.len
    )
end

Base.promote_rule(::Type{FixedSizeString{N}}, ::Type{FixedSizeString{N}}) where N = FixedSizeString{N}
Base.promote_rule(::Type{FixedSizeString{N}}, ::Type{FixedSizeString{M}}) where {N,M} = FixedSizeString{max(M,N)}

# string interface - this is largely copied from Base and will almost certainly break when we move to 0.7

Base.sizeof(s::FixedSizeString) = s.len

@inline function Base.codeunit(s::FixedSizeString, i::Integer)
    @boundscheck if (i < 1) | (i > s.len)
        throw(BoundsError(s,i))
    end
    s.data[i]
end

function Base.read(io::IO, T::Type{FixedSizeString{N}}) where {N}
    FixedSizeString{N}(
        ntuple(Val{N}) do i
            read(io, UInt8)
        end,
        N
    )
end

function Base.write(io::IO, s::FixedSizeString)
    s_ptr = convert(Ptr{UInt8}, pointer_from_objref(s))
    Base.unsafe_write(io, s_ptr, reinterpret(UInt, s.len))
end

function Base.cmp(a::FixedSizeString, b::FixedSizeString)
    c = ccall(:memcmp, Int32, (Ptr{UInt8}, Ptr{UInt8}, UInt),
              a, b, min(a.len,b.len))
    return c < 0 ? -1 : c > 0 ? +1 : cmp(a.len,b.len)
end

function Base.:(==)(a::FixedSizeString, b::FixedSizeString)
    a.len == b.len && 0 == ccall(:memcmp, Int32, (Ptr{UInt8}, Ptr{UInt8}, UInt), a, b, a.len)
end

function Base.prevind(s::FixedSizeString, i::Integer)
    j = Int(i)
    e = s.len
    if j > e
        return endof(s)
    end
    j -= 1
    @inbounds while j > 0 && Base.is_valid_continuation(codeunit(s,j))
        j -= 1
    end
    j
end

function Base.nextind(s::FixedSizeString, i::Integer)
    j = Int(i)
    if j < 1
        return 1
    end
    e = s.len
    j += 1
    @inbounds while j <= e && Base.is_valid_continuation(codeunit(s,j))
        j += 1
    end
    j
end

Base.byte_string_classify(s::FixedSizeString) =
    ccall(:u8_isvalid, Int32, (Ptr{UInt8}, Int), s, s.len)

Base.isvalid(::Type{FixedSizeString}, s::FixedSizeString) = byte_string_classify(s) != 0
Base.isvalid(s::FixedSizeString) = isvalid(FixedSizeString, s)

function Base.endof(s::FixedSizeString)
    p = s.data
    i = s.len
    while i > 0 && Base.is_valid_continuation(p[i])
        i -= 1
    end
    i
end

function Base.length(s::FixedSizeString)
    p = s.data
    cnum = 0
    for i = 1:s.len
        cnum += !Base.is_valid_continuation(p[i])
    end
    cnum
end

Base.done(s::FixedSizeString, state) = state > s.len
@inline function Base.next(s::FixedSizeString, i::Int)
    @boundscheck if (i < 1) | (i > s.len)
        throw(BoundsError(s,i))
    end
    p = s.data
    b = p[i]
    if b < 0x80
        return Char(b), i + 1
    end
    s_ptr = convert(Ptr{UInt8}, pointer_from_objref(s))
    return Base.slow_utf8_next(s_ptr, b, i, s.len)
end

function Base.reverseind(s::FixedSizeString, i::Integer)
    j = s.len + 1 - i
    p = s.data
    while Base.is_valid_continuation(p[j])
        j -= 1
    end
    return j
end

Base.isvalid(s::FixedSizeString, i::Integer) =
    (1 <= i <= s.len) && !Base.is_valid_continuation(s.data[i])

end
