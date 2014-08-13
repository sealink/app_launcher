require 'timeout'
class App
  attr_accessor :services, :apps, :subapps, :name, :script_type, :id
 
  APPS = YAML::load(File.read("#{Rails.root}/config/apps.yml"))
  SUBAPPS = %w(unicorn schedule solr resque cms)

  def self.all
    APPS.map do |id, options|
      App.find_by_id(id)
    end
  end

  def self.find_by_id(id)
    options = APPS[id].symbolize_keys
    subapps = options.except(:color, :script_type)
    options[:name] ||= id
    a = App.new(options.slice(:name, :color, :script_type).merge(id: id))
    a.subapps = subapps.each_with_object({}){|(id, url), subapps| subapps[id]=SubApp.new(id, url) }
    a
  rescue
    raise id.inspect
  end
 
  def initialize(options)
    @id = options[:id]
    @name = options[:name]
    @color = options[:color]
    @script_type = options[:script_type] || 'systemv'
  end

  def has_cms?
    self.subapps[:cms].present?
  end

  def start
    action("start")
  end

  def stop
    action("stop")
  end

  def status
    action = 'status'
    solr     = status_for("service solr        \"#{action} #{@id}\"")
    resque   = status_for("service resque-pool \"#{action} #{@id}\"")
    schedule = status_for("service schedule    \"#{action} #{@id}\"")
    qt       = status_for("service unicorn     \"#{action} #{@id}\"")
    cms      = status_for("service unicorn     \"#{action} #{@id.gsub("qt","cms")}\"") if has_cms?
    {resque: resque, schedule: schedule, solr: solr, qt: qt, cms: cms}
  end
def status_for(command)
require 'open3'
  stdin, stdout, stderr = Open3.popen3(command)
   stderr = stderr.read
  if stderr['Already running'] || stderr['Running with PID']
    'running'
  else
    stderr
  end
end

  def action(action)
    if @script_type == "systemv"
      spawn_and_detach %{ service solr        "#{action} #{@id}" }
      spawn_and_detach %{ service resque-pool "#{action} #{@id}" }
      spawn_and_detach %{ service schedule    "#{action} #{@id}" }
      spawn_and_detach %{ service unicorn     "#{action} #{@id}" }
      # Placing this separately would be better but this is consistent with the Upstart setup
      spawn_and_detach %{ service unicorn     "#{action} #{@id.gsub("qt","cms")}" } if has_cms?
    else # Upstart
      spawn_and_detach %{ sudo #{action} #{@id} }
    end
  end

  def running?
    simple_status == 'running'
  end


  def simple_status(subapp = nil)
    Service.simple_status(@id, subapp)
  end

  def status_class(subapp = nil)
    Service.status_class(@id, subapp)
  end

  def to_s
    @name
  end

  private
  def spawn_and_detach(cmd)
    Process.detach(Process.spawn(cmd))
  end
 
end


class Service
  
  
  def self.simple_status(id, subapp)
    status = nil
    ::Timeout::timeout(1) do
      if App.find_by_id(id).script_type == "systemv"
        if subapp == :cms
          status = system("service unicorn status " << "#{id.gsub("qt","cms")}")
        else
          status = system("service #{subapp || "unicorn"} status " << "#{id}")
        end
        return status ? 'running' : 'stopped'
      else # Upstart
        status = `sudo status #{id}`
      end
    end

    if status['stop']
      'stopped'
    elsif status['running']
      'running'
    elsif status['starting']
      'starting'
    else
      status.gsub(to_s + ' ', '')
    end
  end

  def self.status_class(id, subapp = nil)
    case self.simple_status(id, subapp)
    when 'stopped'; 'stopped'
    when 'running'; 'running'
    when 'starting'; 'starting'
    else '#fff'; 'unknown'
    end
  end
end

class SubApp
  attr_accessor :id, :url

  def initialize(id, url)
    @id = id
    @url = url
  end

  #def simple_status
  #  Service.simple_status(@id)
  #end

  #def status_class
  #  Service.status_class(@id)
  #end
end
