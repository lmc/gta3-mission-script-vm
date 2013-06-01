require 'sinatra'
require 'sinatra/twitter-bootstrap'
require 'haml'
require 'sass'

$: << "#{File.dirname(__FILE__)}/../lib"
require 'gta3vm'

class VmHost < Sinatra::Base

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

  def send_tick_payload
    {
      pc: $exe.pc,
      dirty_memory: $exe.dirty_memory
    }
  end


  def render_memory(range)

  end



end

VmHost.run!

