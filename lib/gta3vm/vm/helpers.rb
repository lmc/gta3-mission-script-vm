module Gta3Vm::Vm::Helpers

  extend self

  def hex(array_of_bytes)
    hex_a(array_of_bytes).join(" ")
  end

  def hex_a(array_of_bytes)
    array_of_bytes = [array_of_bytes] unless array_of_bytes.is_a?(Array)
    array_of_bytes = array_of_bytes.map { |b| b.ord } if array_of_bytes.first.is_a?(String)
    array_of_bytes.map{|m| m.to_s(16).rjust(2,"0") }
  end

end