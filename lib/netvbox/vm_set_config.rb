require 'csv'
require 'netvbox/vm'

module NetVbox
  class VmSetConfig
    def initialize(config_file_path)
      @config_file_path = config_file_path
    end

    def get_all_vm_info
      all_vm_info = []
      if File.readable?(@config_file_path)
        CSV.foreach(@config_file_path) do |row|
          all_vm_info << a_to_vm_info(row)
        end
      end
      all_vm_info
    end

    def add_vm(vm_info)
      all_vm_info = get_all_vm_info
      all_vm_info.index(vm_info).nil? ? write_vm_info(all_vm_info << vm_info) : false
    end

    def remove_vm(vm_info)
      all_vm_info = get_all_vm_info
      updated_vm_info = all_vm_info.select {|i| !(i === vm_info)}
      all_vm_info != updated_vm_info ? write_vm_info(updated_vm_info) : false
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
        true
      rescue IOError
        puts "ERROR: Could not write vm info to #{@config_file_path}"
        return false
      end
    end
  end
end
