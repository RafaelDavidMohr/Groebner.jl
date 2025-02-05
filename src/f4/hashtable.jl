# Monomial hashtable.

# This hashtable implementation assumes that the hash function is linear. (each
# monomial implementation must implement linear hash function)

# The hashtable size is always the power of two. The hashtable size is doubled
# each time the load factor exceeds ht_resize_threshold (see below).
# ht_resize_threshold can be a bit smaller than 0.5, since the number of hits
# greatly exceeds the number of misses usually

# Some monomial implementations are mutable, and some are not. In order to
# maintain generic code that will work for both, we usually write something
# like: m3 = monom_product!(m3, m1, m2). Then, if a mutable implementation is
#   used, m3 would be overwritten inside of monom_product!. Otherwise,
# monom_product! would return a new immutable object that is then assigned to
# m3. That allows us to write more or less independently of the monomial
# implementation.

# Hash of a monomial in the hashtable
# NOTE: Changing the type to one of different size will cause errors in hashing
const MonomHash = UInt32

# Index of a monomial in the hashtable
const MonomIdx = Int32

# Division mask of a monomial
const DivisionMask = UInt32

# Hashvalue of a single monomial
struct Hashvalue
    # index of the monomial in the F4 matrix (defaults to zero),
    idx::Int32
    # hash of the monomial,
    hash::MonomHash
    # corresponding divmask to speed up divisibility checks,
    divmask::DivisionMask
    # total degree of the monomial
    deg::MonomHash
end

# Open addressing, linear scan, hashtable.
mutable struct MonomialHashtable{M <: Monom, Ord <: AbstractInternalOrdering}
    #= Data =#
    monoms::Vector{M}
    # Maps monomial hash to its position in the `monoms` array
    hashtable::Vector{MonomIdx}
    # Stores hashes, division masks, and other valuable info for each hashtable
    # enrty
    hashdata::Vector{Hashvalue}
    # Hash vector. Hash of a monomial is a dot product of the `hasher` vector
    # and the monomial exponent vector
    hasher::Vector{MonomHash}

    #= Ring information =#
    # number of variables
    nvars::Int
    # ring monomial ordering
    ord::Ord

    #= Monom divisibility =#
    use_divmask::Bool
    # Divisor map to check divisibility faster
    divmap::Vector{UInt32}
    ndivvars::Int
    # Number of bits per div variable
    ndivbits::Int

    # Hashtable size (always power of two)
    size::Int
    # Elements currently added
    load::Int
    offset::Int
end

# Resize hashtable if load factor exceeds this ht_resize_threshold. Load factor
# of a hashtable instance must be smaller than ht_resize_threshold at any point
# in its lifetime
ht_resize_threshold() = 0.4
ht_needs_resize(size, load, added) = (load + added) / size > ht_resize_threshold()

function initialize_hashtable(
    ring::PolyRing{Ord},
    rng,
    MonomT::T,
    initial_size
) where {Ord <: AbstractInternalOrdering, T}
    exponents = Vector{MonomT}(undef, initial_size)
    hashdata = Vector{Hashvalue}(undef, initial_size)
    hashtable = zeros(MonomIdx, initial_size)

    nvars = ring.nvars
    ord = ring.ord

    # initialize hashing vector
    hasher = construct_hash_vector(MonomT, nvars)

    # exponents[1:load] cover all stored exponents
    # , also exponents[1] is zeroed by default
    load = 1
    size = initial_size

    # exponents array starts from index offset,
    # We store buffer array at index 1
    offset = 2

    # initialize fast divisibility params
    use_divmask = nvars <= 32
    @log level = -2 "Using division masks: $use_divmask"
    charbit = 8
    int32bits = charbit * sizeof(Int32)
    int32bits != 32 && error("Strange story with Ints")
    ndivbits = div(int32bits, nvars)
    # division mask stores at least 1 bit
    # per each of first ndivvars variables
    ndivbits == 0 && (ndivbits += 1)
    # count only first ndivvars variables for divisibility checks
    ndivvars = nvars < int32bits ? nvars : int32bits
    divmap = Vector{DivisionMask}(undef, ndivvars * ndivbits)

    # first stored exponent used as buffer lately
    exponents[1] = construct_const_monom(MonomT, nvars)

    MonomialHashtable(
        exponents,
        hashtable,
        hashdata,
        hasher,
        nvars,
        ord,
        use_divmask,
        divmap,
        ndivvars,
        ndivbits,
        size,
        load,
        offset
    )
