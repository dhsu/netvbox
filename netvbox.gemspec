# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "netvbox/version"

Gem::Specification.new do |s|
  s.name        = 'netvbox'
  s.version     = NetVbox::VERSION
  s.homepage    = 'https://github.com/dhsu/netvbox'
  s.summary     = 'Limited remote admin of VirtualBox VMs through ssh'
  s.authors     = ['Dennis Hsu']
  s.email       = ['hsu.dennis@gmail.com']

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "net-ssh"
end
