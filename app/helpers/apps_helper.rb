module AppsHelper
  def simple_status(app)
    status = `sudo status #{app}`
    if status['stop']
      'stopped'
    elsif status['running']
      'running'
    elsif status['starting']
      'starting'
    else
      status.gsub(app.to_s + ' ', '')
    end
  end

  def status_class(app)
    case simple_status(app)
    when 'stopped'; 'stopped'
    when 'running'; 'running'
    when 'starting'; 'starting'
    else '#fff'; 'unknown'
    end
  end
end
