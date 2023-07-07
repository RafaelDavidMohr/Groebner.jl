
"""
    groebner(polynomials; options...)

Computes a Groebner basis of the ideal generated by array `polynomials`.

## Possible Options
TODO(alex): default values are not clear.

The `groebner` routine takes the following options:
- `reduced`: If the returned basis must be reduced and unique *(default)*.
- `ordering`: Specifies the monomial ordering. Available monomial orderings are: 
    - `InputOrdering()` for inferring the ordering from the given `polynomials`
      *(default)*, 
    - `Lex()` for lexicographic, 
    - `DegLex()` for degree lexicographic, 
    - `DegRevLex()` for degree reverse lexicographic, 
    - `WeightedOrdering(weights)` for weighted ordering, 
    - `BlockOrdering(args...)` for block ordering, 
    - `MatrixOrdering(matrix)` for matrix ordering. 
  For details and examples see the corresponding documentation page.
- `certify`: Certify the obtained basis. When this option is `false`, the
    algorithm is randomized, and the result is correct with high probability
    *(default)*.
- `linalg`: Linear algebra backend. Available options are: `:exact` for
    deterministic sparse linear algebra, `:prob` for probabilistic sparse linear
    algebra *(default)*.
- `monoms`: Monomial representation used during the computations. The algorithm
    automatically tries to choose the best monomial representation. Otherwise,
    one can set `monoms` to one of the following: 
    - `default_monom_representation()`, 
    - `NotPacked{<:Unsigned}`, e.g., `NotPacked{UInt32}()`, for not packed
      representation with `32` bits per exponent, 
    - `Packed{<:Unsigned}`, e.g., `Packed{UInt8}()`, for packed representation
      with `8` bits per exponent.
- `seed`: The seed for randomization. Default value is `42`.
    Random number generator is 
- `loglevel`: Logging level. Default value is `Logging.Warn`, 
    so that only warnings are produced.
- `maxpairs`: The maximum number of critical pairs used at once in matrix 
    construction. By default, this is not specified. 
    Tweak this option to lower the amount of RAM consumed.

## Basic Example

Using `DynamicPolynomials`:

```jldoctest
using Groebner, DynamicPolynomials
@polyvar x y;
groebner([x*y^2 + x, y*x^2 + y])
```

Using `AbstractAlgebra`:

```jldoctest
using Groebner, AbstractAlgebra
R, (x, y) = QQ["x", "y"]
groebner([x*y^2 + x, y*x^2 + y])
```

"""
function groebner(polynomials::AbstractVector; kws...)
    # `KeywordsHandler` does several useful things on initialization:
    #   - checks that the keyword arguments are valid,
    #   - sets the global logging level for this module.
    _groebner(polynomials, KeywordsHandler(:groebner, kws))
end

# returns a graph
function groebner_learn(polynomials::AbstractVector; kws...)
    _groebner_learn(polynomials, KeywordsHandler(:groebner_learn, kws))
end

# returns a basis
function groebner_apply(graph, polynomials::AbstractVector; kws...)
    _groebner_apply(graph, polynomials, KeywordsHandler(:groebner_apply, kws))
end

"""
    isgroebner(polynomials; options...)

Checks if array `polynomials` forms a Groebner basis.

## Possible Options

The `isgroebner` routine takes the following options:
- `ordering`: Specifies the monomial ordering. Available monomial orderings are: 
    - `InputOrdering()` for inferring the ordering from the given `polynomials`
      *(default)*, 
    - `Lex()` for lexicographic, 
    - `DegLex()` for degree lexicographic, 
    - `DegRevLex()` for degree reverse lexicographic, 
    - `WeightedOrdering(weights)` for weighted ordering, 
    - `BlockOrdering(args...)` for block ordering, 
    - `MatrixOrdering(matrix)` for matrix ordering. 
  For details and examples see the corresponding documentation page.
- `certify`: Certify the obtained basis. When this option is `false`, the
  algorithm is randomized, and the result is correct with high probability
  *(default)*.
- `seed`: The seed for randomization. Default value is `42`.
- `loglevel`: Logging level. Default value is `Logging.Warn`, 
    so that only warnings are produced.

## Basic Example

Using `DynamicPolynomials`:

```jldoctest
using Groebner, DynamicPolynomials
@polyvar x y;
isgroebner([x*y^2 + x, y*x^2 + y])
```

Using `AbstractAlgebra`:

```jldoctest
using Groebner, AbstractAlgebra
R, (x, y) = QQ["x", "y"]
isgroebner([x*y^2 + x, y*x^2 + y])
```

"""
function isgroebner(polynomials::AbstractVector; kws...)
    _isgroebner(polynomials, KeywordsHandler(:isgroebner, kws))
end

"""
    normalform(basis, tobereduced; options...)

Computes the normal form of polynomials `tobereduced` w.r.t `basis`.
`tobereduced` can be either a single polynomial or an array of polynomials.

## Possible Options

The `isgroebner` routine takes the following options:
- `ordering`: Specifies the monomial ordering. Available monomial orderings are: 
    - `InputOrdering()` for inferring the ordering from the given `polynomials`
      *(default)*, 
    - `Lex()` for lexicographic, 
    - `DegLex()` for degree lexicographic, 
    - `DegRevLex()` for degree reverse lexicographic, 
    - `WeightedOrdering(weights)` for weighted ordering, 
    - `BlockOrdering(args...)` for block ordering, 
    - `MatrixOrdering(matrix)` for matrix ordering. 
  For details and examples see the corresponding documentation page.
- `certify`: Certify the obtained basis. When this option is `false`, the
  algorithm is randomized, and the result is correct with high probability
  *(default)*.
- `rng`: Random number generator object (must be `<: Random.AbstractRNG`) 
    used in the computations. 
    Default RNG is `Random.Xoshiro(42)`.
- `loglevel`: Logging level. Default value is `Logging.Warn`, 
    so that only warnings are produced.

## Basic Example

Using `DynamicPolynomials`:

```jldoctest
using Groebner, DynamicPolynomials
@polyvar x y;
isgroebner([x*y^2 + x, y*x^2 + y])
```

Using `AbstractAlgebra`:

```jldoctest
using Groebner, AbstractAlgebra
R, (x, y) = QQ["x", "y"]
isgroebner([x*y^2 + x, y*x^2 + y])

The `basis` is assumed to be a Groebner basis.
If `check=true`, we use randomized algorithm to quickly check 
if `basis` is indeed a Groebner basis (default).

Uses the ordering on `basis` by default.
If `ordering` is explicitly specified, it takes precedence.

# Example

```jldoctest
julia> using Groebner, DynamicPolynomials
julia> @polyvar x y;
julia> normalform([y^2 + x, x^2 + y], x^2 + y^2 + 1)
```

"""
function normalform(basis::AbstractVector, tobereduced; kws...)
    _normalform(basis, tobereduced, KeywordsHandler(:normalform, kws))
end

"""
    kbase(basis; options...)

Computes the basis of polynomial ring modulo the zero-dimensional ideal
generated by `basis` as a basis of vector space.

The `basis` is assumed to be a Groebner basis.
If `check=true`, we use randomized algorithm to quickly check 
if `basis` is indeed a Groebner basis (default).

# Example

```jldoctest
julia> using Groebner, DynamicPolynomials
julia> @polyvar x y;
julia> kbase([y^2 + x, x^2 + y], check=true)
```

"""
function kbase(basis::AbstractVector; kws...) 
    _kbase(basis, KeywordsHandler(:kbase, kws))
end
