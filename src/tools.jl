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


module Tools

using LinearAlgebra

export interp, makevector


interp(x, y, theta) = (1-theta)*x + theta*y



function makevector(T::DataType)
    fnames = fieldnames(T)
    tname = Symbol(split(string(T), '.')[end])
    
    ex = (quote
          # suppose
          #   struct Color
          #     r
          #     g
          #     b
          #   end
          #
          # and we call
          #  eval(makevector(Color))
          #
          # this means *(a, p::Color) = Color(a*p.r, a*p.g, a*p.b)
          Base.:*(a::Number, p::$tname) =  $(Expr(:call, tname, [:(a * p.$fld) for fld in fnames]...))
          Base.:/(p::$tname, a::Number) =  $(Expr(:call, tname, [:(p.$fld / a) for fld in fnames]...))
          
          # unary minus
          Base.:-(p::$tname) =  $(Expr(:call, tname, [:(-p.$fld) for fld in fnames]...))
          
          # this means +(p::Color, q::Color) = Color(p.r + q.r, p.g + q.g, p.b + q.b)
          Base.:+(p::$tname, q::$tname) =  $(Expr(:call, tname, [:(p.$fld + q.$fld) for fld in fnames]...))
          Base.:-(p::$tname, q::$tname) =  $(Expr(:call, tname, [:(p.$fld - q.$fld) for fld in fnames]...))

          # this means convert(::Type{Color}, x) = Color(x)
          Base.convert(::Type{$tname}, x) = $tname(x)
          # this means convert(::Type{Color}, x::Color) = x
          Base.convert(::Type{$tname}, x::$tname) = x

          # this means Color(x::Tuple) = Color(x[1], x[2])
          # but with the correct number of fields
          $tname(x::Tuple) =  $(Expr(:call, tname, [:(x[$i]) for i = 1:length(fnames)]...))
          $tname(x::Vector) =  $(Expr(:call, tname, [:(x[$i]) for i = 1:length(fnames)]...))

          # and others
          Base.:*(p::$tname, a::Number) = a*p
          Base.length(x::$tname) = $(length(fnames))
          LinearAlgebra.dot(p::$tname, q::$tname) =  $(Expr(:call, :+, [:(p.$fld * q.$fld) for fld in fnames]...))
          Base.vec(p::$tname) = $(Expr(:vect, [:(p.$fld) for fld in fnames]...))
          hadamard(p::$tname, q::$tname) =  $(Expr(:call, tname, [:(p.$fld * q.$fld) for fld in fnames]...))
          hadamarddiv(p::$tname, q::$tname) =  $(Expr(:call, tname, [:(p.$fld / q.$fld) for fld in fnames]...))
          LinearAlgebra.normalize(x::$tname) = x/norm(x)
          LinearAlgebra.norm(p::$tname) = sqrt(dot(p,p))

          # LinearAlgebra.norm(p::$tname) = sqrt($(Expr(:call, :+, [:(p.$fld * p.$fld) for fld in fnames]...)))
         end)
end


end

