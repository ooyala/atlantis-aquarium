require 'ifconfig'

module Util
  def self.docker_interface
    config = IfconfigWrapper.new('Linux', `ifconfig`).parse
    config['docker0']
  end

  def self.docker_host_ip
    docker_interface.addresses('inet').first.to_s
  end
end
