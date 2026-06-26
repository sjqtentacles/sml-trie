signature MPT =
sig
  (* A minimal Merkle-Patricia Trie (purely functional radix trie with
     a hash-based root digest). Keys and values are strings. *)
  type t

  val empty  : unit -> t
  val insert : t -> string -> string -> t
  val lookup : t -> string -> string option
  val delete : t -> string -> t
  val root   : t -> string   (* hash digest of serialized root *)
  (* Like `root` but with a caller-supplied hash function over the serialized
     form (the built-in `root` uses an internal FNV/DJB-style hash). *)
  val rootWith : (string -> string) -> t -> string

  (* Membership / cardinality. *)
  val isEmpty : t -> bool
  val member  : t -> string -> bool
  val size    : t -> int      (* number of bound keys; O(n) *)

  (* Build a trie from an association list (later duplicates win). *)
  val fromList : (string * string) list -> t
  (* Return all (key, value) pairs in lexicographic key order. *)
  val toList : t -> (string * string) list
  val keys   : t -> string list      (* lexicographic *)
  val values : t -> string list      (* by lexicographic key *)

  (* Prefix queries. *)
  (* All (key, value) pairs whose key begins with the given prefix, in
     lexicographic order (the prefix itself is included if bound). *)
  val withPrefix : t -> string -> (string * string) list
  (* True if any bound key begins with the prefix. *)
  val hasPrefix  : t -> string -> bool
  (* The longest bound key that is a prefix of the query string, with its
     value (NONE if no bound key is a prefix of it). *)
  val longestPrefixMatch : t -> string -> (string * string) option

  (* Whole-trie traversal / transformation (lexicographic key order). *)
  val fold      : (string * string * 'a -> 'a) -> 'a -> t -> 'a
  val mapValues : (string -> string) -> t -> t
  val filter    : (string * string -> bool) -> t -> t
  (* Left-biased union: on a key present in both, the value from the FIRST
     trie wins. *)
  val union     : t -> t -> t
end
