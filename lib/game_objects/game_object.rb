class GameObject < OpenStruct
  def initialize(attributes = {})
    super( self.class.initialize_attributes(attributes) )
  end

  def assign_from_args(args,options = {})
    options = { :without => [] }.merge(options)
    puts "  #{(args.arg_names - Array[options[:without]]).inspect}"
    (args.arg_names - Array[options[:without]]).each do |arg_name|
      puts "  setting #{arg_name}.inspect to #{args.send(arg_name).inspect}"
      send("#{arg_name}=",args.send(arg_name))
    end
  end

  def self.attributes
    # {attribute: type}
    nil
  end

  def self.initialize_attributes(attributes)
    defaults = Hash[ self.attributes.map { |attribute,type| [attribute,nil] } ]
    defaults.merge(attributes)
  end

  def self.float; :float; end
  def self.int;   :int;   end
  def self.bool;  :bool;  end
end
