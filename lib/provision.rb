require_relative "executer"
require "fileutils"
require "openssl"

class Provision
  class <<self
    def provision
      install_packages
      install_go
      setup_build
      setup_conveniences
      create_keys
    end

    def install_packages
      install_squid
      configure_apt
      install_misc_packages
      configure_docker
      configure_dnsmasq
      configure_parallel
    end

    def install_go
      executer = Executer.new("data/setup")
      executer.run_in_vm!("wget -c http://go.googlecode.com/files/go1.2.1.linux-amd64.tar.gz")
      executer.run_in_vm!("sudo tar -C /usr/local -xzf go1.2.1.linux-amd64.tar.gz")
      executer.run_in_vm!("echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile")
      puts 'run "source ~/.profile", or log out and back in to activate go'
    end

    def setup_build
      executer = Executer.new("data/setup")
      executer.run_in_vm!("echo 'export ATLANTIS_SECRET_DIR=$HOME/.atlantis_secret' >> ~/.profile")
    end

    def setup_conveniences
      executer = Executer.new("data/setup")
      # Set up nice ssh access
      executer.run_in_vm!(%q{cat > ~/.ssh/config <<EOF
        Host 172.17.0.*
        User root
          IdentityFile ~/.atlantis_secret/supervisor_master_id_rsa
            StrictHostKeyChecking no
EOF})
    end

    def install_squid
      executer = Executer.new("data/setup")
      executer.run_in_vm!("sudo apt-get install -y squid")
      executer.run_in_vm!("sudo cp squid.conf /etc/squid3")
      executer.run_in_vm!("sudo service squid3 restart")
      # Start squid after the cache directory is mounted
      executer.run_in_vm!("sudo sed -i 's/start on runlevel.*/start on vagrant-mounted/' /etc/init/squid3.conf")
    end
    
    def configure_apt
      executer = Executer.new("data/setup")
      # send apt through squid for caching
      executer.run_in_vm!("sudo apt-get update -qq")
      executer.run_in_vm!("echo 'Acquire::http::Proxy \"http://localhost:3128\";' | " +
                         "sudo tee /etc/apt/apt.conf.d/99http-proxy > /dev/null")
    end

    def install_misc_packages
      executer = Executer.new("data/setup")
      packages = %w{vim screen git lxc-docker libzookeeper-mt-dev zookeeper dnsmasq inotify-tools parallel}
      executer.run_in_vm!("sudo apt-get install -y #{packages.join(" ")}")
      executer.run_in_vm!("sudo apt-get -y autoremove")
    end

    def configure_docker
      executer = Executer.new("data/setup")
      executer.run_in_vm!("sudo usermod -a -G docker vagrant")
      # Send docker through squid for caching
      executer.run_in_vm!(%q{sudo sed -i '$s#$#\nexport HTTP_PROXY="http://127.0.0.1:3128/"#' /etc/default/docker})
      # Use vagrant's DNS.
      # TODO(edanaher): This IP shouldn't be hardcoded.
      executer.run_in_vm!(%q{sudo sed -i '$s#$#\nexport DOCKER_OPTS="--dns 172.17.42.1"#' /etc/default/docker})
      executer.run_in_vm!("sudo service docker restart")
    end

    def configure_dnsmasq
      executer = Executer.new("data/setup")
      # Tell dnsmasq to use Aquarium Manager's hosts files as well.
      executer.run_in_vm!(%q{sudo sh -c "echo 'addn-hosts=/etc/aquarium/hosts-manager' > /etc/dnsmasq.d/aquarium-extra-hosts"})
      executer.run_in_vm!(%q{sudo sh -c "echo 'addn-hosts=/etc/aquarium/hosts-aquarium' >> /etc/dnsmasq.d/aquarium-extra-hosts"})
      executer.run_in_vm!("sudo service dnsmasq restart", :status => 129)
    end

    def configure_parallel
      executer = Executer.new("data/setup")
      # Ubuntu configure this wrong by default.
      executer.run_in_vm!("sudo rm -f /etc/parallel/config")
    end

    def go_byte_array(bytes)
      bytes = bytes.map { |b|"0x#{b.to_s(16).upcase}" }
      "[]byte{#{bytes.join(", ")}}"
    end

    def atlantis_key_contents
      cipher = OpenSSL::Cipher::AES.new(256, :CBC)
      key = cipher.random_key.chars.map { |c| c.ord }
      iv = cipher.random_iv.chars.map { |c| c.ord }
      salt = (1..8).map { rand(256) }
      <<-EOF
        package crypto

        var (
          AES_SALT = #{go_byte_array(salt)}
          AES_KEY = #{go_byte_array(key)}
          AES_IV = #{go_byte_array(iv)}
        )
      EOF
    end

    def ssl_certificate
      key = OpenSSL::PKey::RSA.new 512

      name = OpenSSL::X509::Name.parse "/C=US/O=Ooyala/OU=Aquarium"
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = rand(2**32) # apparently re-using these is bad.
      cert.not_before = Time.now
      cert.not_after = Time.now + 60*60*24*365
      cert.public_key = key.public_key
      cert.subject = name

      cert.sign key, OpenSSL::Digest::SHA1.new
      [key.to_pem, cert.to_pem]
    end

    def atlantis_manager_cert_contents
      key, cert = ssl_certificate
      <<-EOF
      package crypto

      var (
        SERVER_CERT = []byte(`#{cert}`)
        SERVER_KEY = []byte(`#{key}`)
      )
      EOF
    end

    def create_keys
      saved_wd = Dir.getwd
      Dir.mkdir(".atlantis_secret") unless File.directory?(".atlantis_secret")
      Dir.chdir(".atlantis_secret")

      File.write("registry.secret.sh", "") # AWS keys; unnecessary for local storage.
      File.write("manager.secret.sh", "")  # AWS keys; unnecessary for local storage.
      File.write("atlantis_key.go", atlantis_key_contents) unless File.exists?("atlantis_key.go")
      File.write("manager_cert.go", atlantis_manager_cert_contents) unless File.exists?("manager_cert.go")

      # Don't regenerate key files to avoid breaking ssh'ing into old containers.
      system("ssh-keygen -f supervisor_master_id_rsa -N ''") unless File.exists?("supervisor_master_id_rsa")
      system("cp supervisor_master_id_rsa builder_id_rsa") unless File.exists?("builder_id_rsa")
      system("cp supervisor_master_id_rsa.pub builder_id_rsa.pub") unless File.exists?("builder_id_rsa.pub")
      # Also copy the ssh keys to the standard location.
      unless File.exists?("/home/vagrant/.ssh/id_rsa")
        FileUtils.cp("supervisor_master_id_rsa", "/home/vagrant/.ssh/id_rsa")
        FileUtils.cp("supervisor_master_id_rsa.pub", "/home/vagrant/.ssh/id_rsa.pub")
      end

      Dir.chdir(saved_wd)
    end
  end
end
