require "fileutils"
require "erb"

class Component
  attr_reader :name, :directory, :repo, :debs, :image_name
  attr_reader :instance
  attr_reader :docker_opts
  attr_reader :precompile, :postcompile
  attr_reader :preimage, :postimage
  attr_reader :prestart, :poststart

  # TODO(edanaher): This is transitional until all components use function for pre/post commands.
  #                 Remove when that transition completes.
  def wrap_in_function(operation)
    if operation.is_a?(Array) || operation.is_a?(String)
      lambda { |executer| executer.run_in_vm!(operation) }
    else
      lambda { |executer| operation.call(self) if operation }
    end
  end

  def initialize(name, options)
    @name = name
    @instance = options[:instance]
    @image_name = options[:image_name] || "aquarium-#{name}"
    @directory = "data/#{options[:directory] || name}"
    @repo = options[:repo] ? "#{ENV["HOME"]}/repos/#{options[:repo]}" : nil
    @debs = options[:debs]
    @docker_opts = options[:docker_opts]
    @precompile = wrap_in_function(options[:precompile])
    @postcompile = wrap_in_function(options[:postcompile])
    @preimage = wrap_in_function(options[:preimage])
    @postimage = wrap_in_function(options[:postimage])
    @prestart = wrap_in_function(options[:prestart])
    @poststart = wrap_in_function(options[:poststart])
    @instances = {nil => self}

    if options[:instances]
      suboptions = options.dup
      suboptions.delete(:instances)
      @instances = Hash[options[:instances].map do |instance, instance_options|
        [instance, Component.new(name, suboptions.merge(instance_options).merge({instance: instance}))]
      end]
    end
  end

  def each_instance(instances)
    if instances.include?("all") || instances.nil? || instances.empty?
      @instances.each { |name, instance| yield instance }
    else
      instances.each do |instance|
        if @instances[instance]
          yield @instances[instance]
        else
          puts "No such instance for #{name}: #{instance}"
        end
      end
    end
  end

  def set_status(status)
    set_value("status", status)
  end

  def set_value(key, value)
    data = {key => value}
    data = {@instance => data} if @instance
    data = {@name => data}
    Status::set(data)
  end

  def self.all
    @@components.values
  end

  def self.[](name, options = {})
    @@components[name]
  end

  def self.names
    @@components.keys
  end

  def self.map(*args)
    @@components.map(*args)
  end

  class Context
    def get
      binding
    end

    def initialize(hash)
      hash.each_pair { |k, v| instance_variable_set("@#{k}", v) }
    end
  end

  def self.template(output_file, input_file, params = nil)
    if params.nil?
      params = input_file
      input_file = "#{output_file}.erb"
    end
    context = Context.new(params)
    puts "[33;1mGenerating #{output_file} from #{input_file}[0m"
    template = File.read("#{input_file}")
    processed = ERB.new(template).result(context.get)
    File.write("#{output_file}", processed)
  end

  def self.setup
    components = {
      "base-aquarium-image" => {
        directory: "base-container",
        image_name: "aquarium-base",
        preimage: lambda do |component|
          FileUtils.cp "#{ENV["HOME"]}/.ssh/id_rsa.pub",  component.directory
        end,
        postimage: lambda do |component|
          FileUtils.rm "#{component.directory}/id_rsa.pub"
        end
      },
      "builder" => {
        debs: ["atlantis-builder", "atlantis-builderd"],
        repo: "atlantis-builder",
        preimage: lambda do |component|
          FileUtils.cp "#{ENV["HOME"]}/.ssh/id_rsa.pub", component.directory
          status = Status.read
        end,
        postimage: lambda do |component|
          FileUtils.rm "#{component.directory}/id_rsa.pub"
        end,
        docker_opts: ['-e REGISTRY=$(cat ../registry/ip) ',
                      '-e ATLANTIS_BUILDERD_OPT=--registry=$(cat ../registry/ip)',
                      '-v /home/vagrant/repos:/root/repos',
                      '-v /home/vagrant/data/builder/images/:/root/images',
                      '--privileged'].join(" ")
      },
      "manager" => {
        debs: ["atlantis-manager"],
        repo: "atlantis-manager",
        postcompile: lambda do |component|
           system("sudo cp #{component.repo}/example/client /usr/local/bin/atlantis-manager")
           system("sudo cp #{component.repo}/lib/atlantis/bin/atlantis /usr/local/bin")
        end,
        preimage: lambda do |component|
          status = Status.read
        end,
        poststart: lambda do |component|
          status = Status.read
          params = { :manager_host => status["manager"]["ip"] }
          template("#{component.directory}/client.toml", params)
          system("sudo mkdir -p /etc/atlantis/manager")
          system("sudo mv #{component.directory}/client.toml /etc/atlantis/manager/client.dev.toml")
        end,
        docker_opts: "-v /etc/aquarium:/host/etc/aquarium -p 443:443"
      },
      "registry" => {
        debs: ["go-docker-registry"],
        repo: "go-docker-registry",
        preimage: lambda do |component|
          FileUtils.cp "#{ENV["HOME"]}/.ssh/id_rsa.pub", component.directory
        end,
        postimage: lambda do |component|
          FileUtils.rm "#{component.directory}/id_rsa.pub"
        end,
        docker_opts: ['-v /atlantis-docker:/atlantis-docker'].join(" ")
       },

      "router" => {
        debs: ["atlantis-router"],
        repo: "atlantis-router",
        preimage: lambda do |component|
          status = Status.read
          params = { }
          %w{internal external}.each do |group|
            template("#{component.directory}/server.#{group}.toml",
                     "#{component.directory}/server.toml.erb",
                     params.merge({:group => group}))
          end
        end,
        instances: {
          "internal" => {
            docker_opts: "-e GROUP=internal -p 8081:8080"
          },
          "external" => {
            docker_opts: "-e GROUP=external -p 8080:8080 -p 8000:80"
          }
        }
      },
      "supervisor" => {
        debs: ["atlantis-supervisor"],
        repo: "atlantis-supervisor",
        preimage: lambda do |component|
          status = Status.read
        end,
        docker_opts: "--privileged",
        instances: {
          "1" => {},
          "2" => {}
        }
      },
      "zookeeper" => {},
    }
    @@components = Hash[components.map do |name, options|
      [name, Component.new(name, options)]
    end]
  end
  setup
end
