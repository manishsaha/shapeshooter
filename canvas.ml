open Dom
open Dom_html
open Format

open Constants
open Js_utils
open Types
open Utils

(* [font] is the font used in drawing text. *)
let font = "Montserrat, sans-serif"

(* [canvas] is the canvas element. *)
let canvas =
  let cvs = getElementById_coerce_exn "canvas" CoerceTo.canvas in
  cvs##.width := int_of_float map_size;
  cvs##.height := int_of_float map_size;
  cvs

(* [context] is the canvas context. *)
let context = canvas##getContext Dom_html._2d_

(* [bits_display] is the bit count element. *)
let bits_display = getElementById "bit-count"

(* [build_cost_display] is the build cost element. *)
let build_cost_display = getElementById "build-cost"

(* [build_button] is the build button. *)
let build_button = getElementById_coerce_exn "build-submit" CoerceTo.input

(* [upgrade_table] is the table of upgrades. *)
let upgrade_table = getElementById "upgrade-table"

(* [create_img] creates an image element from [name]. *)
let create_img name =
  let img = createImg document in
  img##.src := Js.string ("static/img/" ^ name ^ ".png");
  img

(* [images] is a list of preloaded images. *)
let images =
  let names = ["background"; "ui_background"; "player"; "enemy";
               "friendly_bullet"; "enemy_bullet";
               "laser_bullet"; "flamethrower_bullet"; "bit"; "chassis";
               "harvester"; "pistol"; "shotgun"; "machine";
               "flamethrower"; "sniper"; "laser"; "rocket"; "impulse"] in
  List.map (fun name -> (name, create_img name)) names

(* [get_image] gets the image associated with [id]. *)
let get_image id = List.assoc id images

(* [set_text] sets the text of [el] to [s]. *)
let set_text el s = el##.textContent := Js.Opt.return (Js.string s)

(* [set_value] sets the value of [input] to [s]. *)
let set_value input s = input##.value := s

(* [transform_context] translates the context to [x y] and rotates it [phi]. *)
let transform_context x y phi =
  context##translate x y; context##rotate (phi -. pi /. 2.)

(* [draw_rect] draws a rectangle at [x y] with dimensions [w h],
 * line width [lw], stroke color [sc_opt], and fill color [fc_opt]. *)
let draw_rect x y w h lw sc_opt fc_opt =
  context##save;
  (match fc_opt with
   | Some fc ->
     let fc' = Js.string fc in
     context##.fillStyle := fc';
     context##fillRect x y w h
   | None -> ());
  (match sc_opt with
   | Some sc ->
     let sc' = Js.string sc in
     context##.lineWidth := lw;
     context##.strokeStyle := sc';
     context##strokeRect x y w h
   | None -> ());
  context##restore

(* [draw_arc] draws an arc at [x y] with radius [r], line width [lw], start and
 * end angles [sphi ephi], stroke color [sc_opt], and fill color [fc_opt]. *)
let draw_arc x y r lw sphi ephi sc_opt fc_opt =
  context##save;
  context##beginPath;
  context##arc x y r sphi ephi Js._false;
  (match fc_opt with
   | Some fc ->
     let fc' = Js.string fc in
     context##.fillStyle := fc';
     context##fill
   | None -> ());
  (match sc_opt with
   | Some sc ->
     let sc' = Js.string sc in
     context##.lineWidth := lw;
     context##.strokeStyle := sc';
     context##stroke
   | None -> ());
  context##restore

(* [add_text] adds string [s] at [x y] with [size] and optional color [c_opt]. *)
let add_text s x y size c_opt =
  context##save;
  context##.font := Js.string (string_of_int size ^ "px " ^ font);
  (match c_opt with
   | Some c -> context##.fillStyle := Js.string c
   | None -> ());
  context##fillText (Js.string s) x y;
  context##restore

(* [draw_progress_circle] draws a progress circle filled to [percentage]. *)
let draw_progress_circle x y r lw wait_color done_color percentage =
  if percentage = 0.0 then
    draw_arc x y r lw 0. (2. *. pi) done_color None
  else
    draw_arc x y r lw
      (2. *. pi *. (1. -. percentage) -. pi /. 2.)
      (3. /. 2. *. pi) wait_color None

(* [draw_cooldown_circle] draws a progress circle for the provided cooldown. *)
let draw_cooldown_circle x y r lw wait_color done_color (max, cur) =
  draw_progress_circle x y r lw wait_color done_color
    (float_of_int cur /. float_of_int max)

(* [draw_hp_circle] draws a progress circle for the provided health. *)
let draw_hp_circle x y r lw color (max, cur) =
  draw_progress_circle x y r lw
    color None (cur /. max)

