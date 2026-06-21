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

  (* Return all (key, value) pairs in lexicographic key order *)
  val toList : t -> (string * string) list
end
