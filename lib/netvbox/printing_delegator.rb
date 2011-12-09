require 'netvbox/vm_set'
require 'netvbox/vm_set_manager'

module NetVbox
  class PrintingDelegator
    def initialize(vm_set_manager, vm_set)
      @vm_set = vm_set
      @vm_set_manager = vm_set_manager
    end

    def add_vm(hostname, username, password, vm_name, snapshot_name)
      begin
        @vm_set.add_vm(hostname, username, password, vm_name, snapshot_name)
        puts "Added (#{vm_name}, #{snapshot_name}) on host, #{hostname}"
      rescue => e
        puts "Could not add VM snapshot: #{e.message}"
      end
    end

    def list_vms
      all_vm_info = @vm_set.config.all_vm_info
      all_vm_info.each do |vm_info|
        ssh_info = vm_info.ssh_connection_info
        printf "vm: %-36s host: %s\n", "#{vm_info.vm_name} (#{vm_info.snapshot_name})", "#{ssh_info.username}@#{ssh_info.hostname}"
      end
      puts 'No vms' if all_vm_info.empty?
    end

    def list_vm_ips
      puts 'Retrieving VM IP addresses for VMs with guest additions...'
      all_ips = @vm_set.all_ips
      all_ips.each do |vm_info, ip|
        ip_string = (ip == :ip_unavailable) ? 'unavailable' : ip
        printf "%-40s %s\n", "#{vm_info.vm_name} on #{vm_info.ssh_connection_info.hostname}", "[#{ip_string}]"
      end
      puts 'There are no vms' if all_ips.empty?
    end

    def load_snapshots
      puts 'Loading snapshots...'
      @vm_set.load_snapshots
      print_status
    end

    def poweroff_all
      puts 'Powering off VMs...'
      @vm_set.poweroff_all
      print_status
    end

    def remove_vm(hostname, username, vm_name)
      begin
        @vm_set.remove_vm(hostname, username, vm_name)
        puts "Removed #{vm_name} snapshot on host, #{hostname}"
      rescue => e
        puts "Could not remove #{vm_name} snapshot: #{e.message}"
      end
    end

    def print_status
      puts 'Retrieving status info...'
      all_status = @vm_set.all_status
      all_status.each do |vm_info, status|
        printf "%-40s %s\n", "#{vm_info.vm_name} on #{vm_info.ssh_connection_info.hostname}", "[#{status}]"
      end
      puts 'There are no vms' if all_status.empty?
    end

    def create_set(set_name)
      begin
        @vm_set_manager.create_set set_name
        puts "Created set: #{set_name}"
      rescue => e
        puts "Could not create set: #{e.message}"
      end
    end

    def print_current_set
      puts @vm_set_manager.current_set_name
    end

    def list_sets
      @vm_set_manager.vm_set_names.each {|vm_set_name| puts vm_set_name}
    end

    def remove_set(set_name)
      begin
        @vm_set_manager.remove_set set_name
        puts "Removed set: #{set_name}"
      rescue => e
        puts "Could not remove set: #{e.message}"
      end
    end

    def use_default_set
      @vm_set_manager.use_default_set
      puts "Now using set: #{@vm_set_manager.current_set_name}"
    end

    def use_set(set_name)
      begin
        @vm_set_manager.use_set set_name
      rescue => e
        puts "Could not use set: #{e.message}"
      end
      puts "Now using set: #{@vm_set_manager.current_set_name}"
    end
  end
end