(* [draw_progress_horizontal_bar] draws a progress bar filled to [percentage]. *)
let draw_progress_horizontal_bar x y w h wait_color done_color percentage =
  if percentage = 0.0 then
    draw_rect x y w h 0.0 None done_color
  else
    draw_rect x y (w *. percentage) h 0.0 None wait_color

(* [draw_hp_bar] draws a progress bar for the provided health. *)
let draw_hp_bar x y w h lw color (max, cur) =
  draw_rect x y w h lw (Some "#000") (Some "#fff");
  draw_progress_horizontal_bar
    (x +. lw /. 2.) (y +. lw /. 2.) (w -. lw) (h -. lw)
    color None (cur /. max)

(* [draw_bullet] draws a bullet of type [id] at [x y] with angle [phi], radius
 * [size], and friendly status [friendly]. *)
let draw_bullet id x y phi size friendly =
  context##save;
  transform_context x y phi;
  context##drawImage_withSize
    (try get_image (id ^ "_bullet")
     with _ ->
       get_image
         (if friendly then "friendly_bullet" else "enemy_bullet"))
    ~-.size ~-.size (size *. 2.) (size *. 2.);
  context##restore

(* [draw_player] draws a player at the center of the screen with [phi],
 * [size], and [opacity]. *)
let draw_player phi size opacity =
  context##save;
  transform_context half_map_size half_map_size phi;
  context##.globalAlpha := opacity;
  context##drawImage_withSize
    (get_image "player") ~-.size ~-.size (size *. 2.) (size *. 2.);
  context##restore

(* [draw_enemy] draws an enemy at [x y] with angle [phi], [size], and [hp]. *)
let draw_enemy x y phi size hp =
  context##save;
  draw_hp_bar (x -. size *. 0.6) (y +. size *. 1.5) (size *. 1.2)
    4. 1. (Some "#f00") hp;
  transform_context x y phi;
  context##drawImage_withSize (get_image "enemy")
    ~-.size ~-.size (size *. 2.) (size *. 2.);
  context##restore

