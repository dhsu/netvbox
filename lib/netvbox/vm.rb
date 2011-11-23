require 'net/ssh'

module NetVbox

  class SshConnectionInfo
    attr_reader :hostname, :username, :password

    def initialize(hostname, username, password)
      @hostname = hostname
      @username = username
      @password = password
    end

    def ==(other)
      self === other &&
      self.password == other.password
    end

    def ===(other)
      self.hostname == other.hostname &&
      self.username == other.username      
    end
  end

  class VmInfo
    attr_reader :ssh_connection_info, :vm_name, :snapshot_name

    def initialize(ssh_connection_info, vm_name, snapshot_name)
      @ssh_connection_info = ssh_connection_info
      @vm_name = vm_name
      @snapshot_name = snapshot_name
    end

    def ==(other)
      self.ssh_connection_info == other.ssh_connection_info &&
      self.vm_name == other.vm_name &&
      self.snapshot_name == other.snapshot_name
    end

    def ===(other)
      self.ssh_connection_info === other.ssh_connection_info &&
      self.vm_name == other.vm_name &&
      self.snapshot_name == other.snapshot_name      
    end
  end

  class Vm
    attr_reader :vm_info

    def initialize(vm_info)
      @vm_info = vm_info
    end

    def status
      vm_state = showvminfo('VMState')
      case vm_state
      when 'running'
        'running'
      when 'saved'
        'not running (saved)'
      when 'poweroff'
        'not running (power off)'
      when 'aborted'
        'not running (aborted)'
      else
        vm_state
      end
    end

    def poweroff
      if showvminfo('VMState') == 'running'
        my_ssh do |ssh|
          ssh.exec!("VBoxManage controlvm \"#{@vm_info.vm_name}\" poweroff").strip
        end
      else
        "#{@vm_info.vm_name} is not running"
      end
    end

    def load_snapshot
      return "ERROR: you must disable 3d acceleration for #{@vm_info.vm_name}" if showvminfo('accelerate3d') == 'on'
      poweroff
      my_ssh do |ssh|
        ssh.exec!("VBoxManage snapshot \"#{@vm_info.vm_name}\" restore \"#{@vm_info.snapshot_name}\" && VBoxManage startvm \"#{@vm_info.vm_name}\" --type headless")
      end
    end

    private

    def showvminfo(var_name)
      my_ssh do |ssh|
        ssh.exec!("VBoxManage showvminfo \"#{@vm_info.vm_name}\" --machinereadable | grep ^#{var_name}= | cut -d '\"' -f 2").strip
      end
    end

    def my_ssh
      ssh_info = @vm_info.ssh_connection_info
      begin
        # can raise SocketError or Net::SSH::AuthenticationFailed
        Net::SSH.start(ssh_info.hostname, ssh_info.username, :password => ssh_info.password) do |ssh|
          return yield ssh
        end
      rescue SocketError
        return 'Connection Error'
      rescue Net::SSH::AuthenticationFailed
        return 'Authentication Error'
      end
    end
  end
end
