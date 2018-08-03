open Dom_html
open Constants
open Js_utils
open Types
open Utils

(* [input_state_internal] is the internal type for inputs. *)
type input_state_internal = {
  mutable keys_pressed: char list;
  mutable keys_held: char list;
  mutable keys_released: char list;
  mutable buttons_pressed: button list;
  mutable buttons_held: button list;
  mutable buttons_released: button list;
  mutable mouse: coords;
  mutable version: int;
  mutable scroll: int * int;
  mutable builder: (int * bool) * build_stats;
  mutable upgrade: string option;
}

(* [inputs] is the internal input state record. *)
let inputs: input_state_internal = {
  keys_pressed = [];
  keys_held = [];
  keys_released = [];
  buttons_pressed = [];
  buttons_held = [];
  buttons_released = [];
  mouse = (-1., -1.);
  scroll = (0, 0);
  version = 0;
  builder = ((0, false), (1, 1));
  upgrade = None;
}

let input_state (): input_state =
  if inputs.version != fst inputs.scroll
  then inputs.scroll <- (0, 0);

  if inputs.version != fst (fst inputs.builder)
  then inputs.builder <- ((0, false), snd inputs.builder);
  
  let state: input_state = {
    keys_pressed = inputs.keys_pressed;
    keys_held = inputs.keys_held;
    keys_released = inputs.keys_released;
    buttons_pressed = inputs.buttons_pressed;
    buttons_held = inputs.buttons_held;
    buttons_released = inputs.buttons_released;
    mouse = inputs.mouse;
    scroll = snd inputs.scroll / scroll_threshold;
    builder = (snd inputs.builder, snd (fst inputs.builder));
    upgrade = inputs.upgrade;
  } in
  
  inputs.keys_pressed <- [];
  inputs.keys_released <- [];
  inputs.buttons_pressed <- [];
  inputs.buttons_released <- [];
  inputs.scroll <- (fst inputs.scroll, snd inputs.scroll mod scroll_threshold);
  inputs.upgrade <- None;
  inputs.version <- inputs.version + 1;
  state
  
(* [canvas] is the canvas element. *)
let canvas = getElementById "canvas"

(* [builder] is the builder menu element. *)
let builder = getElementById "builder"

(* [build_health] is the structure health input field. *)
let build_health = getElementById_coerce_exn "build-health" CoerceTo.input

(* [build_attack] is the structure attack input field. *)
let build_attack = getElementById_coerce_exn "build-attack" CoerceTo.input

(* [keydown] is the key down event handler. *)
let keydown (e: keyboardEvent Js.t) =
  let c = Char.chr e##.keyCode in
  if not (List.mem c inputs.keys_held) then
    (inputs.keys_pressed <- cons_no_dups c inputs.keys_pressed;
     inputs.keys_held <- cons_no_dups c inputs.keys_held);
  Js._true
  
(* [keyup] is the key up event handler. *)
let keyup (e: keyboardEvent Js.t) =
  let c = Char.chr e##.keyCode in
  inputs.keys_held <- List.filter (fun c' -> c <> c') inputs.keys_held;
  inputs.keys_released <- cons_no_dups c inputs.keys_released;
  Js._true

(* [button_of_int] returns the mouse button associated with [i]. *)
let button_of_int i =
  match i with
  | 0 -> Left
  | 1 -> Middle
  | 2 -> Right
  | _ -> raise Not_found

(* [mousedown] is the mouse down event handler. *)
let mousedown (e: mouseEvent Js.t) =
  let b = button_of_int e##.button in
  if not (List.mem b inputs.buttons_held) then
    (inputs.buttons_pressed <- cons_no_dups b inputs.buttons_pressed;
     inputs.buttons_held <- cons_no_dups b inputs.buttons_held);
  Js._false
  
(* [mouseup] is the mouse up event handler. *)
let mouseup (e: mouseEvent Js.t) =
  let b = button_of_int e##.button in
  inputs.buttons_held <- List.filter (fun b' -> b <> b') inputs.buttons_held;
  inputs.buttons_released <- cons_no_dups b inputs.buttons_released;
  Js._false

(* [mousemove] is the mouse move event handler. *)
let mousemove (e: mouseEvent Js.t) =
  let rect = canvas##getBoundingClientRect in
  let x = float_of_int e##.clientX -. rect##.left
  and y = float_of_int e##.clientY -. rect##.top in
  inputs.mouse <- (x, y);
  Js._false

(* [mouseout] is the mouse out event handler. *)
let mouseout (e: mouseEvent Js.t) =
  inputs.mouse <- (-1., -1.);
  Js._false

(* [mousewheel] is the mouse wheel event handler. *)
let mousewheel (e: mousewheelEvent Js.t) =
  inputs.scroll <- (inputs.version, e##.wheelDelta + snd inputs.scroll);
  Js._false

(* [update_cost] updates the current build cost display. *)
let update_cost _ =
  let constrain_value input =
    let value = Js.to_string input##.value in
    input##.value :=
      Js.string (string_of_int
                   (try int_of_string value with _ -> 1)) in
  constrain_value build_health;
  constrain_value build_attack;
  let health = int_of_string (Js.to_string build_health##.value) in
  let attack = int_of_string (Js.to_string build_attack##.value) in
  inputs.builder <- (fst inputs.builder, (health, attack));
  Js._false

let upgrade id e =
  inputs.upgrade <- Some id;
  Js._false

(* [build] is the build button event handler. *)
let build _ =
  let health = int_of_string (Js.to_string build_health##.value) in
  let attack = int_of_string (Js.to_string build_attack##.value) in
  inputs.builder <- ((inputs.version, true), (health, attack));
  canvas##focus;
  Js._false

let _ = [
  addEventListener document Event.keydown (Dom.handler keydown) Js._true;
  addEventListener document Event.keyup (Dom.handler keyup) Js._true;
  addEventListener canvas Event.mousedown (Dom.handler mousedown) Js._true;
  addEventListener canvas Event.mouseup (Dom.handler mouseup) Js._true;
  addEventListener canvas Event.mousemove (Dom.handler mousemove) Js._true;
  addEventListener canvas Event.mouseout (Dom.handler mouseout) Js._true;
  addEventListener canvas Event.mousewheel (Dom.handler mousewheel) Js._true;
  addEventListener builder Event.submit (Dom.handler build) Js._true
]

let _ =
  List.map
    (fun input ->
       addEventListener input Event.change (Dom.handler update_cost) Js._true)
    (Dom.list_of_nodeList
       (document##getElementsByClassName (Js.string "build-input")))
