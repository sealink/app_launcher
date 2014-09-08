require 'open3'

ServiceStatus = Struct.new(:ok, :message) do

  # Return a new status instance for the given command
  def self.for(command)
    stdin, stdout, stderr = Open3.popen3(command)
    error_message = stderr.read

    ok = error_message['Already running'] || error_message['Running with PID']
    new(ok, error_message)
  end

  def running?
    ok
  end
end
