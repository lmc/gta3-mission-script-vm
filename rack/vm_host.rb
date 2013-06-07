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
    Instrumentation.instrument {
    haml :inspect, layout: false, locals: {pos: params[:pos].to_i, vm: $vm}
    }
  end

  def send_tick_payload
    {
      pc: $exe.pc,
      dirty_memory: $exe.dirty_memory,
      cpu: haml(:cpu, layout: false, locals: {vm: $vm, exe: $exe})
    }
  end


  def render_memory(range)

  end



end

VmHost.run!