end

function copy_hashtable(ht::MonomialHashtable{M, O}) where {M, O}
    exps = Vector{M}(undef, ht.size)
    table = Vector{MonomIdx}(undef, ht.size)
    data = Vector{Hashvalue}(undef, ht.size)
    exps[1] = construct_const_monom(M, ht.nvars)

    @inbounds for i in 2:(ht.load)
        exps[i] = copy_monom(ht.monoms[i])
        table[i] = ht.hashtable[i]
        data[i] = ht.hashdata[i]
    end

    MonomialHashtable(
        ht.monoms,
        ht.hashtable,
        ht.hashdata,
        ht.hasher,
        ht.nvars,
        ht.ord,
        ht.use_divmask,
        ht.divmap,
        ht.ndivvars,
        ht.ndivbits,
        ht.size,
        ht.load,
        ht.offset
    )
end

# initialize hashtable either for `symbolic_preprocessing` or for `update` functions
# These are of the same purpose and structure as basis hashtable,
# but are more local oriented
function initialize_secondary_hashtable(basis_ht::MonomialHashtable{M}) where {M}
    # 2^6 seems to be the best out of 2^5, 2^6, 2^7
    initial_size = 2^6

    exponents = Vector{M}(undef, initial_size)
    hashdata = Vector{Hashvalue}(undef, initial_size)
    hashtable = zeros(MonomIdx, initial_size)

    # preserve ring info
    nvars = basis_ht.nvars
    ord = basis_ht.ord

    # preserve division info
    divmap = basis_ht.divmap
    ndivbits = basis_ht.ndivbits
    ndivvars = basis_ht.ndivvars

    # preserve hasher
    hasher = basis_ht.hasher

    load = 1
    size = initial_size
    offset = 2

    exponents[1] = construct_const_monom(M, nvars)

    MonomialHashtable(
        exponents,
        hashtable,
        hashdata,
        hasher,
        nvars,
        ord,
        basis_ht.use_divmask,
        divmap,
        ndivvars,
        ndivbits,
        size,
        load,
        offset
    )
end

function select_hashtable_size(ring::PolyRing, monoms)
    nvars = ring.nvars
    sz = length(monoms)

    tablesize = 2^10
    if nvars > 4
        tablesize = 2^14
    end
    if nvars > 7
        tablesize = 2^16
    end

    if sz < 3
        tablesize = div(tablesize, 2)
    end
    if sz < 2
        tablesize = div(tablesize, 2)
    end

    tablesize
end

# Returns the next look-up position in the table 
function next_lookup_index(h::MonomHash, j::MonomHash, mod::MonomHash)
    (h + j) & mod + MonomHash(1)
end

function resize_hashtable_if_needed!(ht::MonomialHashtable, added::Integer)
    newsize = ht.size
    while ht_needs_resize(newsize, ht.load, added)
        newsize *= 2
    end
    if newsize != ht.size
        ht.size = newsize
        @assert ispow2(ht.size)

        resize!(ht.hashdata, ht.size)
        resize!(ht.monoms, ht.size)
        ht.hashtable = zeros(Int, ht.size)

        mod = MonomHash(ht.size - 1)

        for i in (ht.offset):(ht.load)
            # hash for this elem is already computed
            he = ht.hashdata[i].hash
            hidx = he
            @inbounds for j in MonomHash(1):MonomHash(ht.size)
                hidx = next_lookup_index(he, j, mod)
                !iszero(ht.hashtable[hidx]) && continue
                ht.hashtable[hidx] = i
                break
            end
        end
    end
    nothing
end

#------------------------------------------------------------------------------

# if hash collision happened
function ishashcollision(ht::MonomialHashtable, vidx, e, he)
    # if not free and not same hash
    @inbounds if ht.hashdata[vidx].hash != he
        return true
    end
    # if not free and not same monomial
    @inbounds if !is_monom_elementwise_eq(ht.monoms[vidx], e)
        return true
    end
    false
