class Player < GameObject
  def self.attributes
    {
      model: int,
      x: float,
      y: float,
      z: float,
      pedgroup: int,
      actor_id: int,
      defined: bool
    }
  end

  def self.map_render_args
    [:point_3d,[:x,:y,:z]]
  end
end
