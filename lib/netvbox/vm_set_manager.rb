require 'fileutils'
require 'netvbox/vm_set_config'
require 'netvbox/vm_set'

module NetVbox
  class VmSetManager
    DEFAULT_VM_SET_NAME = 'default'
    VM_SETS_FOLDER_NAME = 'vm_sets'
    CURRENT_VM_SET_FILENAME = 'current_vm_set'
    VM_SET_EXTENSION = 'vmset'

    def initialize(netvbox_home)
      @netvbox_home = netvbox_home
      FileUtils.mkdir_p "#{@netvbox_home}/#{VM_SETS_FOLDER_NAME}"
      FileUtils.touch vm_set_config_file(DEFAULT_VM_SET_NAME)
      current_vm_file = "#{@netvbox_home}/#{CURRENT_VM_SET_FILENAME}"
      IO.write(current_vm_file, DEFAULT_VM_SET_NAME) unless File.exists?(current_vm_file)
    end

    def exists?(vm_set_name)
      File.exists? vm_set_config_file(vm_set_name)
    end

    def vm_set_names
      Dir.entries("#{@netvbox_home}/#{VM_SETS_FOLDER_NAME}")
         .select {|e| e.end_with?(VM_SET_EXTENSION)}
         .collect {|e| e[0...(-VM_SET_EXTENSION.length - 1)]}
    end

    def current_set_name
      current_vm_file = "#{@netvbox_home}/#{CURRENT_VM_SET_FILENAME}"
      File.readable?(current_vm_file) ? IO.read(current_vm_file) : DEFAULT_VM_SET_NAME
    end

    def current_set
      VmSet.new(VmSetConfig.new("#{current_set_name()}.#{VM_SET_EXTENSION}"))
    end

    def use_default_set
      FileUtils.touch vm_set_config_file(DEFAULT_VM_SET_NAME)
      IO.write("#{@netvbox_home}/#{CURRENT_VM_SET_FILENAME}", DEFAULT_VM_SET_NAME)
    end

    def use_set(vm_set_name)
      if File.exists? vm_set_config_file(vm_set_name)
        IO.write("#{@netvbox_home}/#{CURRENT_VM_SET_FILENAME}", vm_set_name)
      else
        use_default_set()
      end
    end

    def create_set(vm_set_name)
      raise "set: #{vm_set_name} already exists" if exists? vm_set_name
      FileUtils.touch vm_set_config_file(vm_set_name)
    end

    def remove_set(vm_set_name)
      raise "set: #{vm_set_name} does not exist" unless exists? vm_set_name
      raise "cannot remove default set" if vm_set_name == DEFAULT_VM_SET_NAME
      use_default_set if current_set_name == vm_set_name
      File.delete vm_set_config_file(vm_set_name)
    end

    private

    def vm_set_config_file(vm_set_name)
      "#{@netvbox_home}/#{VM_SETS_FOLDER_NAME}/#{vm_set_name}.#{VM_SET_EXTENSION}"
    end
  end
end

