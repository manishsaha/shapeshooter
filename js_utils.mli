open Dom_html

(* [getElementById_coerce_exn id coercer] returns the element with [id],
 * coerced with [coercer].
 * raises: Not_found if no such element exists *)
val getElementById_coerce_exn: string -> (element Js.t -> 'a Js.opt) -> 'a

(* [debug s] prints [s] to the developer console. *)
val debug: string -> unit
