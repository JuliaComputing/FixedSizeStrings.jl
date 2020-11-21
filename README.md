# SizedStrings.jl

[![Build Status](https://github.com/Luapulu/SizedStrings.jl/workflows/CI/badge.svg)](https://github.com/Luapulu/SizedStrings.jl/workflows/CI/badge.svg)
[![codecov](https://codecov.io/gh/Luapulu/SizedStrings.jl/branch/master/graph/badge.svg?token=9qibx3Mx9Q)](https://codecov.io/gh/Luapulu/SizedStrings.jl)

This packages introduces a string type for storing short strings of
statically-known size compactly. As each character is stored in one byte, only
the Latin-1 subset of Unicode is supported currently.

<!-- TODO: Basic Usage Section -->

SizedStrings work well in the following cases:

- Very short strings, e.g. <= 8 characters
- Storing many strings of the same length, when the number of unique strings is large

If you have a large array with a relatively small number of unique strings, it is
probably better to use `PooledArrays` with whatever string type is convenient.

TODO and open questions:

- Support more characters by adding a parameter for the representation (UInt16, UInt32)
- Does it make sense to support UTF-8?
- Possibly add `MaxSizedString`, which is the same except can be padded with 0 bytes to represent fewer than the maximum possible number of characters.
