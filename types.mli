(* [coords] are multipurpose float 2-tuples. *)
type coords = float * float

(* [button] represents the type of mouse button presses. *)
type button = Left | Middle | Right

(* [upgrade] represents the type of an equip upgrade. *)
type upgrade = {
  id: string;
  cost: int;
  requires: string list
}

(* [build_stats] represents the stats from the build menu. *)
type build_stats = int * int

(* [input_state] represents the player's current inputs. *)
type input_state = {
  keys_pressed: char list;
  keys_held: char list;
  keys_released: char list;
  buttons_pressed: button list;
  buttons_held: button list;
  buttons_released: button list;
  mouse: coords;
  scroll: int;
  builder: build_stats * bool;
  upgrade: string option;
}

(* [action] represents the actions a player's inputs are converted into. *)
type action =
  | Move of coords
  | StartInteract
  | StopInteract
  | Interact of coords
  | Hover of coords
  | Upgrade of string
  | Scroll of int
  | Builder of (build_stats * bool)
  | Advance

(* [pattern] represents the possible enemy movement patterns. *)
type pattern =
  | Linear
  | Oscillate
  | Dodge

(* [attack] represents the possible enemy attack patterns. *)
type attack =
  | MaxDist of float * pattern
  | ConstDist of float * pattern

(* [equip] represents an equippable tool or weapon. *)
type equip = {
  id: string;
  power: float;
  bullet_speed: float;
  bullet_size: float;
  bullet_dist: float;
  piercing: bool;
  cooldown: int * int;
}

(* [bullet] represents a bullet in the world. *)
type bullet = {
  equip_id: string;
  damage: float;
  location: coords;
  piercing: bool;
  velocity: coords;
  origin: coords;
  dist: float;
  direction: float;
  hitbox: float;
  friendly: bool;
  hit_ids: int list;
}

(* [structure] represents a structure in the world. *)
type structure = {
  hp: float * float;
  location: coords;
  direction: float;
  attack: float;
  equip: equip;
  invuln: int * int;
  hitbox: float;
}

(* [enemy] represents an enemy in the world. *)
type enemy = {
  id: int;
  species: string;
  hp: float * float;
  targets: [`All | `Player | `Structure | `Harvester | `Turret] list;
  attack: float;
  pattern: attack;
  speed: float;
  equip: equip option;
  stopped: bool;
  location: coords;
  direction: float;
  hitbox: float;
}

(* [player] represents a player in the world. *)
type player = {
  hp: float * float;
  attack: float;
  speed: float;
  stopped: bool;
  equip_index: int;
  equips: equip list;
  location: coords;
  direction: float;
  hitbox: float;
  invuln: int * int;
  bits: int;
  upgrades: upgrade list;
}

(* [entity] represents any dynamic object in the world. *)
type entity =
  | Enemy of enemy
  | Player of player
  | Structure of structure
  | Bullet of bullet

(* [bitfield] represents a resource field. *)
type bitfield = {
  location: coords;
  radius: float;
  bits: (coords * float) list;
}

(* [mode] is the current status of the game. *)
type mode = Normal | Interaction | Build | Dead

(* [state] represents the game state. *)
type state = {
  player: player;
  enemies: enemy list;
  bullets: bullet list;
  structures: structure list;
  bitfields: bitfield list;
  wave: int * int;
  points: int;
  enemies_spawned: int;
  mode: mode;
  mouse: coords;
  can_interact: bool;
  build_stats: build_stats;
}
