open Std_internal

module type S = sig
  include Identifiable with type t = private string

  module Stable : sig
    module V1 : sig
      type nonrec t = t with sexp, bin_io, compare

      include Stable_containers.Comparable.V1.S
        with type key := t
        with type comparator_witness := comparator_witness
    end
  end
end

module Make (M : sig val module_name : string end) () = struct
  module Stable = struct
    module V1 = struct
      include String

      let check =
        let invalid s reason =
          Error (sprintf "'%s' is not a valid %s because %s" s M.module_name reason)
        in
        fun s ->
          let len = String.length s in
          if Int.(=) len 0
          then invalid s "it is empty"
          else if Char.is_whitespace s.[0] || Char.is_whitespace s.[len-1]
          then invalid s "it has whitespace on the edge"
          else if String.contains s '|'
          then invalid s "it contains a pipe '|'"
          else Ok ()
      ;;

      let of_string s =
        match check s with
        | Ok () -> s
        | Error err -> invalid_arg err

      let t_of_sexp sexp =
        let s = String.t_of_sexp sexp in
        match check s with
        | Ok () -> s
        | Error err -> of_sexp_error err sexp
    end
  end

  include Stable.V1

end

include Make (struct let module_name = "String_id" end) ()

BENCH_MODULE "String_id" = struct
  BENCH "of_string(AAA)"       = of_string "AAA"
  BENCH "of_string(AAABBB)"    = of_string "AAABBB"
  BENCH "of_string(AAABBBCCC)" = of_string "AAABBBCCC"
end
