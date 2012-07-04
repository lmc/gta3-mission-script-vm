module Opcodes
  class << self
    attr_accessor :definitions
  end
  self.definitions = {}
  include OpcodeDsl
  int, float, bool, string = :int, :float, :bool, :string
  pg_if = :pg_if
  int_or_float = :int_or_float

  opcode("0002", "jump", jump_location:int) do |args|
    self.pc = args.jump_location
  end

  opcode("03A4", "thread_set_name", thread_name:string) do |args|
    self.thread_names[self.thread_id] = args.thread_name
  end

  opcode("016A", "screen_fade", fade_in_out:bool, fade_time:int) do |args|
    # do nothing?
  end

  opcode("042C", "engine_set_missions_count", missions_count:int) do |args|
    self.missions_count = args.missions_count
  end

  opcode("030D", "engine_set_progress_count",      progress_count:int,      &engine_var_setter(:progress_count))
  opcode("0997", "engine_set_respect_count",       respect_count:int,       &engine_var_setter(:respect_count))
  opcode("01F0", "engine_set_max_wanted_level",    max_wanted_level:int,    &engine_var_setter(:max_wanted_level))
  opcode("0111", "engine_set_wasted_busted_check", wasted_busted_check:int, &engine_var_setter(:wasted_busted_check))

  opcode("00C0", "engine_set_game_time", hour:int, minute:int) do |args|
    self.engine_vars.time_hour   = args.hour
    self.engine_vars.time_minute = args.minute
  end

  opcode("04E4", "engine_refresh_renderer_at", x:float, y:float) do |args|
    # do nothing?
  end

  opcode("03CB", "engine_set_renderer_at", x:float, y:float, z:float) do |args|
    # do nothing?
  end

  opcode("062A", "engine_set_game_stat_float", var_id:int, value:float) do |args|
    self.engine_vars.game_stats ||= {}
    self.engine_vars.game_stats[args.var_id] = args.value
  end

  opcode("0629", "engine_set_game_stat_int", var_id:int, value:int) do |args|
    self.engine_vars.game_stats ||= {}
    self.engine_vars.game_stats[args.var_id] = args.value
  end

  opcode("0053", "player_create", model:int, x:float, y:float, z:float, ret_player_id:pg_if ) do |args|
    self.players[args.ret_player_id] = Player.new(
      :model => args.model,
      :x => args.x,
      :y => args.y,
      :z => args.z,
    )
    allocate!(args.ret_player_id,:pg_if)
  end

  opcode("06CF", "noop", noop:int ) do |args|
    # do nothing!
  end

  opcode("0914", "noop", noop:int ) do |args|
    # do nothing!
  end

  opcode("0746", "pedgroup_set_relationship", relationship:int, pedgroup_1:int, pedgroup_2:int ) do |args|
    self.engine_vars.pedgroup_relationships ||= {}
    self.engine_vars.pedgroup_relationships[args.pedgroup_1] ||= {}
    self.engine_vars.pedgroup_relationships[args.pedgroup_1][args.pedgroup_2] = args.relationship
    # also do it in reverse ??? 
    #self.engine_vars.pedgroup_relationships[args.pedgroup_2] ||= {}
    #self.engine_vars.pedgroup_relationships[args.pedgroup_2][args.pedgroup_1] = args.relationship
  end

  opcode("07AF", "player_get_pedgroup", player_id:pg_if, ret_player_group:pg_if ) do |args|
    pedgroup = self.players[args.player_id].pedgroup ||= 126126
    allocate!(args.ret_player_group,:int32,pedgroup)
  end

  opcode("01F5", "player_get_actor", player_id:pg_if, ret_player_actor_id:pg_if ) do |args|
    pedgroup = self.players[args.player_id].pedgroup ||= 126126
    # TODO: write to actors
    allocate!(args.ret_player_actor_id,:pg_if)
  end

  opcode("0373", "camera_position_angle_behind_player" ) do |args|
    # do nothing?
  end

  opcode("0173", "actors_set_z_angle", actor_id:pg_if, z_angle:float ) do |args|
    # TODO: write to actors/players
  end

  opcode("0417", "mission_start", mission_id:int ) do |args|
    # TODO: implement
    # TODO: does this require passing control to mission thread immediately?
  end

  opcode("0001", "sleep", time_ms:int ) do |args|
    # TODO: set up timer for resume?
    self.thread_suspended = true
  end

  opcode("0004", "set_global_int", ret_address:pg_if, value:int ) do |args|
    allocate!(args.ret_address,args.value_type,args.value)
  end

  opcode("0005", "set_global_float", ret_address:pg_if, value:float ) do |args|
    puts [args.ret_address,args.value_type,args.value].inspect
    allocate!(args.ret_address,args.value_type,args.value)
  end

  opcode("04AE", "set_global_int_or_float", ret_address:pg_if, value:int_or_float ) do |args|
    puts [args.ret_address,args.value_type,args.value].inspect
    allocate!(args.ret_address,args.value_type,args.value)
  end

  opcode("0213", "pickup_create", model:int, flags:int, x:float, y:float, z:float, ret_pickup_id:pg_if ) do |args|
    # TODO: do something with pickup
    # flags documented at: http://gtag.gtagaming.com/opcode-database.php?opcode=0213
    allocate!(args.ret_pickup_id,:pg_if)
  end

  opcode("0180", "engine_bind_onmission_var", ret_address:pg_if ) do |args|
    self.onmission_address = args.ret_address
    allocate!(args.ret_address,:pg_if)
  end

  opcode("01E8", "paths_disable_in_cube", x1:float, y1:float, z1:float, x2:float, y2:float, z2:float ) do |args|
    # TODO: do something with this?
  end

  opcode("014B", "cargen_create", x:float, y:float, z:float, rz:float, model:int, color1:int, color2:int,
    force_spawn:bool, alarm_pc:int, locked_pc:int, delay_min:int, delay_max:int, ret_cargen_id:pg_if ) do |args|
    # TODO: do something with this
    allocate!(args.ret_cargen_id,:pg_if)
  end

  opcode("014C", "cargen_set_ttl", cargen_id:pg_if, ttl:int ) do |args|
    # TODO: do something with this
  end

  opcode("0929", "extscript_create_on_object", extscript_id:int, model:int,
    priority:int, radius:float, flags:int ) do |args|
    # TODO: do something with this
  end

  opcode("07D3", "extscript_create_on_attractor", extscript_id:int, attractor_id:string ) do |args|
    # TODO: do something with this
  end

  opcode("0928", "extscript_create_on_ped_id", extscript_id:int, ped_id:int, priority:int ) do |args|
    # TODO: do something with this
  end

  opcode("08E8", "extscript_create_on_model", extscript_id:int, model:string ) do |args|
    # TODO: do something with this
  end

  opcode("0884", "extscript_set_name", extscript_id:int, name:string ) do |args|
    # TODO: do something with this
  end

  opcode("0776", "objgroup_create_objects", objgroup_id:string ) do |args|
    # TODO: do something with this
  end

  opcode("0363", "obj_set_visibility_closest_of_type", x:float, y:float, z:float, radius:float, model:int, visible:bool ) do |args|
    # TODO: do something with this
  end

  opcode("004F", "thread_create", thread_pc:int, var_args: true ) do |args|
    # TODO: do something with this
  end

end