end

function insert_in_hash_table!(ht::MonomialHashtable{M}, e::M) where {M}
    # generate hash
    he = monom_hash(e, ht.hasher)

    # find new elem position in the table
    hidx = MonomHash(he)
    # power of twoooo
    @assert ispow2(ht.size)
    mod = MonomHash(ht.size - 1)
    i = MonomHash(1)
    hsize = MonomHash(ht.size)

    @inbounds while i < hsize
        hidx = next_lookup_index(he, i, mod)

        vidx = ht.hashtable[hidx]

        # if free
        iszero(vidx) && break

        # if not free and not same hash
        if ishashcollision(ht, vidx, e, he)
            i += MonomHash(1)
            continue
        end

        # already present in hashtable
        return vidx
    end

    # add its position to hashtable, and insert exponent to that position
    vidx = MonomIdx(ht.load + 1)
    @inbounds ht.hashtable[hidx] = vidx
    @inbounds ht.monoms[vidx] = copy_monom(e)
    divmask = monom_divmask(e, DivisionMask, ht.ndivvars, ht.divmap, ht.ndivbits)
    @inbounds ht.hashdata[vidx] = Hashvalue(0, he, divmask, totaldeg(e))

    ht.load += 1

    return vidx
end

#------------------------------------------------------------------------------

function is_divmask_divisible(d1::DivisionMask, d2::DivisionMask)
    iszero(~d1 & d2)
end

#=
    Having `ht` filled with monomials from input polys,
    computes ht.divmap and divmask for each of already stored monomials
=#
function fill_divmask!(ht::MonomialHashtable)
    ndivvars = ht.ndivvars

    min_exp = Vector{UInt64}(undef, ndivvars)
    max_exp = Vector{UInt64}(undef, ndivvars)

    e = Vector{UInt64}(undef, ht.nvars)
    monom_to_dense_vector!(e, ht.monoms[ht.offset])

    @inbounds for i in 1:ndivvars
        min_exp[i] = e[i]
        max_exp[i] = e[i]
    end

    @inbounds for i in (ht.offset):(ht.load)
        monom_to_dense_vector!(e, ht.monoms[i])
        for j in 1:ndivvars
            if e[j] > max_exp[j]
                max_exp[j] = e[j]
                continue
            end
            if e[j] < min_exp[j]
                min_exp[j] = e[j]
            end
        end
    end

    ctr = 1
    steps = UInt32(0)
    @inbounds for i in 1:ndivvars
        steps = div(max_exp[i] - min_exp[i], UInt32(ht.ndivbits))
        (iszero(steps)) && (steps += UInt32(1))
        for j in 1:(ht.ndivbits)
            ht.divmap[ctr] = steps
            steps += UInt32(1)
            ctr += 1
        end
    end
    @inbounds for vidx in (ht.offset):(ht.load)
        unmasked = ht.hashdata[vidx]
        e = ht.monoms[vidx]
        divmask = monom_divmask(e, DivisionMask, ht.ndivvars, ht.divmap, ht.ndivbits)
        ht.hashdata[vidx] = Hashvalue(0, unmasked.hash, divmask, totaldeg(e))
    end

    nothing
end

#------------------------------------------------------------------------------

# h1 divisible by h2
function is_monom_divisible(h1::MonomIdx, h2::MonomIdx, ht::MonomialHashtable)
    @inbounds if ht.use_divmask
        if !is_divmask_divisible(ht.hashdata[h1].divmask, ht.hashdata[h2].divmask)
            return false
        end
    end
    @inbounds e1 = ht.monoms[h1]
    @inbounds e2 = ht.monoms[h2]
    is_monom_divisible(e1, e2)
end

# checks that gcd(g1, h2) is one
function is_gcd_const(h1::MonomIdx, h2::MonomIdx, ht::MonomialHashtable)
    @inbounds e1 = ht.monoms[h1]
    @inbounds e2 = ht.monoms[h2]
    is_gcd_const(e1, e2)
end

