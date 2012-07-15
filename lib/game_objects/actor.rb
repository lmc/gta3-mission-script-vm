class Actor < GameObject
  def self.attributes
    {
      rz: float,
    }
  end

  def self.map_render_args
    nil
  end
end
