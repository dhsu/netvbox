require 'netvbox/vm'
require 'netvbox/vm_set_config'

module NetVbox
  class VmSet
    def initialize(vm_set_config)
      @vm_set_config = vm_set_config
    end

    def config
      @vm_set_config
    end

    def load_snapshots
      threads = []
      get_vms.each do |vm|
        threads << Thread.new(vm) {|vm| vm.load_snapshot}
      end
      threads.each(&:join)
    end

    def poweroff_all
      threads = []
      get_vms.each do |vm|
        threads << Thread.new(vm) {|vm| vm.poweroff}
      end
      threads.each(&:join)
    end

    def add_vm(hostname, username, password, vm_name, snapshot_name)
      vm_info = VmInfo.new(SshConnectionInfo.new(hostname, username, password), vm_name, snapshot_name)
      @vm_set_config.add_vm(vm_info)
    end

    def remove_vm(hostname, username, vm_name)
      @vm_set_config.remove_vm(hostname, username, vm_name)
    end

    # return Hash of VmInfo to status
    def all_status
      status_map = {}
      threads = []
      get_vms.each do |vm|
        threads << Thread.new(vm) {|vm| status_map[vm.vm_info] = vm.status}
      end
      threads.each(&:join)
      status_map
    end

    # return Hash of VmInfo to (vm ip or :ip_unavailable)
    def all_ips
      ip_map = {}
      threads = []
      get_vms.each do |vm|
        threads << Thread.new(vm) do |vm|
          begin
            ip_map[vm.vm_info] = vm.vm_ip
          rescue
            ip_map[vm.vm_info] = :ip_unavailable
          end
        end
      end
      threads.each(&:join)
      ip_map
    end

    # return Hash of VmInfo to output of command
    def ssh_hosts(command)
      output_map = {}
      threads = []
      get_vms.each do |vm|
        threads << Thread.new(vm) {|vm| output_map[vm.vm_info] = vm.ssh_host(command)}
      end
      threads.each(&:join)
      output_map
    end

    # return Hash of VmInfo to output of command
    def ssh_guests(username, pw, command)
      output_map = {}
      threads = []
      get_vms.each do |vm|
        threads << Thread.new(vm) {|vm| output_map[vm.vm_info] = vm.ssh_guest(username, pw, command)}
      end
      threads.each(&:join)
      output_map
    end

    private

    def get_vms
      @vm_set_config.all_vm_info.collect {|vm_info| Vm.new(vm_info)}
    end
  end
end
