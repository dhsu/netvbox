require 'netvbox/vm'
require 'netvbox/vm_set_config'

module NetVbox
  class VmSet
    def initialize(vm_set_config)
      @vm_set_config = vm_set_config
    end

    def print_status
      puts 'Getting status info...'
      threads = []
      get_vms.each do |vm|
        threads << Thread.new(vm) {|vm| puts "#{vm.vm_info.vm_name} on #{vm.vm_info.ssh_connection_info.hostname}... #{vm.status}"}
      end
      threads.each(&:join)
      puts 'There are no vms' if threads.empty?
    end

    def load_snapshots
      puts 'Loading snapshots...'
      threads = []
      get_vms.each do |vm|
        threads << Thread.new(vm) {|vm| vm.load_snapshot}
      end
      threads.each(&:join)
      print_status
    end

    def poweroff_all
      puts 'Powering off vms...'
      threads = []
      get_vms.each do |vm|
        threads << Thread.new(vm) {|vm| vm.poweroff}
      end
      threads.each(&:join)
      print_status
    end

    def list_vms
      all_vm_info = @vm_set_config.get_all_vm_info
      all_vm_info.each do |vm_info|
        ssh_info = vm_info.ssh_connection_info
        puts "#{ssh_info.username}@#{ssh_info.hostname} - vm: #{vm_info.vm_name}, snapshot: #{vm_info.snapshot_name}"
      end
      puts 'There are no vms' if all_vm_info.empty?
    end

    def add_vm(hostname, username, password, vm_name, snapshot_name)
      vm_info = VmInfo.new(SshConnectionInfo.new(hostname, username, password), vm_name, snapshot_name)
      if @vm_set_config.add_vm(vm_info)
        puts "Successfully added vm (#{vm_name}, #{snapshot_name})"
      else
        puts "Failed to add vm (#{vm_name}, #{snapshot_name})"
      end
    end

    def remove_vm(hostname, username, vm_name, snapshot_name)
      vm_info = VmInfo.new(SshConnectionInfo.new(hostname, username, nil), vm_name, snapshot_name)
      if @vm_set_config.remove_vm(vm_info)
        puts "Successfully removed vm (#{vm_name}, #{snapshot_name})"
      else
        puts "Failed to remove vm (#{vm_name}, #{snapshot_name})"
      end
    end

    private

    def get_vms
      @vm_set_config.get_all_vm_info.collect {|vm_info| Vm.new(vm_info)}
    end
  end
end
