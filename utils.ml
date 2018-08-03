open Constants
open Types

let get_enemy entity =
  match entity with
  | Enemy e -> e
  | _ -> failwith "Not an enemy"

let get_player entity =
  match entity with
  | Player p -> p
  | _ -> failwith "Not a player"

let get_struct entity =
  match entity with
  | Structure s -> s
  | _ -> failwith "Not a structure"

let get_bullet entity =
  match entity with
  | Bullet b -> b
  | _ -> failwith "Not a bullet"

let get_id entity =
  match entity with
  | Enemy e -> e.id
  | Player p -> -1
  | Structure s -> -1
  | Bullet b -> -1

let get_hp entity =
  match entity with
  | Enemy e -> snd e.hp
  | Player p -> snd p.hp
  | Structure s  -> snd s.hp
  | Bullet _ -> failwith "No bullet hp field"

let set_hp hp entity =
  let hp = max 0. hp in
  match entity with
  | Enemy e -> Enemy {e with hp = (fst e.hp, hp)}
  | Player p -> Player {p with hp = (fst p.hp, hp)}
  | Structure s -> Structure {s with hp = (fst s.hp, hp)}
  | Bullet _ -> failwith "No bullet hp field"

let get_hitbox entity =
  match entity with
  | Enemy e -> e.hitbox
  | Player p -> p.hitbox
  | Structure s -> s.hitbox
  | Bullet b -> b.hitbox

let get_loc entity =
  match entity with
  | Enemy e -> e.location
  | Player p -> p.location
  | Structure s -> s.location
  | Bullet b -> b.location

let set_loc loc entity =
  match entity with
  | Enemy e -> Enemy {e with location = loc}
  | Player p -> Player {p with location = loc}
  | Structure s -> Structure {s with location = loc}
  | Bullet b -> Bullet {b with location = loc}

let get_invuln entity =
  match entity with
  | Enemy _ -> (0, 0)
  | Player p -> p.invuln
  | Structure s -> s.invuln
  | Bullet _ -> failwith "No bullet invulnerability"

let set_invuln invuln entity =
  match entity with
  | Enemy e -> Enemy e
  | Player p -> Player {p with invuln = invuln}
  | Structure s -> Structure {s with invuln = invuln}
  | Bullet _ -> failwith "No bullet invulnerability"

let get_some opt1 opt2 = if opt1 <> None then opt1 else opt2

let calc_wave_time n = wave_time + (n - 1) * wave_buffer

let pos_mod a b = let r = a mod b in if r < 0 then r + b else r

let pos_mod_float a b = let r = mod_float a b in if r < 0. then r +. b else r

let eq_coords (x1, y1) (x2, y2) =
  abs_float (x1 -. x2) < epsilon && abs_float (y1 -. y2) < epsilon

let distance (x1, y1) (x2, y2) = sqrt ((x2 -. x1) ** 2. +. (y2 -. y1) ** 2.)

let magnitude (x, y) = distance (0., 0.) (x, y)

let direction (x, y) = atan2 y x

let add (x1, y1) (x2, y2) = (x1 +. x2, y1 +. y2)

let subtract (x1, y1) (x2, y2) = (x1 -. x2, y1 -. y2)

let dot (x1, y1) (x2, y2) = x1 *. x2 +. y1 *. y2

let scale (x, y) mag = (x *. mag, y *. mag)

let normalize v = scale v (if magnitude v = 0. then 0. else 1. /. magnitude v)

let set_mag v mag = scale (normalize v) mag

let rotate (x, y) phi = (x *. cos phi -. y *. sin phi,
                         x *. sin phi +. y *. cos phi)

let xy_of_rphi r phi = (r *. cos phi, r *. sin phi)

let check_bounds location hitbox =
  distance location origin < (world_size -. hitbox)

let canvas_xy_of_world (px, py) (wx, wy) =
  (wx -. px +. half_map_size, wy -. py +. half_map_size)

let world_xy_of_canvas (px, py) (cx, cy) =
  (cx -. half_map_size +. px, cy -. half_map_size +. py)

let is_coll loc1 loc2 r1 r2 = distance loc1 loc2 < r1 +. r2

let cons_no_dups x xs = if not (List.mem x xs) then x :: xs else xs

let fold_rev f xs init = List.fold_left (fun acc x -> f x acc) init xs

let find_index pred xs =
  List.fold_left
    (fun (acc, i) x -> ((if acc < 0 && pred x then i else acc), i + 1))
    (-1, 0) xs |> fst

let equip_of_id eid equips = List.find (fun ({id}: equip) -> id = eid) equips

let upgrade_of_id uid upgrades = List.find (fun ({id}: upgrade) -> id = uid) upgrades

let equip_at_index i equips = List.nth equips i

let equip_id_at_index i equips = ((equip_at_index i equips): equip).id

let index_of_equip_id eid equips =
  find_index (fun ({id}: equip) -> id = eid) equips

let update_equip new_equip player =
  let equips =
    (List.fold_left
       (fun (acc, i) eq ->
          ((if i = player.equip_index then new_equip else eq) :: acc, i + 1))
       ([], 0) player.equips) |> fst |> List.rev in
  {player with equips = equips}

let equip_ids_of_equips equips = List.map (fun ({id}: equip) -> id) equips

let possible_upgrades equips =
  let current = equip_ids_of_equips equips in
  List.filter
    (fun {id; requires} ->
       not (List.mem id current)
       && List.for_all (fun id -> List.mem id current) requires)
    default_upgrades

let get_equip entity =
  match entity with
  | Enemy e -> e.equip
  | Player p -> Some (equip_at_index p.equip_index p.equips)
  | Structure s -> Some s.equip
  | Bullet _ -> failwith "No bullet equip field"

let set_equip equip_opt entity =
  match entity with
  | Enemy e -> Enemy {e with equip = equip_opt}
  | Player p ->
    (match equip_opt with
    | None -> Player p
    | Some equip ->
      Player {p with equip_index = (index_of_equip_id equip.id p.equips)})
  | Structure s ->
    (match equip_opt with
    | None -> Structure s
    | Some equip -> Structure {s with equip = equip})
  | Bullet _ -> failwith "No bullet equip field"

let enemy_of_species species =
  let rec e_of_sp enems =
    match enems with
    | [] -> failwith "Invalid enemy id"
    | h::t -> if h.species = species then h else e_of_sp t in
  e_of_sp default_enemies

let check_bitfields loc bitfields =
  let in_bitfield loc bitfield =
    let {location = floc; radius = r} = bitfield in
    let distance = distance loc floc in
    distance < r in
  let rec checkall_bitfields loc bitfields =
    match bitfields with
    | [] -> false
    | h::t -> begin
        if in_bitfield loc h then true
        else checkall_bitfields loc t
      end in
  checkall_bitfields loc bitfields

let build_cost (health, attack) =
  10 * health + 100 * attack
