#! /usr/bin/env ruby
# (($: << "./lib") && load("lib/gta3vm.rb") && Gta3Vm::Vm.new_for_gta3.disassemble && exit)
(($: << "./lib") && load("lib/gta3vm.rb") && Gta3Vm::Vm.new_for_vc.execute{|exe| exe.load_state_from_save(File.open('GTAVCsf3.b')) } && exit)