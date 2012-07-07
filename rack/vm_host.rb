# encoding: UTF-8

class VmHost
  def initialize(vm)
    @vm = vm
    @last_tick_times = []
    @last_exception = nil
  end

  def tick(ticks = 1)
    @last_exception = nil
    ticks.times do
      @last_tick_times << Benchmark.measure do
        @vm.tick!
      end.real
    end
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

          <div class="span3 current_instruction">
            <h2>Current instruction</h2>
            <span class="opcode">#{hex(@vm.opcode)}</span>
            #{@vm.args.map {|(data_type,value)| %(
              <span class="data_type">#{hex(data_type)}</span>
              <span class="value">#{hex(value)}</span>
            )}.join("\n")}
          </div>

          <div class="span2 threads">
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

          <div class="span6 memory">
            <h2>Memory</h2>
            #{memory_view(20,8,43808)}
          </div>
        </div>
      HTML
    end
  end

  def template(&block)
    template_value = ""
    template_time = Benchmark.measure { template_value = yield }.real
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
            .opcode    { color: #99ff6f; }
            .data_type { color: #ff6ffd; }
            .value     { color: #9ed5ff; }

            .memory .address { width: 3em; text-align: right; padding-right: 1em; }

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
          </div>

          <div>Template: #{"%.6f" % template_time} sec</div>
          <div>Ticks: #{@last_tick_times.size}, Average: #{"%.6f" % (@last_tick_times.inject(:+) / @last_tick_times.size.to_f)} sec</div>
          <div>#{@last_tick_times.inspect}</div>

          #{last_exception_view if @last_exception}

          #{template_value}

          <div class="row footer">
            scm
          </div>

        </body>
      </html>

    HTML
  end

  def memory_view(cols = 32,start_at = 8,end_at = 43808)
    str = "<table><tbody>"
    @vm.memory[start_at...end_at].each_slice(cols).each_with_index do |row,index|
      address = start_at + (index * cols)
      str << %(
        <tr>
          <td class="address">#{address}</td>
          <td>#{hex(row)}</td>
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
