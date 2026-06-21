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
      end
    end
end
