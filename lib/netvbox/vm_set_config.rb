require 'csv'
require 'netvbox/vm'

module NetVbox
  class VmSetConfig
    def initialize(config_file_path)
      @config_file_path = config_file_path
    end

    def all_vm_info
      all_vm_info = []
      if File.readable?(@config_file_path)
        CSV.foreach(@config_file_path) {|row| all_vm_info << a_to_vm_info(row)}
      else
        raise "Could not read file: #{@config_file_path}"
      end
      all_vm_info
    end

    def add_vm(vm_info)
      all = all_vm_info
      if all.detect {|i| i.clashes_with? vm_info}.nil?
        write_vm_info(all << vm_info)
      else
        raise "The VM, #{vm_info.vm_name}, is already under management"
      end
    end

    def remove_vm(hostname, username, vm_name)
      all = all_vm_info
      updated = all.select {|i| !i.clashes_with_params?(hostname, username, vm_name)}
      if all != updated      
        write_vm_info(updated)
      else
        raise "The VM, #{vm_name}, is not under management"
      end
    end

    private

    def vm_info_to_a(vm_info)
      a = []
      a << vm_info.ssh_connection_info.hostname
      a << vm_info.ssh_connection_info.username
      a << vm_info.ssh_connection_info.password
      a << vm_info.vm_name
      a << vm_info.snapshot_name
      a
    end

    def a_to_vm_info(a)
      VmInfo.new(SshConnectionInfo.new(a[0], a[1], a[2]), a[3], a[4])
    end

    def write_vm_info(all_vm_info)
      begin
        CSV.open(@config_file_path, "w") do |csv|
          all_vm_info.each {|vm_info| csv << vm_info_to_a(vm_info)}
        end
      rescue IOError
        raise "Could not write vm info to #{@config_file_path}"
      end
    end
  end
end
