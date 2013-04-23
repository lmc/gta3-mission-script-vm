
class String
  def strip_to_null
    temp = self.bytes.to_a
    null_index = temp.index(0)
    temp[0...null_index].to_byte_string
    #gsub(/#{0x00}.+$/,"")
  end
end

class Array
  def to_byte_string
    self.map { |byte| byte.chr }.join
  end
end

