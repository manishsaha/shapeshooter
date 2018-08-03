open Dom_html

let getElementById_coerce_exn id coercer =
  match getElementById_coerce id coercer with
  | None -> raise Not_found
  | Some el -> el

let debug s = Firebug.console##log (Js.string s)
