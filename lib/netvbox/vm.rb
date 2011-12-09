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
      self.hostname == other.hostname &&
      self.username == other.username &&
      self.password == other.password
    end
  end

  class VmInfo
    attr_reader :ssh_connection_info, :vm_name, :snapshot_name

    def initialize(ssh_connection_info, vm_name, snapshot_name)
      @ssh_connection_info = ssh_connection_info
      @vm_name = vm_name
      @snapshot_name = snapshot_name
    end

    def clashes_with?(other)
      clashes_with_params?(other.ssh_connection_info.hostname, other.ssh_connection_info.username, other.vm_name)
    end

    def clashes_with_params?(hostname, username, vm_name)
      self.ssh_connection_info.hostname == hostname &&
      self.ssh_connection_info.username == username &&
      self.vm_name == vm_name
    end

    def ==(other)
      self.ssh_connection_info == other.ssh_connection_info &&
      self.vm_name == other.vm_name &&
      self.snapshot_name == other.snapshot_name
    end

    def to_s
      "host: #{self.ssh_connection_info.hostname}, vm: #{vm_name}, snapshot: #{snapshot_name}"
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
        my_ssh {|ssh| ssh.exec!("VBoxManage controlvm \"#{@vm_info.vm_name}\" poweroff").strip}
      end
    end

    def load_snapshot
      # VMs with 3D acceleration cannot be started remotely
      # TODO: propogate this info to a log or some output to notify user
      return if showvminfo('accelerate3d') == 'on'
      poweroff
      command = "VBoxManage snapshot \"#{@vm_info.vm_name}\" restore \"#{@vm_info.snapshot_name}\" && VBoxManage startvm \"#{@vm_info.vm_name}\" --type headless"
      my_ssh {|ssh| ssh.exec! command}
    end

    def ssh_host(command)
      my_ssh {|ssh| ssh.exec! command} || ''
    end

    def ssh_guest(username, pw, command)
      begin
        hostname = vm_ip
      rescue
        return 'Guest VM IP unavailable'
      end
      ssh_info = SshConnectionInfo.new(hostname, username, pw)
      my_ssh(ssh_info) {|ssh| ssh.exec! command} || ''
    end

    def vm_ip
      command = "VBoxManage guestproperty get \"#{@vm_info.vm_name}\" /VirtualBox/GuestInfo/Net/0/V4/IP"
      out = my_ssh {|ssh| ssh.exec! command}
      return out['Value:'.length..-1].strip unless (out =~ /^Value:/).nil?
      raise "Cannot get IP for #{@vm_info.vm_name}: #{out}"
    end

    private

    def showvminfo(var_name)
      command = "VBoxManage showvminfo \"#{@vm_info.vm_name}\" --machinereadable | grep ^#{var_name}= | cut -d '\"' -f 2"
      my_ssh {|ssh| ssh.exec!(command).strip}
    end

    def my_ssh(ssh_info=@vm_info.ssh_connection_info)
      begin
        # can raise SocketError or Net::SSH::AuthenticationFailed
        Net::SSH.start(ssh_info.hostname, ssh_info.username, :password => ssh_info.password) {|ssh| return yield ssh}
      rescue SocketError
        return 'connection error'
      rescue Net::SSH::AuthenticationFailed
        return 'authentication error'
      rescue => e
        return e.message
      end
    end
  end
end
