class Gta3Vm::Assembler < Gta3Vm::Disassembler

  def assemble
    input.each_line do |line|
      assemble_line(line)
    end
  end

  def assemble_line(line)
    tokens = line.split(" ")
    case tokens[0]
    when /^:/
      # label
    when /^MEMORY/

    when /^MODEL/

    when /^MISSION/

    end
  end

  protected

  def input
    File.open("disassemble.txt","r")
  end

  def output
    File.open("assembled.scm","w")
  end

end
