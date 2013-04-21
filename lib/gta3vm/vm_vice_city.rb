class Gta3Vm::VmViceCity < Gta3Vm::Vm
  def self.scm_markers
    [ [0x6d,:memory], [0x00,:models], [0x00,:missions] ]
  end
end
