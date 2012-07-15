# encoding: UTF-8
require "json"

class VmHost
  def initialize(vm)
    @vm = vm
    @last_tick_times = []
    @last_exception = nil
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

  def render_json
    segments = [:stats,:current_instruction]
    segments += @vm.dirty.select { |k,v| v == true }.keys
    response = {
      segments: Hash[ segments.map { |segment| [segment,send("render_#{segment}")] } ]
    }
    [200, {"Content-Type" => "application/json"}, [response.to_json]]
  end

  def render_stats
    <<-HTML
      <div class="well span2">
        <dl>
          <dt>Process memory</dt>
          <dd>#{@total_memory}kb</dd>
          <dt>Ticks</dt>
          <dd>#{"%.6f" % (@last_tick_times.inject(:+) / @last_tick_times.size.to_f)} sec avg, x #{@last_tick_times.size}</dd>
        </dl>
      </div>
    HTML
  end

  def render_current_instruction
    <<-HTML
      <h2>Current instruction</h2>
      <table class="table table-bordered table-condensed">
        <tr>
          <td class="opcode"><span class="opcode">#{hex(@vm.opcode)}</span></td>
          #{@vm.args.inject("") {|str,(data_type,value)| str << %(
            <td>
              <span class="data_type">#{hex(data_type)}</span>
              <span class="value">#{hex(value)}</span>
            </td>
          )}}
        </tr>
        <tr>
          <td class="opcode">#{Opcodes.definitions[@vm.opcode][:sym_name] rescue "--"}</td>
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
      </table>
    HTML
  end

  def render_threads
    <<-HTML
      <h2>Threads</h2>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>ID</th>
            <th>PC</th>
          </tr>
        </thead>
        <tbody>
        #{ @vm.thread_pcs.each_with_index.map { |thread_pc,thread_id|
          classes = []
          classes << "current" if thread_id == @vm.thread_id
          %(
          <tr class="#{classes.join(" ")}">
            <td class="name">#{@vm.thread_names[thread_id]}</td>
            <td class="id">#{thread_id}</td>
            <td class="pc">#{thread_pc}</td>
          </tr>
        )}.join("\n")}
        </tbody>
      </table>
    HTML
  end

  def render_memory
    <<-HTML
      <h2>Memory</h2>
      #{memory_view(16,8,43808,true)}
    HTML
  end

  def render_game_objects
    <<-HTML
      <h2>Game Objects</h2>
      <table class="table table-condensed table-bordered">
        <tr>
          <th>Addr</th>
          <th>ID</th>
          <th>Object</th>
          <th></th>
        </tr>
        #{@vm.game_objects.each_pair.inject("") { |str,(address,object)|
          alloc_data = @vm.allocations[address]
          str << %(
            <tr class="meta game_object_#{alloc_data[1]} hl_address hl_address_#{address}">
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

  def render_main_body
    template do
      <<-HTML
        <div class="row">
          <div class="span10 well current_instruction" id="segment_current_instruction">
            #{render_current_instruction}
          </div>
        </div>
        <div class="row">

          <div class="span2 well threads" id="segment_threads">
            #{render_threads}
          </div>

          <div class="span6 well memory" id="segment_memory">
            #{render_memory}
          </div>

          <div class="span5 well game_objects" id="segment_game_objects">
            #{render_game_objects}
          </div>
        </div>
      HTML
    end
  end

  def template(&block)
    template_value = yield
    <<-HTML
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>gta3-mission-script-vm</title>

          <!-- Le styles -->
          <link href="http://twitter.github.com/bootstrap/assets/css/bootstrap.css" rel="stylesheet">
          <link href="http://twitter.github.com/bootstrap/assets/css/bootstrap-responsive.css" rel="stylesheet">
          <link href="http://twitter.github.com/bootstrap/assets/js/google-code-prettify/prettify.css" rel="stylesheet">
          <script type="text/javascript" src="http://twitter.github.com/bootstrap/assets/js/jquery.js"></script>
          <script type="text/javascript" src="http://twitter.github.com/bootstrap/assets/js/bootstrap-tooltip.js"></script>
          <script type="text/javascript" src="http://twitter.github.com/bootstrap/assets/js/bootstrap-popover.js"></script>
          <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>

          <style>
            body { zoom: 0.5; }

            .hl_address.hover { background-color: #f8f !important; }

            span.opcode    { color: #5BB75B; }
            span.data_type { color: #49AFCD; }
            span.value     { color: #0074CC; }

            .current_instruction table { width: auto; }
            .current_instruction td { font-family: monospace; padding-left: 1em; }
            .current_instruction td.opcode { width: 10em; text-align: right; }

            .memory table tbody { font-family: monospace; display: block; height: 20em; overflow-y: scroll; }
            .memory .address { width: 3em; text-align: right; padding-right: 1em; }
            .memory .allocated   { text-decoration: underline; }
            .memory .data_type_1 { color: #0074CC; }
            .memory .data_type_2 { color: #5BB75B; }
            .memory .data_type_4 { color: #0074CC; }
            .memory .data_type_6 { color: #FAA732; }

            .threads tr { color: #888; }
            .threads tr.current { color: #333; }
            .threads .name { width: 3em; text-align: right; padding-right: 1em;  }
            .threads .id { width: 1em; text-align: left;  padding-right: 1em; }
            .threads .pc {  }

            .game_objects td.address { width: 5em; text-align: right; }
            .game_objects td.allocation_id { width: 3em; }
          </style>
        </head>

        <body>
          <div class="row">
            <form action="/tick" method="get" class="form-inline well span3" id="tick_form">
              <label>Number of ticks</label>
              <input name="ticks" value="1" type="text" class="span1" />
              <button type="submit" class="btn">Tick!</button>
            </form>
            <form action="/reset" method="get" class="form-inline well span1">
              <button type="submit" class="btn btn-danger">Reset</button>
            </form>
          </div>

          #{last_exception_view if @last_exception}

          <div class="span12 well" style="position: absolute; top: 0; right: 0">
            <div class="map_holder" style="zoom: 0.2">
              <div class="layers"></div>
              <div class="bg">
                <img src="/main.jpg" width="6000" height="6000"  />
              </div>
            </div>
          </div>

          <div class="row" id="segment_stats">
            #{render_stats}
          </div>

          #{template_value}

          <div class="row footer">
            scm
          </div>

          <script>
            $('#tick_form').submit(function(){
              $.get("/tick",function(response){
                $.each(response.segments,function(segment_id,html){
                  //var element = $('#segment_'+segment_id);
                  var element = document.getElementById("segment_"+segment_id);
                  if(element){
                    element.innerHTML = html;
                  }else{
                    //alert("No element for segment: #segment_"+segment_id);
                    //alert("No element for segment: "+segment_id);
                  }
                })
              })
              return false;
            });

            $('.hl_address').live("mouseover",function(ev){
              var element = ev.target;
              var address = element.className.match(/hl_address_(\\d+)/)[1];
              var matched = $('.hl_address_'+address);
              matched.push(element);
              console.log(matched);
              matched.addClass("hover");
            });

            $('.hl_address').live("mouseout", function(ev){
              var element = ev.target;
              var address = element.className.match(/hl_address_(\\d+)/)[1];
              var matched = $('.hl_address_'+address);
              matched.push(element);
              matched.removeClass("hover");
            });

            var dt_shorthands = #{Vm::TYPE_SHORTHANDS.invert.to_json};
            $('.memory table a.allocated').popover({
              placement: "top",
              title: function(){ return $(this).data("native"); },
              content: function(){
                $this = $(this);
                var data_type = $this.data("data_type");
                var s = "";
                  s += "<dl>";
                  s += "<dt>Data type</dt><dd>"+data_type+" "+dt_shorthands[data_type]+"</dd>";
                  if($this.data("allocation_id")){
                    s += "<dt>Game object</dt><dd>"+$this.data("allocation_id")+"</dd>";
                  }
                  s += "</dl>";
                return s;
              }
            });
          </script>

        </body>
      </html>

    HTML
  end

  def memory_view(cols = 32,start_at = 8,end_at = 43808,skip_empties = false)
    str = "<table><tbody>"
    tag_open = ""
    bytes_left = -1
    empty_row = Array.new(cols,0)
    @vm.memory[start_at...end_at].each_slice(cols).each_with_index do |row,index|
      next if skip_empties && row == empty_row
      row_address = start_at + (index * cols)
      mem_hex = row.map.each_with_index{ |b,i|
        s = ""
        address = row_address + i

        if @vm.allocations[address]
          bytes_left = Vm::TYPE_SIZES[ @vm.allocations[address][0] ]
          classes = "allocated hl_address hl_address_#{address} data_type_#{@vm.allocations[address][0]} allocation_id_#{@vm.allocations[address][1]}"
          bytes = @vm.read(address,bytes_left)
          native = @vm.arg_to_native(@vm.allocations[address][0],bytes)
          tag_open = %(<a class="#{classes}" href="#" data-native="#{native}" data-bytes="#{hex(bytes)}" data-data_type="#{@vm.allocations[address][0]}" data-allocation_id="#{@vm.allocations[address][1]}">)
          s << tag_open
        elsif i == 0 && bytes_left > 0
          s << tag_open
        end

        bytes_left -= 1
        s << %(<span class="address_#{address}">) << hex(b) << %(</span>)

        if bytes_left == 0 || bytes_left > 0 && i == cols-1
          s << "</a>"
        end

        s << " "
      }.join('')
      str << %(
        <tr>
          <td class="address">#{row_address}</td>
          <td>#{mem_hex}</td>
        </tr>
      )
    end
    str << "</tbody></table>"
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
