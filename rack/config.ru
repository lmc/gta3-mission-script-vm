#\ -w -p 8765
load "./lib/vm.rb"
require 'cgi'
require 'benchmark'
#use Rack::Reloader, 0
use Rack::ContentLength

def reload!(vm)
  load "./rack/vm_host.rb"
  VmHost.new(vm)
end

@vm = Vm.load_scm("main")
@vm.tick!

app = proc do |env|
  @vm_host = reload!(@vm)
  case env["REQUEST_URI"]
  when %r(\A/tick)
    ticks = env["QUERY_STRING"].scan(/ticks=(\d+)/)[0][0].to_i rescue 1
    @vm_host.tick(ticks)
    @vm_host.render_main
  when %r(\A/reset)
    @vm = Vm.load_scm("main")
    @vm.tick!
  when %r(\A/\Z)
    @vm_host.render_main
  when %(\A/favicon.ico)
    [404,{"Content-Type" => "text/plain"},[]]
  else
    [404,{"Content-Type" => "text/plain"},[]]    
  end
end

run app
