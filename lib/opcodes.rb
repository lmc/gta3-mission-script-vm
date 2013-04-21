module Opcodes
  def self.module_for_game(data_dir)
    case data_dir
    when "vc"
      OpcodesVc
    end
  end

  SWITCH_THREAD_ON_INIT = true

  def implement_opcodes!

    include OpcodeDsl
    int, float, bool, string = :int, :float, :bool, :string
    pg = :pg
    int_or_float, int_or_var, float_or_var = :int_or_float, :int_or_var, :float_or_var

    #parse_from_scm_ini("data/vc/VICESCM.ini")
    # parse_from_scm_ini("data/sa/SASCM.ini")

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
    opcode("02ED", "engine_set_hidden_packages_count", hidden_packages_count:int, &engine_var_setter(:hidden_packages_count))
    opcode("01F0", "engine_set_max_wanted_level",    max_wanted_level:int,    &engine_var_setter(:max_wanted_level))
    opcode("0111", "engine_set_wasted_busted_check", wasted_busted_check:int, &engine_var_setter(:wasted_busted_check))
    opcode("09BA", "engine_set_show_entered_zone_name", show_entered_zone_name:bool, &engine_var_setter(:show_entered_zone_name))

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

    # opcode("0053", "player_create", model:int, x:float, y:float, z:float, ret_player_id:pg ) do |args|
    opcode("0053", "player_create", model:int, x:float, y:float, z:float, ret_player_id:pg ) do |args|
      self.game_objects[args.ret_player_id] = Player.new(
        :model => args.model,
        :x => args.x,
        :y => args.y,
        :z => args.z,
      )
      allocate!(args.ret_player_id,:pg,Player)
    end

    opcode("06CF", "noop", noop:int ) do |args|
      # do nothing!
    end

    opcode("0914", "extscript_noop", noop:int ) do |args|
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

    opcode("07AF", "player_get_pedgroup", player_id:pg, ret_player_group:pg ) do |args|
      pedgroup = self.game_objects[args.player_id].pedgroup ||= 126126
      allocate!(args.ret_player_group,:int32,pedgroup)
    end

    opcode("01F5", "player_get_actor", player_id:pg, ret_player_actor_id:pg ) do |args|
      #self.game_objects[args.ret_player_actor_id] = Actor.new
      #allocate!(args.ret_player_actor_id,:pg,Actor)
      allocate_game_object!(args.ret_player_actor_id,Actor)
    end

    opcode("0373", "camera_position_angle_behind_player" ) do |args|
      # do nothing?
    end

    opcode("0173", "actors_set_z_angle", actor_id:pg, z_angle:float ) do |args|
      # TODO: write to actors/players
    end

    opcode("0417", "mission_start", mission_id:int ) do |args|
      # TODO: implement
      # TODO: does this require passing control to mission thread immediately?
    end

    opcode("0001", "sleep", time_ms:int_or_var ) do |args|
      # TODO: set up timer for resume?
      self.thread_suspended = true
    end

    opcode("0004", "set_global_int", ret_address:pg, value:int ) do |args|
      allocate!(args.ret_address,args.value_type,args.value)
    end

    opcode("0005", "set_global_float", ret_address:pg, value:float ) do |args|
      puts [args.ret_address,args.value_type,args.value].inspect
      allocate!(args.ret_address,args.value_type,args.value)
    end

    opcode("04AE", "set_global_int_or_float", ret_address:pg, value:int_or_float ) do |args|
      allocate!(args.ret_address,args.value_type,args.value)
    end

    opcode("0008", "add_set_global_int", ret_address:pg, value:int ) do |args|
      gv_value = arg_to_native(:int32,read(args.ret_address,4))
      gv_value += args.value 
      allocate!(args.ret_address,:int32,gv_value)
    end

    opcode("0213", "pickup_create", model:int, flags:int, x:float, y:float, z:float, ret_pickup_id:pg ) do |args|
      # TODO: do something with pickup
      # flags documented at: http://gtag.gtagaming.com/opcode-database.php?opcode=0213
      allocate!(args.ret_pickup_id,:pg,Pickup)
    end


    opcode("029B", "mapobject_create", model:int, x:float_or_var, y:float_or_var, z:float_or_var, ret_mapobject_id:pg) do |args|
      puts args.inspect
      allocate_game_object!(args.ret_mapobject_id,Mapobject) do |mapobject|
        mapobject.assign_from_args(args,without: [:ret_mapobject_id])
      end
      #exit
    end

    opcode("01C7", "mapobject_cleanup_exclude", mapobject_id:pg) do |args|
      # TODO: do something with this
    end


    opcode("0180", "engine_bind_onmission_var", ret_address:pg ) do |args|
      self.onmission_address = args.ret_address
      allocate!(args.ret_address,:int32,0)
    end

    opcode("01E8", "paths_disable_in_cube", x1:float, y1:float, z1:float, x2:float, y2:float, z2:float ) do |args|
      # TODO: do something with this?
    end

    opcode("014B", "cargen_create", x:float, y:float, z:float, rz:float, car_model:int, color1:int, color2:int,
      force_spawn:bool, alarm_pc:int, locked_pc:int, delay_min:int, delay_max:int, ret_cargen_id:pg ) do |args|
      allocate_game_object!(args.ret_cargen_id,Cargen) do |cargen|
        cargen.assign_from_args(args,without: [:ret_cargen_id])
      end
    end

    opcode("014C", "cargen_set_ttl", cargen_id:pg, ttl:int ) do |args|
      self.game_objects[args.cargen_id].ttl = args.ttl
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

    opcode("0913", "extscript_run", extscript_id:int, var_args: true ) do |args|
      # TODO: do something with this
    end

    opcode("0776", "objgroup_create_objects", objgroup_id:string ) do |args|
      # TODO: do something with this
    end

    opcode("0363", "obj_set_visibility_closest_of_type", x:float, y:float, z:float, radius:float, model:int, visible:bool ) do |args|
      # TODO: do something with this
    end

    opcode("004F", "thread_create_with_args", jump_thread_pc:int, var_args: true ) do |args|
      self.thread_pcs << args.jump_thread_pc
      # TODO: load var_args into thread local vars
      self.thread_switch_to_id = self.thread_pcs.size-1 if SWITCH_THREAD_ON_INIT
    end

    opcode("00D7", "thread_create", jump_thread_pc:int ) do |args|
      self.thread_pcs << args.jump_thread_pc
      self.thread_switch_to_id = self.thread_pcs.size-1 if SWITCH_THREAD_ON_INIT
    end

    opcode("004E", "thread_destroy" ) do |args|
      dead_thread_id = self.thread_id
      self.thread_pcs[dead_thread_id] = nil
      self.pc = nil
      self.thread_suspended = true
    end

    opcode("00D6", "if", conditions_count:int ) do |args|
      conditions_count = args.conditions_count + 1 # just because
      self.branch_conditions = Array.new(conditions_count)
    end

    opcode("0256", "if_player_defined", player_id:pg ) do |args|
      bool = true

      #puts "should player exist? (y/n)"
      #bool = gets.strip == "y"

      write_branch_condition!( bool ) # TODO: do this properly
    end

    opcode("004D", "if_false_jump", jump_address:int ) do |args|
      if self.branch_conditions.any?(&:nil?)
        raise Vm::InvalidBranchConditionState, "not enough conditional opcodes (allocated: #{self.branch_conditions.size})"
      end
      self.pc = args.jump_address if !self.branch_conditions.all? # all must be true, otherwise jump
      self.branch_conditions = nil
    end

    opcode("0038", "if_gv_eq_int", gv_address:pg, int:int ) do |args|
      value_at_gv = arg_to_native(:int32,read(args.gv_address,4))
      write_branch_condition!( value_at_gv == args.int )
    end

    opcode("002C", "if_gv_int_gte_gv_int", gv_address_1:pg, gv_address_2:pg ) do |args|
      value_at_gv1 = arg_to_native(:int32,read(args.gv_address_1,4))
      value_at_gv2 = arg_to_native(:int32,read(args.gv_address_2,4))
      write_branch_condition!( value_at_gv1 >= value_at_gv2 )
    end


    opcode("0662", "gamedbg_print_string", dbg_string:string) do |args|
      puts "GAMEDBG: #{args.dbg_string}"
    end

    #opcode("0200", "is_player_near_car_3d_on_foot", player_id:pg, )

  end

end

module OpcodesVc
  include OpcodeDsl
  class << self
    attr_accessor :definitions
  end
  self.definitions = {} # Opcodes.definitions.dup
  parse_from_scm_ini("data/vc/VICESCM.ini")
  extend Opcodes
  implement_opcodes!
end
