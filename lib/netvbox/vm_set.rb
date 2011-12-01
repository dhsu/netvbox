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

    def remove_vm(hostname, username, vm_name, snapshot_name)
      vm_info = VmInfo.new(SshConnectionInfo.new(hostname, username, nil), vm_name, snapshot_name)
      @vm_set_config.remove_vm(vm_info)
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

    private

    def get_vms
      @vm_set_config.all_vm_info.collect {|vm_info| Vm.new(vm_info)}
    end
  end
end
