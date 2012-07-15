class Pickup < GameObject
  def self.attributes
    {
      model: int,
      flags: int,
      x: float,
      y: float,
      z: float
    }
  end

  def self.map_render_args
    [:point_3d,[:x,:y,:z]]
  end
end
