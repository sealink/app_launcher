class App
  attr_accessor :services, :apps, :subapps, :name, :script_type
 
  APPS = YAML::load(File.read("#{Rails.root}/config/apps.yml"))
  SUBAPPS = %w(unicorn schedule solr resque cms)

  def self.all
    APPS.map do |name, options|
      App.find_by_name(name)
    end
  end

  def self.find_by_name(name)
    options = APPS[name].symbolize_keys
    subapps = options.except(:color, :script_type)
    a = App.new(options.slice(:color, :script_type).merge(name: name))
    a.subapps = subapps.each_with_object({}){|(name, url), subapps| subapps[name]=SubApp.new(name, url) }
    a
  rescue
    raise name.inspect
  end
 
  def initialize(options)
    @name = options[:name]
    @color = options[:color]
    @script_type = options[:script_type]
  end

  def start
    action("start")
  end

  def stop
    action("stop")
  end

  def action(action)
    Timeout::timeout(300) do
      if @script_type == "systemv"
        `service resque "#{action} #{@name}"`
        `service schedule "#{action} #{@name}"`
        `service unicorn "#{action} #{@name}"`
        # Placing this separately would be better but this is consistent with the Upstart setup
        `service unicorn "#{action} #{@name.gsub("qt","cms")}"`
      else # Upstart
        `sudo #{action} #{@name}`
      end
    end
  end

  def running?
    simple_status == 'running'
  end


  def simple_status(subapp = nil)
    Service.simple_status(@name, subapp)
  end

  def status_class(subapp = nil)
    Service.status_class(@name, subapp)
  end
  def to_s
    @name.to_s.titleize
  end
 
end

class Service
  
  
  def self.simple_status(name, subapp)
    status = nil
    Timeout::timeout(1) do
      if App.find_by_name(name).script_type == "systemv"
        if subapp == :cms
          status = system("service unicorn status " << "#{name.gsub("qt","cms")}")
        else
          status = system("service #{subapp || "unicorn"} status " << "#{name}")
        end
        return status ? 'running' : 'stopped'
      else # Upstart
        status = `sudo status #{name}`
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

  def self.status_class(name, subapp = nil)
    case self.simple_status(name, subapp)
    when 'stopped'; 'stopped'
    when 'running'; 'running'
    when 'starting'; 'starting'
    else '#fff'; 'unknown'
    end
  end
end

class SubApp
  attr_accessor :name, :url

  def initialize(name, url)
    @name = name
    @url = url
  end

  #def simple_status
  #  Service.simple_status(@name)
  #end

  #def status_class
  #  Service.status_class(@name)
  #end
end
