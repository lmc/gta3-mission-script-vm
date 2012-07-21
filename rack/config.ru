#\ -w -p 8765
load "./lib/vm.rb"
require 'cgi'
require 'benchmark'
#use Rack::Reloader, 0
use Rack::Static, :urls => ["/images","/javascripts","/stylesheets"], :root => "rack/public"
use Rack::ContentLength

should_reload = true

def reload!(vm)
  load "./rack/vm_host.rb"
  VmHost.new(vm)
end

@vm = Vm.load_scm("main-vc")
@vm.tick!

@vm_host = reload!(@vm)

app = proc do |env|
  @vm_host = reload!(@vm) if should_reload
  case env["REQUEST_URI"]
  when %r{/\A/disassembly/(\d+)/(\d+)}
    #TODO: refactor VM so we can easily get disassembly around a specific address (cache? vanilla script doesn't do self-modifying code)
    # UI panels: memory viewer, disassembly viewer, can click on addresses to view in memory viewer, can shift-click to view in disassembly viewer
    # disassembly viewer: show parsed opcode, translated method call
    # memory viewer: use allocations data to show native value on click/hover
    # entity viewer: view emulated entities (like player/pickup/etc), use allocations ids to map values/pointers to entities
    # map viewer: can overlay graphics onto gamemap
  when %r{\A/tick}
    ticks = env["QUERY_STRING"].scan(/ticks=(\d+)/)[0][0].to_i rescue 1
    @vm_host.tick(ticks)
    @vm_host.render_json
  when %r{\A/reset}
    @vm = Vm.load_scm("main")
    @vm.tick!
    @vm_host = VmHost.new(@vm)
    @vm_host.render_main
  when %r{\A/\Z}
    @vm_host.render_main
  when %r{\A/favicon.ico}
    [404,{"Content-Type" => "text/plain"},[]]
  when %r{\A/main.jpg}
    [200,{"Content-Type" => "image/jpeg"},[File.read("./rack/public/main.jpg")]]
  else
    [404,{"Content-Type" => "text/plain"},[]]    
  end
end

run app