# computes lcm of he1 and he2 as exponent vectors from ht1
# and inserts it in ht2
function get_lcm(
    he1::MonomIdx,
    he2::MonomIdx,
    ht1::MonomialHashtable{M},
    ht2::MonomialHashtable{M}
) where {M}
    @inbounds e1 = ht1.monoms[he1]
    @inbounds e2 = ht1.monoms[he2]
    @inbounds etmp = ht1.monoms[1]

    etmp = monom_lcm!(etmp, e1, e2)

    insert_in_hash_table!(ht2, etmp)
end

#------------------------------------------------------------------------------

# compare pairwise divisibility of lcms from a[first:last] with lcm
function check_monomial_division_in_update(
    a::Vector{MonomIdx},
    first::Int,
    last::Int,
    lcm::MonomIdx,
    ht::MonomialHashtable{M}
) where {M}

    # pairs are sorted, we only need to check entries above starting point

    @inbounds divmask = ht.hashdata[lcm].divmask
    @inbounds lcmexp = ht.monoms[lcm]

    j = first
    @inbounds while j <= last
        # bad lcm
        if iszero(a[j])
            j += 1
            continue
        end
        # fast division check
        if ht.use_divmask && !is_divmask_divisible(ht.hashdata[a[j]].divmask, divmask)
            j += 1
            continue
        end
        ea = ht.monoms[a[j]]
        if !is_monom_divisible(ea, lcmexp)
            j += 1
            continue
        end
        # mark as redundant
        a[j] = 0
    end

    nothing
end

#------------------------------------------------------------------------------

# add monomials from `poly` multiplied by exponent vector `etmp`
# with hash `htmp` to hashtable `symbol_ht`,
# and substitute hashes in row
function insert_multiplied_poly_in_hash_table!(
    row::Vector{MonomIdx},
    htmp::MonomHash,
    etmp::M,
    poly::Vector{MonomIdx},
    ht::MonomialHashtable{M},
    symbol_ht::MonomialHashtable{M}
) where {M}

    # length of poly to add
    len = length(poly)

    mod = MonomHash(symbol_ht.size - 1)

    bexps = ht.monoms
    bdata = ht.hashdata

    sexps = symbol_ht.monoms
    sdata = symbol_ht.hashdata

    l = 1 # hardcoding 1 does not seem nice =(
    @label Letsgo
    @inbounds while l <= len
        # we iterate over all monoms of the given poly,
        # multiplying them by htmp/etmp,
        # and inserting into symbolic hashtable

        # hash is linear, so that
        # monom_hash(e1 + e2) = monom_hash(e1) + monom_hash(e2)
        # We also assume that the hashing vector is shared same
        # between all created hashtables
        h = htmp + bdata[poly[l]].hash

        e = bexps[poly[l]]

        lastidx = symbol_ht.load + 1
        enew = sexps[1]
        enew = monom_product!(enew, etmp, e)

        # insert into hashtable
        k = h

        i = MonomHash(1)
        ssize = MonomHash(symbol_ht.size)
        @inbounds while i <= ssize
            k = next_lookup_index(h, i, mod)
            vidx = symbol_ht.hashtable[k]

            # if index is free
            iszero(vidx) && break

            if ishashcollision(symbol_ht, vidx, enew, h)
                i += MonomHash(1)
                continue
            end

            # hit
            row[l] = vidx
            l += 1

            @goto Letsgo
        end
        # miss

        # add multiplied exponent to hash table        
        sexps[lastidx] = copy_monom(enew)
        symbol_ht.hashtable[k] = lastidx

        divmask = monom_divmask(
            enew,
            DivisionMask,
            symbol_ht.ndivvars,
            symbol_ht.divmap,
            symbol_ht.ndivbits
        )
        sdata[lastidx] = Hashvalue(0, h, divmask, totaldeg(enew))

        row[l] = lastidx
        l += 1
        symbol_ht.load += 1
    end

    row
end

function multiplied_poly_to_matrix_row!(
    symbolic_ht::MonomialHashtable,
    basis_ht::MonomialHashtable{M},
    htmp::MonomHash,
    etmp::M,
    poly::Vector{MonomIdx}
) where {M}
    row = similar(poly)
    resize_hashtable_if_needed!(symbolic_ht, length(poly))

    insert_multiplied_poly_in_hash_table!(row, htmp, etmp, poly, basis_ht, symbolic_ht)
end
