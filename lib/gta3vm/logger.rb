module Gta3Vm::Logger
  def log(*strs)
    puts "#{self.class.name.gsub(/Gta3Vm::/,'')}: #{strs.join('')}"
  end
end
