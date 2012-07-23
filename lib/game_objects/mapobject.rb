class Mapobject < GameObject
  def self.attributes
    {
      model: int,
      x:  float,
      y:  float,
      z:  float
    }
  end

  def self.map_render_args
    [:point_3d_r,[:x,:y,:z,:rz]]
  end
end
