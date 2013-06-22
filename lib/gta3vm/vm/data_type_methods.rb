module Gta3Vm::Vm::DataTypeMethods

  extend self

  def bytes_to_read_for_arg_at_offset(offset)
    arg_type = memory.read(offset,1)[0]
    bytes_to_read_for_arg_data_type(arg_type,offset)
  end

  def bytes_to_read_for_arg_data_type(arg_type,offset)
    case arg_type
    when 0x01 # immediate 32 bit signed int
      4
    when 0x02 # 16-bit global pointer to int/float
      2
    when 0x03 # 16-bit local pointer to int/float
      2
    when 0x04 # immediate 8-bit signed int
      1
    when 0x05 # immediate 16-bit signed int 
      2
    when 0x06 # immediate 32-bit float
      4
    when 0x09 # immediate 8-byte string
      8
    when 0x0e # variable-length string
      memory.read(offset + 1,1)[0] + 1 #+1 to read the var string length prefix too
    else
      if arg_type > DATA_TYPE_MAX # immediate type-less 8-byte string
        7
      else
        raise Gta3Vm::Vm::InvalidDataType, "unknown data type #{arg_type} (#{hex(arg_type)})"
      end
    end
  end

  DATA_TYPE_MAX = 31
  TYPE_SHORTHANDS = {
    :int32   => 0x01,
    :pg      => 0x02, # all "pointers" are to ints or floats
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

    # arg_type = TYPE_SHORTHANDS[arg_type] if arg_type.is_a?(Symbol)

    value = if pack_char = PACK_CHARS_FOR_DATA_TYPE[arg.type]
      value = arg.value.to_byte_string.unpack( PACK_CHARS_FOR_DATA_TYPE[arg.type] )[0]
      value
    else

      case arg.type
      when  0x09 # immediate 8-byte string
        arg.value.to_byte_string.strip_to_null
      when  0x0e # variable-length string
        arg.value.to_byte_string[1..-1]
      else
        if arg.type > DATA_TYPE_MAX # immediate type-less 8-byte string
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