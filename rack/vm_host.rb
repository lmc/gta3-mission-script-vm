# encoding: UTF-8
require "json"

class VmHost
  def initialize(vm)
    @vm = vm
    @last_tick_times = []
    @last_exception = nil

    @memory_starts_at = 8
    @memory_view_width = 24
    @variable_labels = begin
      labels = {}
      File.read("data/vc/CustomVariables.ini").each_line do |line|
        next unless line =~ /\A;?(\d+)=(.+)/
        var_no, label = *line.scan(/\A;?(\d+)=(.+)/)[0]
        address = @memory_starts_at + ((var_no.to_i - 2) * 4)
        labels[address] = label
      end
      labels
    end
  end

  def tick(ticks = 1)
    @last_exception = nil
    @original_memory = `ps -o rss= -p #{Process.pid}`.to_i 
    ticks.times do
      @last_tick_times << Benchmark.measure do
        @vm.tick!
      end.real
    end
    @total_memory = `ps -o rss= -p #{Process.pid}`.to_i
  rescue => ex
    @last_exception = ex
  end

  # record dirty state of VM
  # threads (always)
  # memory (detect write calls)
  # game objects (maybe? state on vm, seperate state on vmhost?)
  # map? (same as game objects?)
  def render_main
    @total_memory = `ps -o rss= -p #{Process.pid}`.to_i
    @last_tick_times = [-1] if @last_tick_times.size == 0
    [ 200, {'Content-Type' => 'text/html'}, [render_main_body {
      
    }] ]
  end

  def render_main_body
    template
  end

  def render_json
    segments = [:stats,:current_instruction]
    segments += @vm.dirty.select { |k,v| v == true }.keys
    response = {
      segments: Hash[ segments.map { |segment| [segment,send("render_#{segment}")] } ],
      dirty_memory_addresses: render_json_dirty_memory_addresses
    }
    [200, {"Content-Type" => "application/json"}, [response.to_json]]
  end
  def render_json_dirty_memory_addresses
    @vm.dirty_memory_addresses.map do |address|
      row_address = address - (address % @memory_view_width)
    end.uniq.map do |row_address|
      [row_address,memory_view(@memory_view_width,row_address,row_address+@memory_view_width-1,false)]
    end
  end

  def render_vm_controls
    <<-HTML
      <form action="/tick" method="get" class="form-inline" id="tick_form">
        <table class="ticks_time table table-bordered table-condensed">
          <tr>
            <th>Ticks</th>
            <td>#{@vm.tick_count}</td>
            <td><input name="ticks" value="1" type="text" class="span1" /></td>
          </tr>
          <tr>
            <th>Time</th>
            <td>#{@vm.time}</td>
            <td> </td>
          </tr>
        </table>

        <table class="branch_conditions table table-bordered table-condensed">
          <tr>
            <th>Branch Conds</th>
            <td>#{@vm.branch_conditions.inspect}</td>
          </tr>
        </table>
        
        <button type="submit" class="btn">Tick</button>
      </form>

      <form action="/reset" method="get" class="form-inline">
        <button type="submit" class="btn btn-danger">Reset</button>
      </form>
    HTML
  end

  def render_stats
    <<-HTML
      <dl>
        <dt>Process memory</dt>
        <dd>#{@total_memory}kb</dd>
        <dt>Ticks</dt>
        <dd>#{"%.6f" % (@last_tick_times.inject(:+) / @last_tick_times.size.to_f)} sec avg, x #{@last_tick_times.size}</dd>
      </dl>
    HTML
  end

  def render_current_instruction
    <<-HTML
      <table class="table table-bordered table-condensed">
        <tr>
          <th>Bytecode</th>
          <td class="opcode"><span class="opcode">#{hex(@vm.opcode)}</span></td>
          #{@vm.args.inject("") {|str,(data_type,value)| str << %(
            <td>
              <span class="data_type">#{hex(data_type)}</span>
              <span class="value">#{hex(value)}</span>
            </td>
          )}}
        </tr>
        <tr>
          <th>Disassembled</th>
          <td class="opcode"><span class="opcode">#{Opcodes.definitions[@vm.opcode][:nice] rescue "--"}</span></td>
          #{@vm.args.inject("") {|str,(data_type,value)|
          attrs = ""
          value = format_arg(data_type,value)
          if data_type == TYPE_SHORTHANDS[:pg_if]
            attrs << %(href="#" class="hl_address hl_address_#{value}")
          end
          str << %(
            <td #{attrs}>
              <a>
                #{value}
              </a>
            </td>
          )}}
        </tr>
        <tr>
          <th>Handled As</th>
          <td class="opcode"><span class="opcode">#{Opcodes.definitions[@vm.opcode][:sym_name] rescue "--"}</span></td>
          #{@vm.args.each_with_index.inject("") {|str,((data_type,value),index)|
          str << %(
            <td>
              <a>
                <span class="data_type">#{Opcodes.definitions[@vm.opcode][:args_types][index]}</span>
                <span class="value">#{Opcodes.definitions[@vm.opcode][:args_names][index]}</span>
              </a>
            </td>
          )}}
        </tr>
      </table>
    HTML
  end

  def render_threads
    <<-HTML
      <div style="width:50000px">
      <table class="threads_table">
        <tr>
        #{ @vm.thread_pcs.each_with_index.map { |thread_pc,thread_id|
          classes = []
          classes << "current" if thread_id == @vm.thread_id
          %(
            <td class="thread">
              <h2>#{thread_id} #{@vm.thread_names[thread_id]}</h2>

              <h2>Local Vars</h2>
              <table class="local_vars">
              </table>

              <h2>PC</h2>
              #{thread_pc}
            </td>
        )}.join("\n")}
        </tbody>
      </table>
      </div>
    HTML
  end

  #memory_view(24,8,34336,true)
  def render_memory
    <<-HTML
      #{memory_view(24,0,@vm.struct_positions[:memory][1],false)}
    HTML
  end

  def render_game_objects
    <<-HTML
      <table class="table table-condensed table-bordered">
        <tr>
          <th>Addr</th>
          <th>ID</th>
          <th>Object</th>
          <th></th>
        </tr>
        #{@vm.game_objects.each_pair.inject("") { |str,(address,object)|
          alloc_data = @vm.allocations[address]
          data = object.map_render_args
          str << %(
            <tr class="meta game_object_#{alloc_data[1]} hl_address hl_address_#{address} hl_render" data-render-type="#{data[0]}" data-render-args="#{data[1].to_json}">
              <td class="address">#{address}</td>
              <td class="allocation_id">#{alloc_data[1]}</td>
              <td class="allocated_as">#{alloc_data[2].name} #{alloc_data[1]}</td>
              <td class="inspect">#{h object.inspect}</td>
            </tr>
          )
        }}
      </table>
    HTML
  end

  def format_arg(data_type,value)
    if data_type == 0x00
      "[end of args]"
    else
      arg = @vm.arg_to_native(data_type,value)
      if arg.is_a?(Float)
        "%.5f" % arg
      else
        arg.inspect
      end
    end
  rescue
    h(value.inspect)
  end

  def h(str)
    CGI.escape_html(str)
  end

  def template(&block)
    template_value = block_given? ? yield : ""
    <<-HTML
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>gta3-mission-script-vm</title>

          <link href="/stylesheets/bootstrap.css" rel="stylesheet">
          <link href="/stylesheets/bootstrap-responsive.css" rel="stylesheet">
          <link href="/stylesheets/vm_host.css" rel="stylesheet">

          <script type="text/javascript">
            var dt_shorthands = #{Vm::TYPE_SHORTHANDS.invert.to_json};
            var variable_labels = #{@variable_labels.to_json};
          </script>
          <script type="text/javascript" src="/javascripts/jquery.js"></script>
          <script type="text/javascript" src="/javascripts/bootstrap-tooltip.js"></script>
          <script type="text/javascript" src="/javascripts/bootstrap-popover.js"></script>
          <script type="text/javascript" src="/javascripts/jquery.scrollTo-1.4.2-min.js"></script>
          <script type="text/javascript" src="/javascripts/vm_host.js"></script>
        </head>

        <body>

          <div class="column span4">
            <div class="well span4">
              <h1>VM</h1>
              <div id="vm_controls">
                #{render_vm_controls}
              </div>
            </div>
            <div class="well span4 game_state">
              <h1>GS</h1>
              <div id="segment_stats">
                #{render_stats}
              </div>
            </div>
          </div>

          <div class="column span4 offset1 well threads">
            <h1>Threads</h1>
            <div class="threads_holder span4" id="segment_threads">
              #{render_threads}
            </div>
          </div>

          <div class="row memory_game_objects_current_instruction">
            <div class="row">
              <div class="column span9 well memory">
                <h1>Memory</h1>
                <div>
                  <table><tbody id="segment_memory">
                    #{render_memory}
                  </tbody></table>
                </div>
              </div>

              <div class="column span9 well game_objects">
                <h1>Game objects</h1>
                <div id="segment_game_objects">
                  #{render_game_objects}
                </div>
              </div>
            </div>

            <div class="row">
              <div class="span22 well current_instruction">
                <h1>Instruction</h1>
                <div id="segment_current_instruction">
                  #{render_current_instruction}
                </div>
              </div>
            </div>
          </div>

        </body>
      </html>

    HTML
  end

  # TODO:
  # mark each row of memory as dirty
  # load in memory initially over ajax to avoid lag
  # update memory over ajax, only when row is dirty
  def memory_view(cols = nil,start_at = 8,end_at = 43808,skip_empties = false)
    cols = @memory_view_width
    str = ""
    puts Benchmark.measure {
    tag_open = ""
    bytes_left = -1
    empty_row = Array.new(cols,0)
    mem_address = start_at
    row_index = 0
    while mem_address <= end_at
      #row = @vm.memory[mem_address..(mem_address+cols)]
      row = @vm.memory.raw_read(mem_address...(mem_address+cols))
      next if skip_empties && row == empty_row
      row_address = start_at + (row_index * cols)
      mem_hex = ""
      str << %(<tr class="memory_row_address_#{row_address}"><td class="address">#{row_address}</td><td>)
      row.bytes.each_with_index{ |b,i|
        address = row_address + i

        if @vm.allocations[address]
          #bytes_left = Vm::TYPE_SIZES[ @vm.allocations[address][0] ]
          bytes_left = 4 # vars in memory are always 32-bit ints/floats?
          classes = "allocated hl_address hl_address_#{address} data_type_#{@vm.allocations[address][0]} allocation_id_#{@vm.allocations[address][1]}"
          bytes = @vm.read(address,bytes_left)
          native = @vm.arg_to_native(@vm.allocations[address][0],bytes)
          tag_open = %(<a class="#{classes}" href="#" data-native="#{native}" data-bytes="#{hex(bytes)}" data-data_type="#{@vm.allocations[address][0]}" data-allocation_id="#{@vm.allocations[address][1]}" data-address="#{address}">)
          str << tag_open
        elsif i == 0 && bytes_left > 0
          str << tag_open
        end

        bytes_left -= 1
        str << %(<span class="address_#{address}">) << hex(b) << %(</span>)

        if bytes_left == 0 || bytes_left > 0 && i == cols-1
          str << "</a>"
        end

        str << " "
      }
      str << %(</td></tr>\n)
      mem_address += cols
      row_index += 1
    end
    }
    str
  end

  def last_exception_view
    cleaned_backtrace = @last_exception.backtrace.reject{|l| l =~ %r{/gems/(rack|thin)\-} }
    <<-HTML
      <div class="alert alert-error">
        <h1>#{@last_exception.class.name}</h1>
        <h2>#{@last_exception.message}</h2>
        <div class="backtrace">#{cleaned_backtrace.join("<br />\n")}</div>
      </div>
    HTML
  end

  def hex(array_of_bytes)
    array_of_bytes = [array_of_bytes] unless array_of_bytes.is_a?(Array)
    array_of_bytes = array_of_bytes.map { |b| b.ord } if array_of_bytes.first.is_a?(String)
    array_of_bytes.map{|m| m.to_s(16).rjust(2,"0") rescue "--" }.join(" ")
  end
end
