structure MPT :> MPT =
struct
  datatype trie
    = Empty
    | Node of { value    : string option
              , children : (char * trie) list }

  type t = trie

  fun empty () = Empty

  fun simpleHash (s : string) : string =
    let
      val n = String.size s
      fun go i acc =
        if i >= n then acc
        else go (i + 1) (Word32.+ (Word32.* (acc, 0w31),
                                   Word32.fromInt (Char.ord (String.sub (s, i)))))
      val h = go 0 0w5381
    in
      Word32.toString h
    end

  fun serialize Empty = "E"
    | serialize (Node {value, children}) =
        let
          val vStr = case value of NONE => "N" | SOME v => "V:" ^ v
          val cStr = String.concat
            (List.map (fn (c, t) => String.str c ^ "(" ^ serialize t ^ ")") children)
        in
          "[" ^ vStr ^ cStr ^ "]"
        end

  fun root t = simpleHash (serialize t)
  fun rootWith hash t = hash (serialize t)

  fun updateAssoc key newVal [] = [(key, newVal)]
    | updateAssoc key newVal ((k2, v2) :: rest) =
        if key = k2 then (key, newVal) :: rest
        else if Char.< (key, k2) then (key, newVal) :: (k2, v2) :: rest
        else (k2, v2) :: updateAssoc key newVal rest

  fun insert trie0 key value =
    let
      val klen = String.size key
      fun ins node i =
        if i = klen
        then
          case node of
            Empty => Node {value = SOME value, children = []}
          | Node {children, ...} => Node {value = SOME value, children = children}
        else
          let
            val c = String.sub (key, i)
            val child' = case node of
              Empty => ins Empty (i + 1)
            | Node {children, ...} =>
                case List.find (fn (c2, _) => c = c2) children of
                  NONE => ins Empty (i + 1)
                | SOME (_, ch) => ins ch (i + 1)
            val newChildren = case node of
              Empty => updateAssoc c child' []
            | Node {children, ...} => updateAssoc c child' children
            val oldVal = case node of
              Empty => NONE
            | Node {value = v, ...} => v
          in
            Node {value = oldVal, children = newChildren}
          end
    in
      ins trie0 0
    end

  fun lookup trie0 key =
    let
      val klen = String.size key
      fun look node i =
        if i = klen
        then
          case node of
            Empty => NONE
          | Node {value, ...} => value
        else
          let val c = String.sub (key, i)
          in
            case node of
              Empty => NONE
            | Node {children, ...} =>
                case List.find (fn (c2, _) => c = c2) children of
                  NONE => NONE
                | SOME (_, child) => look child (i + 1)
          end
    in
      look trie0 0
    end

  fun pruneChildren [] = []
    | pruneChildren ((_, Empty) :: rest) = pruneChildren rest
    | pruneChildren ((_, Node {value = NONE, children = []}) :: rest) = pruneChildren rest
    | pruneChildren ((c, ch) :: rest) = (c, ch) :: pruneChildren rest

  fun delete trie0 key =
    let
      val klen = String.size key
      fun del node i =
        if i = klen
        then
          case node of
            Empty => Empty
          | Node {children, ...} =>
              let val pruned = pruneChildren children
              in
                Node {value = NONE, children = pruned}
              end
        else
          let val c = String.sub (key, i)
          in
            case node of
              Empty => Empty
            | Node {value = v, children} =>
                let
                  val newChildren = List.map
                    (fn (c2, ch) => if c = c2 then (c2, del ch (i + 1)) else (c2, ch))
                    children
                  val pruned = pruneChildren newChildren
                in
                  Node {value = v, children = pruned}
                end
          end
    in
      del trie0 0
    end

  fun toList trie0 =
    let
      fun go node prefix =
        case node of
          Empty => []
        | Node {value, children} =>
            let
              val here = case value of
                NONE => []
              | SOME v => [(prefix, v)]
              val below = List.concat
                (List.map (fn (c, ch) => go ch (prefix ^ String.str c)) children)
            in
              here @ below
            end
    in
      go trie0 ""
    end

  fun keys t = List.map #1 (toList t)
  fun values t = List.map #2 (toList t)

  fun member t key = Option.isSome (lookup t key)

  fun isEmpty Empty = true
    | isEmpty (Node {value = SOME _, ...}) = false
    | isEmpty (Node {value = NONE, children}) = List.all (fn (_, ch) => isEmpty ch) children

  fun size t = List.length (toList t)

  fun fold f acc t =
    List.foldl (fn ((k, v), a) => f (k, v, a)) acc (toList t)

  fun fromList kvs =
    List.foldl (fn ((k, v), t) => insert t k v) (empty ()) kvs

  fun mapValues g t =
    fromList (List.map (fn (k, v) => (k, g v)) (toList t))

  fun filter p t =
    fromList (List.filter p (toList t))

  (* left-biased: keys from `a` override keys from `b` *)
  fun union a b =
    let
      val merged = toList b   (* start with b, then overwrite with a *)
      val withA = List.foldl (fn ((k, v), t) => insert t k v)
                    (fromList merged) (toList a)
    in
      withA
    end

  (* Descend to the node reached by following `prefix`; NONE if the path is
     absent from the trie. *)
  fun nodeAt trie0 prefix =
    let
      val plen = String.size prefix
      fun go node i =
        if i = plen then SOME node
        else
          case node of
            Empty => NONE
          | Node {children, ...} =>
              let val c = String.sub (prefix, i) in
                case List.find (fn (c2, _) => c = c2) children of
                  NONE => NONE
                | SOME (_, child) => go child (i + 1)
              end
    in
      go trie0 0
    end

  fun withPrefix t prefix =
    case nodeAt t prefix of
      NONE => []
    | SOME node =>
        let
          fun go n p =
            case n of
              Empty => []
            | Node {value, children} =>
                let
                  val here = case value of NONE => [] | SOME v => [(p, v)]
                  val below = List.concat
                    (List.map (fn (c, ch) => go ch (p ^ String.str c)) children)
                in here @ below end
        in
          go node prefix
        end

  fun hasPrefix t prefix =
    case nodeAt t prefix of
      NONE => false
    | SOME node => not (isEmpty node)

  fun longestPrefixMatch t s =
    let
      val slen = String.size s
      fun go node i best =
        let
          val best' =
            case node of
              Empty => best
            | Node {value = SOME v, ...} => SOME (String.substring (s, 0, i), v)
            | Node {value = NONE, ...} => best
        in
          if i = slen then best'
          else
            case node of
              Empty => best'
            | Node {children, ...} =>
                let val c = String.sub (s, i) in
                  case List.find (fn (c2, _) => c = c2) children of
                    NONE => best'
                  | SOME (_, child) => go child (i + 1) best'
                end
        end
    in
      go t 0 NONE
    end
end
