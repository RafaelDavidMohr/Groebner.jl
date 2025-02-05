module Groebner
# Groebner is a package for computing Gröbner bases. This is the main file.

# Groebner works over integers modulo a prime and over the rationals. At its
# heart Groebner implements F4 and modular techniques.

"""
    invariants_enabled() -> Bool

Specifies if custom asserts and invariants are checked.
If `false`, then all checks are disabled, and entail no runtime overhead.

See also `@invariant` in `src/utils/invariants.jl`.
"""
invariants_enabled() = true

"""
    logging_enabled() -> Bool

Specifies if custom logging is enabled.
If `false`, then all logging is disabled, and entails no runtime overhead.

See also `@log` in `src/utils/logging.jl`.
"""
logging_enabled() = true

# Groebner does not provide a polynomial implementation of its own but relies on
# existing symbolic computation packages in Julia for communicating with the
# user instead. Groebner accepts as its input polynomials from the Julia
# packages AbstractAlgebra.jl (Oscar.jl) and MultivariatePolynomials.jl. This
# list can be extended; see `src/input-output/` for details.
import AbstractAlgebra
import AbstractAlgebra: base_ring, elem_type

import Base: *
import Base.Threads: Atomic, threadid, atomic_xchg!
import Base.MultiplicativeInverses: UnsignedMultiplicativeInverse

import Combinatorics

using ExprTools

using Logging

import MultivariatePolynomials
import MultivariatePolynomials: AbstractPolynomial, AbstractPolynomialLike

import Primes
import Primes: nextprime

import Random

using SIMD

include("utils/logging.jl")
include("utils/invariants.jl")
include("utils/performance.jl")

# Minimalistic plotting with Unicode
include("utils/plots.jl")

# Test systems, such as katsura, cyclic, etc
include("utils/test_systems.jl")

# Monomial orderings.
# The file orderings.jl is the interface for communicating with the user, and
# the file internal-orderings.jl actually implements monomial orderings
include("monomials/orderings.jl")
include("monomials/internal-orderings.jl")

include("utils/keywords.jl")

# Monomial implementations
include("monomials/common.jl")
include("monomials/exponentvector.jl")
include("monomials/packedutils.jl")
include("monomials/packedtuples.jl")
include("monomials/sparsevector.jl")

# Defines some type aliases for Groebner
include("utils/types.jl")

# Fast arithmetic modulo a prime
include("arithmetic/Zp.jl")
# Not so fast arithmetic in the rationals
include("arithmetic/QQ.jl")

# Selecting algorithm parameters
include("groebner/parameters.jl")

# Input-output conversions for polynomials
include("input-output/input-output.jl")
include("input-output/AbstractAlgebra.jl")
include("input-output/DynamicPolynomials.jl")

#= generic f4 implementation =#
#= the heart of this library =#
# `MonomialHashtable` implementation
include("f4/hashtable.jl")
# `Pairset` and `Basis` implementations
include("f4/basis.jl")
# Computation graph for F4 (tracing)
include("f4/graph.jl")
# `MacaulayMatrix` implementation
include("f4/matrix.jl")
include("f4/sorting.jl")
# Some very shallow tracing
include("f4/tracer.jl")
# All together combined in the F4 algorithm
include("f4/f4.jl")
include("f4/learn-apply.jl")

#= more high level functions =#
# Lucky prime numbers
include("groebner/lucky.jl")
# Rational number reconstruction and CRT reconstruction
include("groebner/reconstruction.jl")
# GB state
include("groebner/state.jl")
# Correctness checks
include("groebner/correctness.jl")
# `groebner` backend
include("groebner/groebner.jl")
# `groebner_learn` and `groebner_apply` backend
include("groebner/learn-apply.jl")
# `isgroebner` backend
include("groebner/isgroebner.jl")
# `normalform` backend
include("groebner/normalform.jl")
# `autoreduce` backend (not exported)
include("groebner/autoreduce.jl")
# some tricks (which are used to compute in Lex and Block orderings)
include("groebner/homogenization.jl")

#= generic fglm implementation =#
include("fglm/linear.jl")
include("fglm/fglm.jl")

# API
include("interface.jl")

using SnoopPrecompile
include("precompile.jl")

export groebner, groebner_learn, groebner_apply!
export isgroebner
export normalform

export kbase

export Lex,
    DegLex, DegRevLex, InputOrdering, WeightedOrdering, ProductOrdering, MatrixOrdering

@doc read(joinpath(dirname(@__DIR__), "README.md"), String) Groebner

# 라헬
end # module Groebner
