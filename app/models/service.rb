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
