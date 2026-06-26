structure TrieTests =
struct
  fun run () =
    let
      val t0 = MPT.empty ()
    in
      Harness.section "MPT basic operations";

      Harness.checkBool "lookup empty" (false, Option.isSome (MPT.lookup t0 "key"));

      let
        val t1 = MPT.insert t0 "hello" "world"
      in
        Harness.checkString "lookup after insert" ("world", valOf (MPT.lookup t1 "hello"));
        Harness.checkBool "lookup missing" (false, Option.isSome (MPT.lookup t1 "hell"));

        let
          val t2 = MPT.insert t1 "hell" "yes"
        in
          Harness.checkString "lookup prefix key" ("yes", valOf (MPT.lookup t2 "hell"));
          Harness.checkString "lookup original still there" ("world", valOf (MPT.lookup t2 "hello"));

          let
            val t3 = MPT.delete t2 "hell"
          in
            Harness.checkBool "after delete gone" (false, Option.isSome (MPT.lookup t3 "hell"));
            Harness.checkString "original after delete" ("world", valOf (MPT.lookup t3 "hello"))
          end
        end
      end;

      Harness.section "MPT root changes";
      let
        val ta = MPT.insert t0 "a" "1"
        val tb = MPT.insert t0 "b" "1"
      in
        Harness.check "different keys have different roots" (MPT.root ta <> MPT.root tb)
      end;

      Harness.section "MPT toList";
      let
        val t = MPT.insert (MPT.insert (MPT.insert t0 "c" "3") "a" "1") "b" "2"
        val lst = MPT.toList t
      in
        Harness.checkStringList "toList keys in order"
          (["a", "b", "c"], List.map (fn (k, _) => k) lst)
      end;

      Harness.section "MPT size / isEmpty / member / keys / values / fromList";
      let
        val t = MPT.fromList [("car","1"),("cat","2"),("dog","3"),("do","4")]
      in
        Harness.checkBool "empty isEmpty" (true, MPT.isEmpty t0);
        Harness.checkBool "nonempty not isEmpty" (false, MPT.isEmpty t);
        Harness.checkBool "deleted-all isEmpty"
          (true, MPT.isEmpty (MPT.delete (MPT.insert t0 "x" "1") "x"));
        Harness.checkInt "size 4" (4, MPT.size t);
        Harness.checkInt "size empty" (0, MPT.size t0);
        Harness.checkBool "member present" (true, MPT.member t "cat");
        Harness.checkBool "member prefix-only absent" (true, MPT.member t "do");
        Harness.checkBool "member absent" (false, MPT.member t "ca");
        Harness.checkStringList "keys lexicographic"
          (["car","cat","do","dog"], MPT.keys t);
        Harness.checkStringList "values by key"
          (["1","2","4","3"], MPT.values t);
        Harness.checkInt "fromList later wins"
          (1, case MPT.lookup (MPT.fromList [("k","old"),("k","new")]) "k" of
                SOME "new" => 1 | _ => 0)
      end;

      Harness.section "MPT prefix queries";
      let
        val t = MPT.fromList [("car","1"),("cart","2"),("cat","3"),("dog","4"),("do","5")]
      in
        Harness.checkStringList "withPrefix 'ca' keys"
          (["car","cart","cat"], List.map #1 (MPT.withPrefix t "ca"));
        Harness.checkStringList "withPrefix 'car' includes self"
          (["car","cart"], List.map #1 (MPT.withPrefix t "car"));
        Harness.checkStringList "withPrefix empty = all"
          (["car","cart","cat","do","dog"], List.map #1 (MPT.withPrefix t ""));
        Harness.checkStringList "withPrefix absent = []"
          ([], List.map #1 (MPT.withPrefix t "z"));
        Harness.checkBool "hasPrefix present" (true, MPT.hasPrefix t "ca");
        Harness.checkBool "hasPrefix exact key" (true, MPT.hasPrefix t "cat");
        Harness.checkBool "hasPrefix absent" (false, MPT.hasPrefix t "x");
        Harness.checkBool "hasPrefix partial-but-no-key" (true, MPT.hasPrefix t "c");
        Harness.checkString "longestPrefixMatch 'dogs'"
          ("dog", #1 (valOf (MPT.longestPrefixMatch t "dogs")));
        Harness.checkString "longestPrefixMatch 'doge' value"
          ("4", #2 (valOf (MPT.longestPrefixMatch t "doge")));
        Harness.checkString "longestPrefixMatch prefers shorter 'door'"
          ("do", #1 (valOf (MPT.longestPrefixMatch t "door")));
        Harness.checkBool "longestPrefixMatch none" (true, MPT.longestPrefixMatch t "zzz" = NONE)
      end;

      Harness.section "MPT fold / mapValues / filter / union";
      let
        val t = MPT.fromList [("a","1"),("b","2"),("c","3")]
      in
        Harness.checkString "fold concatenates values in key order"
          ("123", MPT.fold (fn (_, v, acc) => acc ^ v) "" t);
        Harness.checkStringList "mapValues doubles"
          (["11","22","33"], MPT.values (MPT.mapValues (fn v => v ^ v) t));
        Harness.checkStringList "mapValues keeps keys"
          (["a","b","c"], MPT.keys (MPT.mapValues (fn v => v ^ v) t));
        Harness.checkStringList "filter keeps b,c"
          (["b","c"], MPT.keys (MPT.filter (fn (k, _) => k <> "a") t));
        let
          val a = MPT.fromList [("x","ax"),("y","ay")]
          val b = MPT.fromList [("y","by"),("z","bz")]
          val u = MPT.union a b
        in
          Harness.checkStringList "union keys" (["x","y","z"], MPT.keys u);
          Harness.checkString "union left-biased on y" ("ay", valOf (MPT.lookup u "y"));
          Harness.checkString "union takes z from b" ("bz", valOf (MPT.lookup u "z"))
        end
      end;

      Harness.section "MPT rootWith / root determinism";
      let
        val t1 = MPT.fromList [("a","1"),("b","2")]
        val t2 = MPT.fromList [("b","2"),("a","1")]
      in
        Harness.checkBool "root insertion-order independent" (true, MPT.root t1 = MPT.root t2);
        Harness.checkBool "rootWith reflects custom hash"
          (true, MPT.rootWith (fn s => Int.toString (String.size s)) t1
                 = MPT.rootWith (fn s => Int.toString (String.size s)) t2);
        Harness.checkBool "rootWith identity differs by content"
          (true, MPT.rootWith (fn s => s) t1
                 <> MPT.rootWith (fn s => s) (MPT.insert t1 "c" "3"))
      end
    end
end
