# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


module Misc

export allowed_kws, ati, getoptions, getoptions_tuple, iffinite, ifnotmissing, setoptions!

ati(x::AbstractArray, i::Int) = x[i]
ati(f::Function, i) = f(i)
ati(f, i) = f


ifnotmissing(x::Missing, y) = y
ifnotmissing(x, y) = x

function iffinite(r::Number, d::Number)
    if isfinite(r)
        return r
    end
    return d
end



##############################################################################
# keyword args

function symsplit(s::Symbol, a::String)
    n = length(a)
    st = string(s)
    if length(st) > n && st[1:length(a)] == a
        return true, Symbol(st[length(a)+1:end])
    end
    return false, :nosuchsymbol
end

function setoptions!(d, prefix, kwargs...)
    for (key, value) in kwargs
        match, tail = symsplit(key, prefix)
        if match && tail in fieldnames(typeof(d))
            setfield!(d, tail, value)
        end
    end
end

# For a type T defined using @kwdef, this function returns the fieldnames
# which can be sent as kw arguments to its constructor
# So you can call 
#
#  T(; allowed_kws(T, kw)...)
#
# when kw is supplied from the kwargs of a function call
#
allowed_kws(T, kw) = Dict(a => kw[a] for a in keys(kw) if a in fieldnames(T))

getoptions_tuple(; kw...) = kwtuple(kw)
kwtuple(opts) = NamedTuple{keys(opts)}(values(opts))
getoptions(; kw...) = kw








end


