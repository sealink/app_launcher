
unicorn_port    = ENV['PORT'] || 8080
unicorn_timeout = ENV['TIMEOUT'] || 40
workers         = ENV['WORKERS'] || 2
rails_env       = ENV['RAILS_ENV'] || 'production'
puts "rails env = #{rails_env} - ENV = #{ENV['RAILS_ENV']}"

root_app_path = File.expand_path('../../../', __FILE__)
current_path = "#{root_app_path}/current"
shared_path = "#{root_app_path}/shared"

shared_bundler_gems_path = "#{shared_path}/bundle/ruby/2.1.0"
Unicorn::HttpServer::START_CTX[0] = "#{shared_bundler_gems_path}/bin/unicorn"

# Use at least one worker per core if you're on a dedicated server,
# more will usually help for _short_ waits on databases/caches.
worker_processes workers.to_i

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
working_directory current_path

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
listen "#{shared_path}/tmp/sockets/unicorn.sock", :backlog => 1024
listen unicorn_port.to_i  # Add :tcp_nopush => true to force FULL response, not partial streaming

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout unicorn_timeout.to_i

# feel free to point this anywhere accessible on the filesystem
pid "#{shared_path}/log/unicorn.pid"

# By default, the Unicorn logger will write to stderr.
# Additionally, ome applications/frameworks log to stderr or stdout,
# so prevent them from going to /dev/null when daemonized here:
stderr_path "#{shared_path}/log/unicorn.stderr.log"
stdout_path "#{shared_path}/log/unicorn.stdout.log"

# combine REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  defined?(RedisConnection) and
    RedisConnection.quit

  # This allows a new master process to incrementally
  # phase out the old master process with SIGTTOU to avoid a
  # thundering herd (especially in the "preload_app false" case)
  # when doing a transparent upgrade.  The last worker spawned
  # will then kill off the old master process with a SIGQUIT.
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
  
  # *optionally* throttle the master from forking too quickly by sleeping
  sleep 1
end

after_fork do |server, worker|
  # per-process listener ports for debugging/admin/migrations
  # addr = "127.0.0.1:#{9293 + worker.nr}"
  # server.listen(addr, :tries => -1, :delay => 5, :tcp_nopush => true)

  # Drop a PID file for each worker... useful for monitoring with monit
  child_pid = server.config[:pid].sub('.pid', ".#{worker.nr}.pid")
  system("echo #{Process.pid} > #{child_pid}")

  # the following is *required* for Rails + "preload_app true",
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached, and Redis.

  # Not sure if we need to do this (since master does a disconnect too on before_fork)
  defined?(RedisConnection) and
    RedisConnection.quit

  Rails.cache.instance_variable_get(:@data).try(:client).try(:reconnect)
end

class Unicorn::HttpServer
  def proc_name(tag)
    root_app_path = File.expand_path('../../../', __FILE__)
    dir = root_app_path.split('/').last
    $0 = ([dir, tag]).concat(START_CTX[:argv]).join(' ')
  end
end

before_exec do |server| 
  paths = (ENV["PATH"] || "").split(File::PATH_SEPARATOR)
  paths.unshift "#{shared_bundler_gems_path}/bin"
  ENV["PATH"] = paths.uniq.join(File::PATH_SEPARATOR)

  ENV['GEM_HOME'] = ENV['GEM_PATH'] = shared_bundler_gems_path
  ENV['BUNDLE_GEMFILE'] = "#{current_path}/Gemfile"
end

