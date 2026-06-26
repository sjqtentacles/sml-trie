# sml-trie

A purely functional **Merkle-Patricia Trie** (radix trie keyed by bytes, with a
hash-based root digest) for string-to-string key/value storage in pure Standard
ML. Every operation is persistent: `insert`/`delete`/`mapValues`/... return a
new trie and never mutate their argument.

It is a genuine per-character trie — each edge is labelled by one byte — so it
supports fast prefix queries (autocomplete, longest-prefix routing) alongside
the usual map operations, plus a deterministic `root` digest that summarizes
the whole structure for cheap equality and tamper-evidence.

No dependencies, no FFI, no clock, no randomness: identical results under
**MLton** and **Poly/ML**.

## Installation

```
smlpkg add github.com/sjqtentacles/sml-trie
smlpkg sync
```

## API

```sml
structure MPT : sig
  type t

  val empty  : unit -> t
  val insert : t -> string -> string -> t
  val lookup : t -> string -> string option
  val delete : t -> string -> t

  (* root digest *)
  val root     : t -> string                       (* built-in hash *)
  val rootWith : (string -> string) -> t -> string (* caller's hash *)

  (* membership / cardinality *)
  val isEmpty : t -> bool
  val member  : t -> string -> bool
  val size    : t -> int

  (* conversions *)
  val fromList : (string * string) list -> t        (* later duplicates win *)
  val toList   : t -> (string * string) list        (* lexicographic *)
  val keys     : t -> string list
  val values   : t -> string list

  (* prefix queries *)
  val withPrefix         : t -> string -> (string * string) list
  val hasPrefix          : t -> string -> bool
  val longestPrefixMatch : t -> string -> (string * string) option

  (* traversal / transformation *)
  val fold      : (string * string * 'a -> 'a) -> 'a -> t -> 'a
  val mapValues : (string -> string) -> t -> t
  val filter    : (string * string -> bool) -> t -> t
  val union     : t -> t -> t                        (* left-biased *)
end
```

## Usage

```sml
(* Create an empty trie *)
val t0 = MPT.empty ()

(* Insert key-value pairs (or build from a list) *)
val t  = MPT.fromList [("hello","world"), ("hell","yes"), ("help","no")]

(* Lookup a value — returns SOME v or NONE *)
val SOME "world" = MPT.lookup t "hello"
val NONE         = MPT.lookup t "missing"

(* Prefix queries: autocomplete and longest-prefix routing *)
val ["hell","hello","help"] = List.map #1 (MPT.withPrefix t "hel")
val true                    = MPT.hasPrefix t "he"
val SOME ("hell","yes")     = MPT.longestPrefixMatch t "hellscape"

(* Map / filter / fold over bindings in key order *)
val shouted = MPT.mapValues (fn v => v ^ "!") t
val onlyH   = MPT.filter (fn (k,_) => String.isPrefix "hel" k) t
val joined  = MPT.fold (fn (k,v,acc) => acc ^ k ^ "=" ^ v ^ ";") "" t

(* Left-biased union (values from the FIRST trie win on conflict) *)
val merged = MPT.union t (MPT.fromList [("hello","other"),("hey","hi")])
val SOME "world" = MPT.lookup merged "hello"   (* kept from t *)

(* Deterministic root digest — insertion-order independent, changes on edit *)
val true = MPT.root (MPT.fromList [("a","1"),("b","2")])
         = MPT.root (MPT.fromList [("b","2"),("a","1")])
val custom = MPT.rootWith (fn s => Int.toString (String.size s)) t
```

## How it works

A trie node carries an optional value plus a sorted child list keyed by the
next byte. `insert`/`lookup`/`delete` walk one byte of the key per level;
because children are kept in byte order, `toList`/`keys`/`values` come out in
lexicographic order for free, and a prefix query just descends to the node for
the prefix and enumerates the subtree below it. `root` serializes the structure
(value markers + child bytes) and hashes the serialization with a built-in
DJB-style 32-bit hash; `rootWith` lets you supply your own (e.g. a real
cryptographic hash). The digest is a pure function of the set of bindings, so
it is insertion-order independent and changes whenever any binding changes.

## Scope and limitations

- Keys and values are `string` (arbitrary bytes are fine).
- The trie is **not** path-compressed: each edge is a single byte, so deep
  sparse keys allocate one node per character. A radix/compressed layout would
  shrink memory but change the serialized form and therefore every `root`
  digest, so it is intentionally left as future work.
- `root` uses a non-cryptographic hash by default; pass a cryptographic hash to
  `rootWith` if you need collision resistance.

## Testing

```
make test       # MLton
make test-poly  # Poly/ML
make all-tests  # both
```

42 deterministic checks cover insert/lookup/delete, `size`/`isEmpty`/`member`,
`keys`/`values`/`fromList`, the prefix queries, `fold`/`mapValues`/`filter`,
left-biased `union`, and `root`/`rootWith` determinism.

## License

MIT
