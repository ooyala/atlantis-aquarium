class Executer
  def initialize(cwd = ".")
    @cwd = cwd
  end

  def self.ensure_in_vm(extra_args)
    if !in_vm?
      puts "[33;1mRestarting in VM...[0m"
      args = (ARGV + extra_args).map { |arg| %Q{'"'"'#{arg}'"'"'}}.join(" ")
      system("vagrant ssh aquarium -c 'bin/atlantis-aquarium #{args}'")
      exit $?.exitstatus
    end
  end

  def self.in_vm?
    @@in_vm ||= (`hostname`.chomp == "atlantis-aquarium-vm")
  end

  def run_in_vm!(commands, options = {})
    return if commands.nil?
    msg = options[:msg]
    status = options[:status] || 0
    [commands].flatten.each do |command|
      unless run_in_vm(command)
        next if $?.exitstatus == status
        puts "Error running command: #{command}"
        puts msg if msg
        puts "Status code: #{$?.exitstatus}"
        exit $?.exitstatus
      end
    end
  end

  def run_in_vm(commands)
    raise "BUG: Not running in VM!" unless self.class.in_vm?
    return if commands.nil?
    [commands].flatten.each do |command|
      command = "cd #{@cwd}; #{command}"
      puts "[33;1m#{command}[0m"
      return false unless system(command)
    end
    true
  end

  def capture(command)
    raise "BUG: Not running in VM!" unless self.class.in_vm?
    return `cd #{@cwd}; #{command}`
  end

  def cd(path)
    @cwd += "/#{path}"
    @cwd = path if path[0] == '/'
  end
end
