require 'netvbox/printing_delegator'
require 'highline/import'

module NetVbox
  class WizardDelegator
    def initialize(printing_delegator)
      @printing_delegator = printing_delegator
    end

    def add_vm
      hostname = get_value 'Enter hostname of VM host: '
      username = get_value 'Enter ssh username: '
      pw = get_password 'Enter ssh password: '
      vm_name = get_value 'Enter VM name: '
      snapshot_name = get_value 'Enter snapshot name: '
      @printing_delegator.add_vm(hostname, username, pw, vm_name, snapshot_name)
    end

    def remove_vm
      hostname = get_value 'Enter hostname of VM host: '
      username = get_value 'Enter ssh username: '
      vm_name = get_value 'Enter VM name: '
      @printing_delegator.remove_vm(hostname, username, vm_name)
    end

    def create_set
      set_name = get_value 'Enter set name: '
      @printing_delegator.create_set set_name
    end

    def remove_set
      set_name = get_value 'Enter set name: '
      @printing_delegator.remove_set set_name
    end

    def use_set
      set_name = get_value 'Enter set name: '
      @printing_delegator.use_set set_name
    end

    private

    def get_value(prompt)
      input = ''
      while input.empty?
        print prompt
        input = STDIN.gets.chomp
        puts 'Cannot be blank' if input.empty?
      end
      input
    end

    def get_password(prompt)
      pw = ''
      while pw.empty?
        pw = ask(prompt) {|q| q.echo = false}
        puts 'Cannot be blank' if pw.empty?
      end
      pw
    end
  end
end
