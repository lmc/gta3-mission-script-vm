require 'sinatra'
require 'sinatra/twitter-bootstrap'
require 'haml'
require 'sass'

$: << "#{File.dirname(__FILE__)}/../lib"
require 'gta3vm'

class VmHost < Sinatra::Base

  set :logging, true

  register Sinatra::Twitter::Bootstrap::Assets

  $vm = Gta3Vm::Vm.new_for_vc
  $exe = $vm.execute

  get "/test" do
    haml :test, layout: true
  end

  get "/stylesheets/:file" do
    scss params[:file].to_sym
  end
  get "/javascripts/:file" do
    coffee params[:file].to_sym
  end

  get "/tick" do
    $exe.tick
    content_type :json
    send_tick_payload.to_json
  end

  get "/reset" do
    $exe.reset
    redirect "/test"
  end

  get "/inspect/:pos" do
    # Instrumentation.instrument {
    haml :inspect, layout: false, locals: {pos: params[:pos].to_i, vm: $vm}
    # }
  end

  get "/memory/:mem_begin/:mem_end" do
    Instrumentation.instrument {
    mem_begin, mem_end = params[:mem_begin].to_i, params[:mem_end].to_i
    mem_begin = 0 if mem_begin < 0
    mem_end = $vm.memory.size if mem_end > $vm.memory.size
    memory = $vm.memory.read(mem_begin,mem_end - mem_begin).to_a
    puts memory.inspect
    # haml :memory, layout: false, locals: {mem_begin: mem_begin, mem_end: mem_end, memory: memory, vm: $vm, exe: $exe, host: self}
    build_memory_output(mem_begin,mem_end,memory)
    }
  end

  def build_memory_output(mem_begin,mem_end,memory)
    pos = mem_begin - 1
    hexes = []
    Instrumentation.time_block("VmHost#hexes"){
    hexes = Gta3Vm::Vm::Helpers.hex_a(memory).to_a
    }
    # Instrumentation.time_block("Memory#inject"){
    str = ""
    puts "ENV: #{ENV.inspect}"
    puts "hexes.size: #{hexes.size}"
    puts "hexes: #{hexes.inspect}"
    hexes.each{ |byte|
      pos += 1
      str << "<span class='"
      str << classes_for_memory_pos(pos)
      str << "'>"
      str << byte
      str << "</span> "
    }
    # }
    puts "str.size: #{str.size}"

    str
    # }
  end

  $classes_for_memory_pos_cache = {}
  def classes_for_memory_pos(pos)
    pos = pos.to_s
    # Instrumentation.time_block("VmHost#classes_for_memory_pos"){
    if $classes_for_memory_pos_cache.key?(pos)
      $classes_for_memory_pos_cache[pos]
    else
      address = _classes_for_memory_pos(pos)
      $classes_for_memory_pos_cache[pos] = address
      address
    end
    # }
  end
  def _classes_for_memory_pos(pos)
    # return "pos_#{pos}"
    pos = pos.to_i
    # Instrumentation.time_block("VmHost#_classes_for_memory_pos"){
    classes = []
    classes = ["pos_#{pos}"]
    classes << "current_pc" if pos == $exe.pc
    if opcode_start = $vm.memory.start_of_opcode_at(pos)
      classes << "instruction"
      if opcode_start == pos
        classes << "instruction_begin" << "instruction_opcode"
      elsif opcode_start + 1 == pos
        classes << "instruction_opcode"
      else
        classes << "instruction_middle"
      end
    end
    classes.join(" ")
    # }
  end

  def send_tick_payload
    {
      pc: $exe.pc,
      dirty_memory: $exe.dirty_memory.map{|r| r[0..1] },
      cpu: haml(:cpu, layout: false, locals: {vm: $vm, exe: $exe})
    }
  end


  def render_memory(range)

  end



end

VmHost.run!