(* [draw_bitfield] draws a bitfield at [x y] with [bits] and [radius]. *)
let draw_bitfield x y bits radius =
  let draw_bit bx by bphi =
    context##save;
    transform_context bx by bphi;
    context##drawImage_withSize (get_image "bit")
      ~-.bit_size ~-.bit_size (bit_size *. 2.) (bit_size *. 2.);
    context##restore in
  let min = ~-.radius in
  let max = map_size +. radius in
  if x >= min && x <= max && y >= min && y <= max then
    (context##save;
     transform_context x y 0.;
     List.iter (fun ((bx, by), bphi) -> draw_bit bx by bphi) bits;
     context##restore)

(* [draw_chassis] draws a structure chassis at [x y] with [size]. *)
let draw_chassis x y size =
  context##save;
  transform_context x y 0.;
  context##drawImage_withSize (get_image "chassis")
    ~-.size ~-.size (size *. 2.) (size *. 2.);
  context##restore

(* [draw_equip] draws an equip [id] at [x y] with angle [phi]
 * and radius [size]. *)
let draw_equip id x y phi size =
  context##save;
  transform_context x y phi;
  context##drawImage_withSize
    (try get_image id
     with _ -> get_image "pistol")
    ~-.size ~-.size (size *. 2.) (size *. 2.);
  context##restore

(* [draw_structure] draws a structure at [x y]
 * with [phi], [size], [hp], and [equip]. *)
let draw_structure x y phi size hp ({id; cooldown}: equip) =
  draw_hp_circle x y (size +. 5.) 4. (Some "#0f0") hp;
  draw_chassis x y size;
  draw_equip id x y phi (size *. 2.5)

(* [set_upgrades] adds [upgrades] to the available upgrade display. *)
let set_upgrades upgrades bits =
  upgrade_table##.innerHTML := Js.string "";
  List.iter
    (fun {id; cost} ->
       let tr = createTr document in
       tr##.className :=
         Js.string
           (if bits < cost then "upgrade-invalid" else "upgrade-item");
       addEventListener tr Event.mousedown
         (Dom.handler (Input.upgrade id)) Js._true |> ignore;
       let iconTable = createTable document in
       let idDiv = createDiv document in
       idDiv##.className := Js.string "upgrade-id";
       let labelTd = createTd document in
       labelTd##.className := Js.string "upgrade-label-cell";
       let imgTd = createTd document in
       imgTd##.className := Js.string "upgrade-img-cell";
       appendChild labelTd idDiv;
       appendChild labelTd iconTable;
       appendChild imgTd (try get_image id with _ -> get_image "pistol");
       appendChild tr labelTd;
       appendChild tr imgTd;
       appendChild upgrade_table tr;
       set_text idDiv id;
       iconTable##.outerHTML :=
         Js.string
           ("<table class=\"icon-table\"><tr>
               <td><img class=\"icon\" src=\"static/img/bit.png\" /></td>
               <td><div class=\"bit-cost\">" ^ string_of_int cost ^ "</div</td>
             </tr></table>");
       ()
    ) upgrades

(* [draw_current_build] draws the structure currently being built at
 * [x y] with [size], [equip], and validity status [valid]. *)
let draw_current_build x y size (equip: equip) valid =
  context##save;
  context##.globalAlpha := if valid then 0.8 else 0.2;
  draw_chassis x y size;
  draw_equip equip.id x y 0. (size *. 2.5);
  context##restore

(* [game_over] draws the game over screen. *)
let game_over () =
  context##save;
  context##.globalAlpha := 0.5;
  draw_rect 0. 0. map_size map_size 0. None (Some "#f00");
  context##.globalAlpha := 1.0;
  context##rotate (pi *. 0.1);
  add_text "wasted" (half_map_size -. 100.)
    (half_map_size -. 90.) 100 (Some "#000");
  context##restore

(* [draw_ui] draws the UI from the given state. *)
let draw_ui {player = {hp; equip_index; equips; bits; upgrades; stopped};
             build_stats; wave = (wave_number, wave_cd);
             points; mode; mouse = (mx, my); can_interact} =
  let x = equip_ui_size *. 0.75 in
  let y = map_size -. x in
  let equip = equip_at_index equip_index equips in
  add_text (string_of_int points)
    20. 60. 40 (Some "#000");
  draw_progress_horizontal_bar 20. 74. 90. 2.5 (Some "#888") None
    (float_of_int wave_cd /. float_of_int (calc_wave_time wave_number));
  add_text
    (if wave_number = 0 then "Preparation"
     else ("Wave " ^ string_of_int wave_number))
    20. 104. 24 (Some "#000");
  add_text equip.id (x *. 1.8) (y +. 5.) 20 (Some "#000");
  draw_cooldown_circle x y (equip_ui_size *. 0.425) 4.
    (Some "#888")
    (Some (if mode <> Build && can_interact then "#0f0" else "#888"))
    equip.cooldown;
  draw_equip equip.id x y (pi /. (-4.)) equip_ui_size;
  draw_hp_bar half_map_size (y -. 10.) (half_map_size -. x +. 5.)
    20. 4. (Some "#0f0") hp;
  set_text bits_display (string_of_int bits);
  let cost = build_cost build_stats in
  set_text build_cost_display (string_of_int cost);
  build_button##.disabled := Js.bool (bits < cost);
  set_upgrades upgrades bits;
  if mode = Build && (mx, my) <> (-1., -1.) then
    draw_current_build mx my structure_size equip can_interact;
  if mode = Dead then game_over ();
  ()

(* [draw_background] draws the game background, given the coordinates of
 * the map center in the canvas. *)
let draw_background (cx, cy) =
  draw_rect 0. 0. map_size map_size 0. None (Some "#f3f3f3");
  let n = map_size /. background_line_spacing in
  let draw_horizontal y =
    draw_rect 0. (y +. (mod_float cy n)) map_size 1. 0. None (Some "#fff") in
  let draw_vertical x =
    draw_rect (x +. (mod_float cx n)) 0. 1. map_size 0. None (Some "#fff") in
  List.iter (fun d -> draw_horizontal d; draw_vertical d)
    (List.init (int_of_float n) (fun i -> float_of_int i *. n));
  draw_arc cx cy world_size 5. 0. (2. *. pi) (Some "#000") None

let draw_st st =
  let {player = {location = ploc; direction = pphi; hitbox = psize;
                 equip_index; equips; invuln = (_, cur_invuln)};
       enemies; bullets; structures; bitfields} = st in
  context##clearRect 0. 0. map_size map_size;
  draw_background (canvas_xy_of_world ploc origin);
  List.iter
    (fun ({location = floc; bits; radius}) ->
       let (fx, fy) = canvas_xy_of_world ploc floc in
       draw_bitfield fx fy bits radius) bitfields;
  List.iter
    (fun ({location = sloc; direction = sphi;
           hitbox = ssize; hp; equip}: structure) ->
       let (sx, sy) = canvas_xy_of_world ploc sloc in
       draw_structure sx sy sphi ssize hp equip) structures;
  List.iter
    (fun ({location = eloc; direction = ephi;
           hitbox = esize; hp}: enemy) ->
       let (ex, ey) = canvas_xy_of_world ploc eloc in
       draw_enemy ex ey ephi esize hp) enemies;
  List.iter
    (fun ({equip_id = eid; location = bloc; direction = bphi;
           hitbox = bsize; friendly}: bullet) ->
      let (bx, by) = canvas_xy_of_world ploc bloc in
      draw_bullet eid bx by bphi bsize friendly) bullets;
  draw_player pphi psize (if cur_invuln = 0 then 1.0 else 0.5);
  draw_ui st
