class Instruction < Array

  def self.new_from_bytecode(bytecode)
    
  end

  def opcode
    self[0]
  end

  def args
    self[1]
  end

  def negated?
    
  end

  def negated_opcode
    
  end

  def size
    flatten.size
  end



  class Opcode < Array;

  end


  class Args < Array;

  end


  class Arg < Array;

    def type
      self[0]
    end

    def value
      self[1]
    end
  end

end
