# encoding: UTF-8

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

  def render_main
    @last_tick_times = [-1] if @last_tick_times.size == 0
    [ 200, {'Content-Type' => 'text/html'}, [render_main_body {
      
    }] ]
  end

  def render_main_body
    template do
      <<-HTML
        <div class="row">

          <div class="span3 well current_instruction">
            <h2>Current instruction</h2>
            <span class="opcode">#{hex(@vm.opcode)}</span>
            #{@vm.args.map {|(data_type,value)| %(
              <span class="data_type">#{hex(data_type)}</span>
              <span class="value">#{hex(value)}</span>
            )}.join("\n")}
          </div>

          <div class="span2 well threads">
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
          </div>

          <div class="span6 well memory">
            <h2>Memory</h2>
            #{memory_view(20,8,43808,true)}
          </div>
        </div>
      HTML
    end
  end

  def template(&block)
    template_value = ""
    @template_time = Benchmark.measure { template_value = yield }.real
    <<-HTML
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>gta3-mission-script-vm</title>

          <!-- Le styles -->
          <link href="http://twitter.github.com/bootstrap/assets/css/bootstrap.css" rel="stylesheet">
          <link href="http://twitter.github.com/bootstrap/assets/css/bootstrap-responsive.css" rel="stylesheet">
          <link href="http://twitter.github.com/bootstrap/assets/css/docs.css" rel="stylesheet">
          <link href="http://twitter.github.com/bootstrap/assets/js/google-code-prettify/prettify.css" rel="stylesheet">

          <style>
            .opcode    { color: #5BB75B; }
            .data_type { color: #49AFCD; }
            .value     { color: #0074CC; }

            .memory table { font-family: monospace; }
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
          </style>
        </head>

        <body>

          <div class="navbar navbar-fixed-top">
            <div class="navbar-inner">
              <div class="container">
                <a class="brand" href="./index.html">gta3-mission-script-vm</a>
                <div class="nav-collapse collapse">
                  <ul class="nav">
                  </ul>
                </div>
              </div>
            </div>
          </div>

          <div class="row">
            <form action="/tick" method="get" class="form-inline well span3">
              <label>Number of ticks</label>
              <input name="ticks" value="1" type="text" class="span1" />
              <button type="submit" class="btn">Tick!</button>
            </form>
            <form action="/reset" method="get" class="form-inline well span1">
              <button type="submit" class="btn btn-danger">Reset</button>
            </form>
            #{process_stats_view}
          </div>

          #{last_exception_view if @last_exception}

          #{template_value}

          <div class="row footer">
            scm
          </div>

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
      puts row.inspect
      puts empty_row.inspect
      next if skip_empties && row == empty_row
      row_address = start_at + (index * cols)
      mem_hex = row.map.each_with_index{ |b,i|
        s = ""
        address = row_address + i

        if @vm.allocations[address]
          tag_open = %(<a class="allocated address_#{address} data_type_#{@vm.allocations[address][0]} allocation_id_#{@vm.allocations[address][1]}" href="#">)
          bytes_left = Vm::TYPE_SIZES[ @vm.allocations[address][0] ]
          s << tag_open
        elsif i == 0 && bytes_left > 0
          s << tag_open
        end

        bytes_left -= 1
        s << hex(b)

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

  def process_stats_view
    <<-HTML
      <div class="well span2">
        <dl>
          <dt>Process memory</dt>
          <dd>#{@total_memory}kb</dd>
          <dt>Template</dt>
          <dd>#{"%.6f" % @template_time} sec</dd>
          <dt>Ticks</dt>
          <dd>#{"%.6f" % (@last_tick_times.inject(:+) / @last_tick_times.size.to_f)} sec avg, x #{@last_tick_times.size}</dd>

        </dl>
      </div>
    HTML
  end

  def hex(array_of_bytes)
    array_of_bytes = [array_of_bytes] unless array_of_bytes.is_a?(Array)
    array_of_bytes = array_of_bytes.map { |b| b.ord } if array_of_bytes.first.is_a?(String)
    array_of_bytes.map{|m| m.to_s(16).rjust(2,"0") rescue "--" }.join(" ")
  end
end
