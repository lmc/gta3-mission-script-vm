module Gta3Vm::Vm::DataTypeMethods

  extend self

  def bytes_to_read_for_arg_at_offset(offset)
    arg_type = memory.read(offset,1)[0]
    bytes_to_read_for_arg_data_type(arg_type,offset)
  end

  def bytes_to_read_for_arg_data_type(arg_type,offset)
    arg_type = normalize_type(arg_type)
    shorthand = type_int_to_shorthand(arg_type)

    if SHORTHANDS_SIZES[shorthand]
      SHORTHANDS_SIZES[shorthand]
    else
      case arg_type
      when 0x09 # immediate 8-byte string
        8
      when 0x0e # variable-length string
        memory.read(offset + 1,1)[0] + 1 #+1 to read the var string length prefix too
      else
        if arg_type > self.class.max_data_type # immediate type-less 8-byte string
          7
        else
          raise Gta3Vm::Vm::InvalidDataType, "unknown data type #{arg_type} (#{hex(arg_type)})"
        end
      end
    end
  end

  def type_shorthand_to_int(shorthand)
    
  end

  def type_shorthand_to_pack_char(shorthand)
    SHORTHANDS_PACK_CHARS[shorthand]
  end

  def type_int_to_shorthand(int)
    self.class.data_types[int]
  end

  def normalize_type(arg_type)
    arg_type = Gta3Vm::Vm::DataTypeMethods::TYPE_SHORTHANDS[arg_type] if arg_type.is_a?(Symbol)
    raise "Unknown type: #{arg_type.inspect}" unless arg_type.is_a?(Numeric)
    arg_type
  end

  SHORTHANDS_SIZES = {
    :int32   => 4,
    :int16   => 2,
    :int8    => 1,
    :pg      => 2,
    :pl      => 2,
    :float32 => 4,
    :float16 => 2
  }
  SHORTHANDS_PACK_CHARS = {
    :int32   => "l<",
    :int16   => "s<",
    :int8    => "c",
    :pg      => "S<",
    :pl      => "S<",
    :float32 => "e",
    :float16 => nil # lol float16 is fucked
  }




  DATA_TYPE_MAX = 31
  TYPE_SHORTHANDS = {
    :int32   => 0x01,
    :pg      => 0x02, # all "pointers" are to ints or floats
    :pl      => 0x03,
    :bool    => 0x04,
    :int8    => 0x04,
    :int16   => 0x05,
    :float32 => 0x06,
    :string  => 0x09,
    :vstring => 0x0e
  }
  TYPE_SHORTHANDS_INV = TYPE_SHORTHANDS.invert
  PACK_CHARS_FOR_DATA_TYPE = {
   -0x01 => "S<",
    0x01 => "l<",
    0x02 => "S<",
    0x03 => "S<",
    0x04 => "c",
    0x05 => "s<",
    0x06 => "e"
  }
  FLOAT_PRECISION = 3
  # p much everything is little-endian
  def arg_to_native(arg)
    return nil if arg.type == 0x00

    shorthand = type_int_to_shorthand( normalize_type(arg.type) )

    # puts "arg_to_native(#{arg.inspect})"
    # puts "type - #{arg.type} - shorthand - #{shorthand.inspect} - pack_char - #{type_shorthand_to_pack_char(shorthand).inspect}"

    value = if pack_char = type_shorthand_to_pack_char(shorthand)
      value = arg.value.to_byte_string.unpack( pack_char )[0]
      value
    elsif shorthand == :float16
      # HACK: these "floats" are actually fixed-point int16s, we need to divide by 8 to get a real value
      arg.value.to_byte_string.unpack( type_shorthand_to_pack_char(:int16) )[0] / 8.0
    else

      case arg.type
      when  0x09 # immediate 8-byte string
        arg.value.to_byte_string.strip_to_null
      when  0x0e # variable-length string
        arg.value.to_byte_string[1..-1]
      else
        if arg.type > self.class.max_data_type # immediate type-less 8-byte string
          [arg.type,arg.value].flatten.to_byte_string.strip_to_null #FIXME: can have random crap after first null byte, cleanup
        else
          raise Gta3Vm::Vm::InvalidDataType, "unknown data type #{arg_type} (#{hex(arg_type)})"
        end
      end

    end

    value = value.round(FLOAT_PRECISION) if value.is_a?(Float)

    value

  end

  def native_to_arg_value(arg_type,native)
    native = [native]
    arg_type = TYPE_SHORTHANDS[arg_type] if arg_type.is_a?(Symbol)
    pack_char = PACK_CHARS_FOR_DATA_TYPE[arg_type]
    if !pack_char
      raise Gta3Vm::Vm::InvalidDataType, "native_to_arg_value: unknown data type #{arg_type} (#{hex(arg_type)})"
    end
    native.pack(pack_char).bytes.to_a
  end

end