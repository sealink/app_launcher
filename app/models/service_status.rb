require 'open3'

ServiceStatus = Struct.new(:ok, :message) do

  # Return a new status instance for the given command
  def self.for(command)
    stdout, stderr, exit_status = Open3.capture3(command)
    new(exit_status.success?, stdout + stderr)
  end

  def running?
    ok
  end
end
