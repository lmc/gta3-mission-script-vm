class Cargen < GameObject
  def self.attributes
    {
      x:  float,
      y:  float,
      z:  float,
      rz: float,
      color1: int,
      color2: int,
      force_spawn: bool,
      alarm_pc: int,
      locked_pc: int,
      delay_min: int,
      delay_max: int,
      ttl: int, # how many cars to generate, when 0 = never generate, 101 = always generate
    }
  end

  def self.map_render_args
    [:point_3d_r,[:x,:y,:z,:rz]]
  end
end
