open Ai
open Constants
open Types
open Utils

(* [gen_spawn_loc ploc] is the location of a newly created enemy relative
 * to the player location [ploc]. *)
let rec gen_spawn_loc ploc =
  let r = Random.float world_size in
  let phi = Random.float (2. *. pi) in
  let (x, y) = xy_of_rphi r phi in
  if distance (x, y) ploc <= sqrt 2. *. map_size
  then gen_spawn_loc ploc else (x, y)

(* [spawn_enemies i ploc e n] creates [n] enemies of species [e] with increasing
 * id from [i]. *)
let rec spawn_enemies i ploc (enemy: enemy) n =
  if n = 0 then []
  else {enemy with id = i; location = gen_spawn_loc ploc}::
       (spawn_enemies (i + 1) ploc enemy (n - 1))

(* [generate_bits r] is the list of bits in the specified radius [r]. *)
let generate_bits r =
  let spacing = 10. in
  let iterations = r /. spacing |> int_of_float in
  List.map
    (fun r' ->
       List.init (int_of_float (r' ** 1.15 /. 5.))
         (fun _ ->
            (xy_of_rphi r' (Random.float 2. *. pi), Random.float 2. *. pi)))
    (List.init iterations (fun i -> (float_of_int i) *. spacing))
  |> List.concat

(* [generate_bitfields ()] is the list of bitfields to be placed on the map. *)
let generate_bitfields () =
  let basic_field = {
    location = (0., 0.);
    radius = 75.;
    bits = generate_bits 75.;
  } in
  let spacing = map_size in
  let iterations = world_size /. spacing |> int_of_float in
  let bitfields_in_radius r =
    let sectors = (int_of_float r / 150) in
    let divisions = float_of_int (360 / sectors) in
    let angles_of_sectors = List.init (sectors)
        (fun i -> float_of_int (i + 1) *. divisions) in
    let angles =
      List.map (fun phi -> Random.float divisions +. phi) angles_of_sectors in
    let bitfields =
      List.map (fun phi ->
          let location = xy_of_rphi r phi in
          let r' = Random.float 75. +. 75. in
          {location = if check_bounds location r' then xy_of_rphi r phi
             else xy_of_rphi (r -. r') phi;
           radius = r';
           bits = generate_bits r';}) angles in
    bitfields in
  let rec make_all r i acc =
    if i = iterations then acc
    else make_all (r +. spacing) (i + 1) (bitfields_in_radius r @ acc) in
  basic_field :: make_all spacing 0 []

(* [gen_structure h a loc equip] is a structure at [loc] whose stats are based
 * off of health [h] and attack [a], with [equip]. *)
let gen_structure health attack coords (equip: equip) =
  let hp = float_of_int health *. 20. in
  let cooldown =
    if equip.id = "harvester" then (fst equip.cooldown) * 3
    else fst equip.cooldown in
  {
    hp = (hp, hp);
    location = coords;
    direction = 0.;
    attack = float_of_int attack *. 3.;
    equip = {equip with cooldown = (cooldown, 0)};
    invuln = (dmg_invuln, 0);
    hitbox = structure_size;
  }

let initial_state () = {
  player = {default_player with
            upgrades = possible_upgrades default_player.equips};
  enemies = [];
  bullets = [];
  structures = [];
  bitfields = generate_bitfields ();
  wave = (0, wave_buffer * 4);
  points = 0;
  enemies_spawned = 0;
  mode = Normal;
  mouse = (-1., -1.);
  can_interact = false;
  build_stats = (1, 1);
}

(* [advance_passive st] is the state after weapon cooldowns and invulnerability
 * have advanced one frame. *)
let advance_passive st =
  let player = st.player in
  let (per, cool) = player.invuln in
  let player = if cool <> 0 then {player with invuln = (per, max (cool - 1) 0)}
    else player in
  if snd player.hp > 0. then
    let new_equips =
      List.map (fun eq -> {eq with cooldown = (fst eq.cooldown,
                                               max (snd eq.cooldown - 1) 0)})
        player.equips in
    let new_player = {player with equips = new_equips} in
    {st with player = new_player}
  else {st with mode = Dead}

let advance_move dir st =
  let {player; bullets; structures} = st in
  let {location = ploc; speed; hitbox} = player in
  let v = set_mag dir speed in
  let (v, _) = check_struct_colls (Player player) v structures in
  let v = check_enemy_colls (Player player) v st.enemies in
  let player = {player with location = add ploc v} in
  if check_bounds player.location hitbox
  then {st with player = player; bullets = bullets}
  else st

(* [check_stopped acts st] is true if the player is moving; false otherwise. *)
let check_stopped acts st =
  let rec check_dirs acts =
    match acts with
    | [] -> true
    | h::t -> begin
        match h with
        | Move dir when dir <> origin -> false
        | _ -> check_dirs t
      end in
  let player = st.player in
  {st with player = {player with stopped = check_dirs acts}}

(* [choose_wave st] creates an enemy wave based on the current wave number. *)
let choose_wave st =
  let (n, _) = st.wave and i = st.enemies_spawned in
  let ploc = st.player.location in
  if n <= 5
  then (spawn_enemies i ploc
          ({(enemy_of_species "weak")
            with hp = (float_of_int n, float_of_int n)})
          (3 * n), i + 5 * n)
  else let wave_index = Random.int (List.length default_waves) in
    match List.nth default_waves wave_index with
    | "swarm" ->
      let (h_seek, i) =
        let num = n / 5 in
        (spawn_enemies i ploc (enemy_of_species "h_seeker") num, i + num) in
      let (p_seek, i) =
        let num = 2 * n in
        (spawn_enemies i ploc (enemy_of_species "p_seeker") num, i + num) in
      let (shotgun, i) =
        let num = n in
        (spawn_enemies i ploc (enemy_of_species "shotgun") num, i + num) in
      let (rush, i) =
        let num = n / 5 * 2 in
        (spawn_enemies i ploc (enemy_of_species "rush") num, i + num) in
      (h_seek @ p_seek @ shotgun @ rush, i)
    | "tank" ->
      let (tank, i) =
        let num = n / 3 in
        (spawn_enemies i ploc (enemy_of_species "tank") num, i + num) in
      let (t_tank, i) =
        let num = n / 5 in
        (spawn_enemies i ploc (enemy_of_species "t_tank") num, i + num) in
      let (p_tank, i) =
        let num = n / 4 in
        (spawn_enemies i ploc (enemy_of_species "p_tank") num, i + num) in
      (tank @ t_tank @ p_tank, i)
    | "close" ->
      let (shotgun, i) =
        let num = n in
        (spawn_enemies i ploc (enemy_of_species "shotgun") num, i + num) in
      let (flame, i) =
        let num = n / 2 in
        (spawn_enemies i ploc (enemy_of_species "flame") num, i + num) in
      let (p_mid, i) =
        let num = n / 3 in
        (spawn_enemies i ploc (enemy_of_species "p_mid") num, i + num) in
      let (p_seek, i) =
        let num = n / 3 * 2 in
        (spawn_enemies i ploc (enemy_of_species "p_seeker") num, i + num) in
      (shotgun @ flame @ p_mid @ p_seek, i)
    | "mid" ->
      let (p_mid, i) =
        let num = n in
        (spawn_enemies i ploc (enemy_of_species "p_mid") num, i + num) in
      let (t_mid, i) =
        let num = n / 3 in
        (spawn_enemies i ploc (enemy_of_species "t_mid") num, i + num) in
      let (p_seek, i) =
        let num = n / 2 in
        (spawn_enemies i ploc (enemy_of_species "p_seeker") num, i + num) in
      let (shotgun, i) =
        let num = n / 2 in
        (spawn_enemies i ploc (enemy_of_species "shotgun") num, i + num) in
      (p_mid @ t_mid @ p_seek @ shotgun, i)
    | "far" ->
      let (sniper, i) =
        let num = n / 4 * 3 in
        (spawn_enemies i ploc (enemy_of_species "sniper") num, i + num) in
      let (rocket, i) =
        let num = n / 3 in
        (spawn_enemies i ploc (enemy_of_species "rocket") num, i + num) in
      let (p_mid, i) =
        let num = n / 2 in
        (spawn_enemies i ploc (enemy_of_species "p_mid") num, i + num) in
      let (t_mid, i) =
        let num = n / 5 in
        (spawn_enemies i ploc (enemy_of_species "t_mid") num, i + num) in
      (sniper @ rocket @ p_mid @ t_mid, i)
    | "turret" ->
      let (h_seek, i) =
        let num = n / 5 * 2 in
        (spawn_enemies i ploc (enemy_of_species "h_seeker") num, i + num) in
      let (t_tank, i) =
        let num = n / 3 in
        (spawn_enemies i ploc (enemy_of_species "t_tank") num, i + num) in
      let (t_mid, i) =
        let num = n / 3 in
        (spawn_enemies i ploc (enemy_of_species "t_mid") num, i + num) in
      let (shotgun, i) =
        let num = n / 2 in
        (spawn_enemies i ploc (enemy_of_species "shotgun") num, i + num) in
      (h_seek @ t_tank @ t_mid @ shotgun, i)
    | _ -> (st.enemies, i)

(* [advance_wave st] is the state after the wave timer has decreased 1 frame
 * and enemies have been spawned if the timer is at 0. *)
let advance_wave st =
  let (num, cooldown) = st.wave in
  if cooldown <> 0 then {st with wave = (num, cooldown - 1)}
  else let st = {st with wave = (num + 1, calc_wave_time (num + 1))} in
    let (enems, i) = choose_wave st in
    {st with enemies = st.enemies @ enems;
             enemies_spawned = i + st.enemies_spawned;}

let advance_enemies st =
  let step_enemy st' (enemy: enemy) =
    match entity_passive (Enemy enemy) with
    | None -> {st' with points = st'.points + fst st'.wave * 5}
    | Some enemy_ent ->
      let enemy = get_enemy enemy_ent in
      let target = enemy_target enemy st' in
      let enemy =
        {enemy with direction = direction (subtract target enemy.location)} in
      let (enemy_ent, st') =
        match enemy.equip with
        | None -> (Enemy enemy, st')
        | Some e ->
          if distance enemy.location target > e.bullet_dist
          then (Enemy enemy, st')
          else entity_attack (Enemy enemy) st' in
      let (enemy, st') = enemy_move target (get_enemy enemy_ent) st' in
      {st' with enemies = enemy::st'.enemies} in
  List.fold_left step_enemy {st with enemies = []}
    (List.sort
       (fun (e1: enemy) (e2: enemy) ->
         let ploc = st.player.location in
         compare (distance e1.location ploc) (distance e2.location ploc))
       st.enemies)

let advance_bullets st =
  let step_bullet st' (bullet: bullet) =
    let blt_opt = move_bullet bullet in
    match blt_opt with
    | None -> st'
    | Some bullet ->
      let (st', blt_opt) = check_bullet_colls st' bullet in
      match blt_opt with
      | None -> st'
      | Some bullet -> {st' with bullets = bullet::st'.bullets} in
  List.fold_left step_bullet {st with bullets = []} st.bullets

(* [advance_structures st] is the state after all structures in the map have
 * advanced one frame targetting enemies, taking damage, and shooting bullets. *)
let advance_structures st =
  let step_struct st' (strct: structure) =
    match entity_passive (Structure strct) with
    | None -> st'
    | Some struct_ent ->
      let strct = get_struct struct_ent in
      let max_rot = structure_rotation_speed in
      if strct.equip.id = "harvester"
      then let strct =
             {strct with direction = strct.direction +. max_rot /. 4.} in
        let (struct_ent, st') = entity_attack (Structure strct) st' in
        {st' with structures = (get_struct struct_ent)::st'.structures}
      else let target = find_target strct.location `Enemy st' in
      match target with
      | None -> {st' with structures = strct::st'.structures}
      | Some target ->
        match strct.equip.id with
        | "impulse" ->
          if distance strct.location target > strct.equip.bullet_dist
          then {st' with structures = strct::st'.structures}
          else let strct =
                 {strct with direction = strct.direction +. max_rot /. 2.} in
            let (struct_ent, st') =
              entity_attack (Structure strct) st' in
            {st' with structures = (get_struct struct_ent)::st'.structures}
        | _ ->
          if distance strct.location target > strct.equip.bullet_dist
          then {st' with structures = strct::st'.structures}
          else let dir = calc_struct_dir strct target in
            let strct = {strct with direction = dir} in
            let (struct_ent, st') =
              if abs_float (dir -. strct.direction) >= max_rot *. 0.9
              then (Structure strct, st')
              else entity_attack (Structure strct) st' in
        {st' with structures = (get_struct struct_ent)::st'.structures} in
  List.fold_left step_struct {st with structures = []} st.structures

let advance_upgrade upgrade_id st =
  let player = st.player in
  let {equips; bits} = player in
  let upgrade = upgrade_of_id upgrade_id default_upgrades in
  let required = upgrade.requires in
  let cost = upgrade.cost in
  let valid = List.for_all
      (fun id -> List.mem (equip_of_id id equips) equips) required in
  if valid && bits >= cost then
    let equip = equip_of_id upgrade_id default_equips in
    let new_equips = equips @ [equip] in
    let new_index = index_of_equip_id upgrade_id new_equips in
    let new_player = {player with equips = new_equips; bits = bits - cost;
                                  equip_index = new_index;
                                  upgrades = possible_upgrades new_equips} in
    {st with player = new_player}
  else st

(* [check_build_valid sloc hitbox st] is true if the player can build a turret
 * at the specified location; false otherwise. *)
let check_build_valid sloc hitbox st =
  let sbox = hitbox in
  let {player = {equip_index; equips; location = ploc; hitbox = pbox};
       enemies; structures; bitfields} = st in
  let check_harvester =
    if equip_id_at_index equip_index equips = "harvester"
    then check_bitfields sloc bitfields else true in
  let valid = not (is_coll sloc ploc sbox pbox) in
  let check_enemies =
    List.for_all
      (fun (e: enemy) -> not (is_coll sloc e.location sbox e.hitbox)) enemies in
  let check_structures =
    List.for_all
      (fun (s: structure) -> not (is_coll sloc s.location sbox s.hitbox))
      structures in
  valid && check_enemies && check_structures && check_bounds sloc sbox
  && check_harvester

(* [advance_build stats loc st] is the state after a build. *)
let advance_build (health, attack) loc st =
  let {player; structures} = st in
  let {equips; equip_index = eid} = player in
  let equip = equip_at_index eid equips in
  let cost = build_cost (health, attack) in
  let new_structure = gen_structure health attack loc equip in
  {st with mode = Normal; structures = new_structure :: structures;
           player = {player with bits = player.bits - cost}}

(* [advance_builder (stats, build) st] is the state with Build mode activated if
 * the player has enough bits to build the turret specified. *)
let advance_builder (stats, build) st =
  let st = {st with build_stats = stats} in
  let cost = build_cost stats in
  let {player} = st in
  if build && player.bits >= cost
  then {st with mode = Build}
  else st

let advance_scroll sc st =
  let new_index =
    pos_mod (st.player.equip_index + sc) (List.length st.player.equips) in
  {st with player = {st.player with equip_index = new_index}}

(* [check_interact_valid loc st] is true if the player can perform the specified
 * interaction at location [loc] in the given state [st]. *)
let check_interact_valid loc st =
  let {player; mode; bitfields} = st in
  let {equip_index; equips; location = ploc} = player in
  match mode with
  | Build -> check_build_valid loc structure_size st
  | Normal | Interaction ->
    (match equip_id_at_index equip_index equips with
     | "laser" -> player.stopped
     | "harvester" -> check_bitfields ploc bitfields
     | _ -> true)
  | _ -> false

(* [advance_hover coords st] is the state after player has rotated according to
 * the mouse location. Calls [check_interact_valid] for graphical purposes. *)
let advance_hover (mx, my) st =
  let {player} = st in
  let {location = ploc}: player = player in
  if (mx, my) <> (-1., -1.)
  then
    let phi = atan2 (my -. half_map_size) (mx -. half_map_size) in
    let loc = world_xy_of_canvas ploc (mx, my) in
    {st with player = {player with direction = phi}; mouse = (mx, my);
             can_interact = check_interact_valid loc st}
  else {st with mouse = (mx, my)}

(* [advance_interact cloc st] matches the current interaction based off the
 * click location [cloc] in [st] with the appropriate advance function. *)
let advance_interact cloc st =
  let {player; mode; build_stats} = st in
  let {bits; location = ploc}:player = player in
  let loc = world_xy_of_canvas ploc cloc in
  match mode with
  | Normal -> st
  | Interaction ->
    if check_interact_valid loc st
    then advance_attack st (Player player) else st
  | Build ->
    let cost = build_cost build_stats in
    if check_interact_valid loc st && bits >= cost
    then advance_build build_stats loc st
    else {st with mode = Normal}
  | Dead -> st

(* [advance_action act st] is the state after applying [act] to state [st]. *)
let advance_action act st =
  match act with
  | StartInteract ->
    if st.mode = Normal then {st with mode = Interaction} else st
  | StopInteract ->
    if st.mode = Interaction then {st with mode = Normal} else st
  | Move dir -> advance_move dir st
  | Interact loc -> advance_interact loc st
  | Hover loc -> advance_hover loc st
  | Upgrade upgrade_id -> advance_upgrade upgrade_id st
  | Scroll sc -> advance_scroll sc st
  | Builder b -> advance_builder b st
  | Advance -> st

let advance acts st frame_advance =
  if (frame_advance && (List.mem Advance acts)) || not frame_advance
  then
    st
    |> check_stopped acts
    |> fold_rev advance_action acts
    |> advance_enemies
    |> advance_structures
    |> advance_bullets
    |> advance_passive
    |> advance_wave
  else st
