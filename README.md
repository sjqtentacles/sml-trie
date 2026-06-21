# sml-trie

Merkle Patricia Trie for key-value storage with cryptographic root hashing in pure Standard ML

## Installation

```
smlpkg add github.com/sjqtentacles/sml-trie
smlpkg sync
```

## Usage

```sml
(* Create an empty trie *)
val t0 = MPT.empty ()

(* Insert key-value pairs *)
val t1 = MPT.insert t0 "hello" "world"
val t2 = MPT.insert t1 "hell"  "yes"
val t3 = MPT.insert t2 "help"  "no"

(* Lookup a value — returns SOME v or NONE *)
val SOME "world" = MPT.lookup t3 "hello"
val NONE         = MPT.lookup t3 "missing"

(* Delete a key *)
val t4 = MPT.delete t3 "hell"

(* Cryptographic root hash — changes with every mutation *)
val root1 = MPT.root t2
val root2 = MPT.root t4
(* root1 <> root2 *)

(* Enumerate all key-value pairs *)
val kvs = MPT.toList t3   (* [("hell","yes"), ("hello","world"), ("help","no")] *)
```

## Testing

```
make test       # MLton
make test-poly  # Poly/ML
```

## License

MIT
