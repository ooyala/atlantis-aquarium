require "json"
require "fcntl"

class Status
  class <<self
    STATUS_FILE = File.join(File.dirname(__FILE__), "../data/status.json")

    def deep_merge(h1, h2)
      result = h1.merge(h2) { |key, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? deep_merge(v1, v2) : v2 }
      h2.each do |key, value|
        result.delete(key) if value.nil?
      end
      result
    end

    def read_file(file)
      contents = file.read
      contents = "{}" if contents.length < 2
      JSON.parse(contents)
    end

    def read
      begin
        file = File.open(STATUS_FILE, "r")
      rescue Errno::ENOENT
        return {}
      end
      unless file.flock(File::LOCK_SH | File::LOCK_NB)
        puts "Failed to acquire shared lock on #{STATUS_FILE}.\nBlocking until it's available..."
        file.flock(File::LOCK_SH)
      end

      read_file(file)
    ensure
      file.close if file
    end

    def set(delta)
      # NOTE(edanaher): "w+" will overwrite the file, but "r+" will fail if it's not there.
      begin
        file = File.open(STATUS_FILE, "r+")
      rescue Errno::ENOENT
        file = File.open(STATUS_FILE, "w+")
      end
      unless file.flock(File::LOCK_EX | File::LOCK_NB)
        puts "Failed to acquire exclusive lock on #{STATUS_FILE}.\nBlocking until it's available..."
        file.flock(File::LOCK_EX)
      end

      data = read_file(file)
      data = deep_merge(data, delta)
      file.rewind
      file.truncate(0)
      file.write(JSON.pretty_generate(data))
    ensure
      file.close if file
    end
  end
end
