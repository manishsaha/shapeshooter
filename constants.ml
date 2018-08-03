open Types

let pi = acos (-1.)

let epsilon = 0.01

let world_size = 3500.

let map_size = 700.

let half_world_size = world_size /. 2.

let half_map_size = map_size /. 2.

let touch_dmg = 1.

let bit_size = 7.

let equip_ui_size = 80.

let background_line_spacing = 10.

let origin = (0., 0.)

let scroll_threshold = 90

let structure_rotation_speed = pi /. 30.

let structure_size = 30.

let player_health = 100.

let dmg_invuln = 20

let wave_buffer = 300

let wave_time = 1800

let harvester = {
  id = "harvester";
  power = 0.;
  bullet_speed = 0.;
  bullet_size = 0.;
  bullet_dist = 0.;
  piercing = false;
  cooldown = (30, 0);
}

let pistol = {
  id = "pistol";
  power = 1.;
  bullet_speed = 10.;
  bullet_size = 7.;
  bullet_dist = 300.;
  piercing = false;
  cooldown = (45, 0);
}

let shotgun = {
  id = "shotgun";
  power = 5.;
  bullet_speed = 15.;
  bullet_size = 4.;
  bullet_dist = 150.;
  piercing = true;
  cooldown = (110, 0);
}

let machine = {
  id = "machine";
  power = 2.;
  bullet_speed = 10.;
  bullet_size = 7.;
  bullet_dist = 400.;
  piercing = false;
  cooldown = (10, 0);
}

let flamethrower = {
  id = "flamethrower";
  power = 0.3;
  bullet_speed = 5.;
  bullet_size = 3.;
  bullet_dist = 100.;
  piercing = true;
  cooldown = (1, 0);
}

let sniper = {
  id = "sniper";
  power = 50.;
  bullet_speed = 15.;
  bullet_size = 5.;
  bullet_dist = 1000.;
  piercing = true;
  cooldown = (200, 0);
}

let laser = {
  id = "laser";
  power = 35.;
  bullet_speed = 0.02;
  bullet_size = 5.;
  bullet_dist = 2. *. world_size;
  piercing = true;
  cooldown = (240, 0);
}

let rocket = {
  id = "rocket";
  power = 75.;
  bullet_speed = 7.;
  bullet_size = 10.;
  bullet_dist = 7000.;
  piercing = false;
  cooldown = (220, 0);
}

let impulse = {
  id = "impulse";
  power = 0.5;
  bullet_speed = 8.;
  bullet_size = 3.;
  bullet_dist = 200.;
  piercing = true;
  cooldown = (150, 0);
}

let default_equips = [harvester; pistol; shotgun; machine;
                      flamethrower; sniper; laser; rocket; impulse]

let start_equips = [harvester; pistol]

let default_waves = ["swarm"; "tank"; "close"; "mid"; "far"; "turret"]

let default_enemies = [
  {
    id = 0;
    species = "weak";
    hp = (1., 1.);
    targets = [`Player];
    attack = 1.;
    pattern = MaxDist (0., Linear);
    speed = 2.5;
    equip = None;
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 10.;
  }; {
    id = 0;
    species = "p_seeker";
    hp = (10., 10.);
    targets = [`Player];
    attack = 1.;
    pattern = MaxDist (0., Linear);
    speed = 6.;
    equip = None;
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 10.;
  }; {
    id = 0;
    species = "h_seeker";
    hp = (5., 5.);
    targets = [`Harvester; `Player];
    attack = 1.;
    pattern = MaxDist (0., Linear);
    speed = 7.;
    equip = None;
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 10.;
  }; {
    id = 0;
    species = "tank";
    hp = (150., 150.);
    targets = [`All];
    attack = 5.;
    pattern = ConstDist (150., Linear);
    speed = 1.5;
    equip = Some pistol;
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 30.;
  }; {
    id = 0;
    species = "p_tank";
    hp = (150., 150.);
    targets = [`Player];
    attack = 0.5;
    pattern = MaxDist (150., Linear);
    speed = 1.5;
    equip = Some machine;
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 30.;
  };{
    id = 0;
    species = "t_tank";
    hp = (150., 150.);
    targets = [`Structure; `Player];
    attack = 1.;
    pattern = MaxDist (200., Linear);
    speed = 1.5;
    equip = Some {rocket with power = 20.};
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 30.;
  }; {
    id = 0;
    species = "p_mid";
    hp = (15., 15.);
    targets = [`Player];
    attack = 2.;
    pattern = ConstDist (200., Linear);
    speed = 3.5;
    equip = Some pistol;
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 15.;
  }; {
    id = 0;
    species = "t_mid";
    hp = (15., 15.);
    targets = [`Turret; `Player];
    attack = 1.;
    pattern = MaxDist (200., Linear);
    speed = 3.;
    equip = Some machine;
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 15.;
  }; {
    id = 0;
    species = "flame";
    hp = (50., 50.);
    targets = [`All];
    attack = 1.;
    pattern = ConstDist (50., Linear);
    speed = 3.;
    equip = Some flamethrower;
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 15.;
  }; {
    id = 0;
    species = "shotgun";
    hp = (20., 20.);
    targets = [`Player];
    attack = 0.5;
    pattern = MaxDist (100., Linear);
    speed = 3.5;
    equip = Some shotgun;
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 15.;
  }; {
    id = 0;
    species = "sniper";
    hp = (20., 20.);
    targets = [`Player];
    attack = 1.;
    pattern = ConstDist (300., Linear);
    speed = 2.;
    equip = Some sniper;
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 15.;
  }; {
    id = 0;
    species = "rush";
    hp = (15., 15.);
    targets = [`Player];
    attack = 1.;
    pattern = MaxDist (0., Linear);
    speed = 5.;
    equip = Some {impulse with cooldown = (50, 0)};
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 10.;
  }; {
    id = 0;
    species = "rocket";
    hp = (30., 30.);
    targets = [`Player];
    attack = 1.;
    pattern = ConstDist (300., Linear);
    speed = 5.;
    equip = Some {rocket with power = 20.};
    stopped = false;
    location = (0., 0.);
    direction = 0.;
    hitbox = 20.;
  };
]

let default_upgrades = [
  {
    id = "harvester";
    cost = 0;
    requires = [];
  }; {
    id = "pistol";
    cost = 0;
    requires = [];
  }; {
    id = "shotgun";
    cost = 150;
    requires = ["pistol"];
  }; {
    id = "machine";
    cost = 200;
    requires = ["shotgun"];
  }; {
    id = "flamethrower";
    cost = 500;
    requires = ["shotgun"];
  }; {
    id = "sniper";
    cost = 200;
    requires = ["pistol"];
  }; {
    id = "laser";
    cost = 500;
    requires = ["sniper"];
  }; {
    id = "rocket";
    cost = 500;
    requires = ["sniper"];
  }; {
    id = "impulse";
    cost = 350;
    requires = ["pistol"];
  }
]

let starting_upgrades = [
  List.nth default_upgrades 2;
  List.nth default_upgrades 5;
  List.nth default_upgrades 8;
]

let default_player = {
  hp = (player_health, player_health);
  attack = 1.;
  speed = 5.;
  stopped = true;
  equips = start_equips;
  equip_index = 0;
  location = origin;
  direction = 0.;
  hitbox = 20.;
  invuln = (dmg_invuln, 0);
  bits = 0;
  upgrades = [];
}
