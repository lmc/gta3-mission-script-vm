module Opcodes
  class << self
    attr_accessor :definitions
  end
  self.definitions = {}
  include OpcodeDsl
  int, float, bool, string = :int, :float, :bool, :string
  pg_if = :pg_if

  opcode("0002", "jump", jump_location:int) do |args|
    self.pc = args.jump_location.value_native
  end

  opcode("03A4", "thread_set_name", thread_name:string) do |args|
    self.thread_names[self.thread_id] = args.thread_name.value_native
  end

  opcode("016A", "screen_fade", fade_in_out:bool, fade_time:int) do |args|
    # do nothing?
  end

  opcode("042C", "engine_set_missions_count", missions_count:int) do |args|
    self.missions_count = args.missions_count.value_native
  end

  opcode("030D", "engine_set_progress_count",      progress_count:int,      &engine_var_setter(:progress_count))
  opcode("0997", "engine_set_respect_count",       respect_count:int,       &engine_var_setter(:respect_count))
  opcode("01F0", "engine_set_max_wanted_level",    max_wanted_level:int,    &engine_var_setter(:max_wanted_level))
  opcode("0111", "engine_set_wasted_busted_check", wasted_busted_check:int, &engine_var_setter(:wasted_busted_check))

  opcode("00C0", "engine_set_game_time", hour:int, minute:int) do |args|
    self.engine_vars.time_hour   = args.hour.value_native
    self.engine_vars.time_minute = args.minute.value_native
  end

  opcode("04E4", "engine_refresh_renderer_at", x:float, y:float) do |args|
    # do nothing?
  end

  opcode("03CB", "engine_set_renderer_at", x:float, y:float, z:float) do |args|
    # do nothing?
  end

  opcode("062A", "engine_set_game_stat_float", var_id:int, value:float) do |args|
    self.engine_vars.game_stats ||= {}
    self.engine_vars.game_stats[args.var_id.value_native] = args.value.value_native
  end

  opcode("0629", "engine_set_game_stat_int", var_id:int, value:int) do |args|
    self.engine_vars.game_stats ||= {}
    self.engine_vars.game_stats[args.var_id.value_native] = args.value.value_native
  end

  # player_id is a returned global variable
  opcode("0053", "player_create", model:int, x:float, y:float, z:float, player_id:pg_if ) do |args|
    # do something??
    #puts args.player_id.value_native
    #puts args.player_id.value_bytes
    #write!(args.player_id.value_native,4,"PL01".bytes.to_a)
    allocate!(args.player_id.value_native,:pg_if)
  end
end
