module FixedSizeStrings

@doc """
Nicer syntax for splicing lists:

    quote
        \$(@splice i in is quote
            stuff_with(\$i)
        end)
    end

Equivalent to:

    quote
        \$([:(stuff_with(\$i)) for i in is]...)
    end
"""
macro splice(iterator, body)
  @assert iterator.head == :call
  @assert iterator.args[1] == :in
  Expr(:..., :(($(esc(body)) for $(esc(iterator.args[2])) in $(esc(iterator.args[3])))))
end


const DEFAULT_STRING_LEN = 100

struct FixedSizeString{N} <: AbstractString
    data::NTuple{N, UInt8} # Immutable statically sized tuple
    len::Int64 # in bytes
end

FixedSizeString{N}(x::FixedSizeString) where N = convert(FixedSizeString{N}, x)

# creation

@inline Base.String(ps::FixedSizeString) = String(UInt8[ps.data[1:ps.len]...])

# string interface - this is largely copied from Base and will almost certainly break when we move to 0.7

Base.ncodeunits(s::FixedSizeString) = s.len
Base.sizeof(s::FixedSizeString) = s.len

@inline Base.codeunit(s::FixedSizeString) = UInt8

@inline function Base.codeunit(s::FixedSizeString, i::Integer)
    @boundscheck if (i < 1) | (i > s.len)
        throw(BoundsError(s,i))
    end
    s.data[i]
end

@generated function Base.read(io::IO, T::Type{FixedSizeString{N}}) where {N}
    quote
        $(Expr(:meta, :inline))
        FixedSizeString{$N}(
            $(Expr(:new, NTuple{N,UInt8}, @splice i in 1:N quote
                read(io, UInt8)
            end)),
            N
        )
    end
end

function Base.write(io::IO, s::FixedSizeString)
    counter = 1
    @inbounds while counter <= s.len
        Base.write(io, s.data[counter])
        counter += 1
    end
end

@generated function Base.cmp(a::FixedSizeString{M}, b::FixedSizeString{N}) where {M, N}
    quote
        $(Expr(:block, (:(
            if a.len < $i
                return b.len < $i ? 0 : -1
            elseif b.len < $i
                return +1
            elseif a.data[$i] < b.data[$i]
                return -1
            elseif a.data[$i] > b.data[$i]
                return +1
            end
        ) for i = 1:min(M, N)+1)...,))
    end
end

function Base.:(==)(a::FixedSizeString, b::FixedSizeString)
    return Base.cmp(a, b) == 0
end

function Base.prevind(s::FixedSizeString, i::Int64)
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

function Base.nextind(s::FixedSizeString, i::Int64)
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

function Base.lastindex(s::FixedSizeString)
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

function Base.reverse(s::FixedSizeString)
     sprint(sizehint=sizeof(s)) do io
         i, j = firstindex(s), lastindex(s)
         while i ≤ j
             c, j = s[j], prevind(s, j)
             write(io, c)
         end
     end
 end

@inline function Base.iterate(s::FixedSizeString, i::Int64=1)
    if i > s.len
        nothing
    else
        @boundscheck if (i < 1) | (i > s.len)
            throw(BoundsError(s,i))
        end
        p = s.data
        b = p[i]
        if b < 0x80
            return Char(b), i + 1
        end

        return iterate(String(s), i)
    end
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

# To limit the total number of different `FixedSizeString{N}` types we compile for, 
# we try to stick to capacities `N` that are powers of 2,
# similar to the way we limit integer types: `Int16, Int32, Int64 ...`
discretize(size::Int) = 2 ^ (Int(ceil(log(2, max(size, 1)))))
FixedSizeString(x::Union{String, SubString}) = FixedSizeString{discretize(sizeof(x))}(x)
@generated function FixedSizeString{N}(x::SubString{FixedSizeString{M}}) where {N, M}
    quote
        $(Expr(:meta, :inline))
        x_len = sizeof(x)
        FixedSizeString{$N}(
            $(Expr(:new, NTuple{N,UInt8}, @splice i in 1:N quote
                UInt8($i <= x_len ? x.string.data[$i + x.offset] : 0)
            end)),
            x_len
        )
    end
end
@generated function FixedSizeString{N}(x::String) where N
    quote
        $(Expr(:meta, :inline))
        x_ptr = pointer(x)
        x_len = sizeof(x)
        @assert N >= x_len
        FixedSizeString{$N}(
            $(Expr(:new, NTuple{N,UInt8}, @splice i in 1:N quote
                UInt8($i <= x_len ? unsafe_load(x_ptr, $i) : 0)
            end)),
            x_len
        )
    end
end

Base.convert(::Type{FixedSizeString}, x::String) = FixedSizeString(x)
Base.convert(::Type{FixedSizeString}, x::FixedSizeString) = x
Base.convert(::Type{FixedSizeString{N}}, x::String) where N = FixedSizeString{N}(x)

@inline Base.convert(::Type{FixedSizeString{N}}, x::FixedSizeString{N}) where {N} = x
@generated function Base.convert(::Type{FixedSizeString{N}}, x::FixedSizeString{M}) where {N, M}
    @assert N >= M
    quote
        $(Expr(:meta, :inline))
        x_len = x.len
        FixedSizeString{$N}(
            $(Expr(:new, NTuple{N,UInt8}, @splice i in 1:N quote
                UInt8($i <= x_len ? x.data[$i] : 0)
            end)),
            x_len
        )
    end
end

@generated function Base.zero(::Type{T}) where {N, T <: FixedSizeString{N}}
    empty_val = FixedSizeString{N}(NTuple{N,UInt8}(UInt8(0) for i in 1:N), 0)
    quote
        $(Expr(:meta, :inline))
        $empty_val
    end
end

Base.promote_rule(::Type{FixedSizeString{N}}, ::Type{FixedSizeString{N}}) where N = FixedSizeString{N}
Base.promote_rule(::Type{FixedSizeString{N}}, ::Type{FixedSizeString{M}}) where {N,M} = FixedSizeString{max(M,N)}


@inline Base.typemin(::Type{FixedSizeString{N}}) where {N} = FixedSizeString{N}(typemin(String))

@generated function Base.typemax(::Type{FixedSizeString{N}}) where {N}
    quote
        $(Expr(:meta, :inline))
        FixedSizeString{$N}(
            $(Expr(:new, NTuple{N,UInt8}, @splice i in 1:N quote
                typemax(UInt8)
            end)),
            $N
        )
    end
end

@inline Base.zero(::Type{FixedSizeString}) = FixedSizeString(zero(String))

const TestString = FixedSizeString{DEFAULT_STRING_LEN}

export FixedSizeString, DEFAULT_STRING_LEN

end
