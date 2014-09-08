class Service
  attr_reader :id

  ALLOWED_TYPES = %w(solr resque-pool schedule unicorn)

  def initialize(app_id, id, service_type)
    if !ALLOWED_TYPES.include?(service_type)
      raise ArgumentError, "Unknown service type: [#{service_type}]"
    end

    @app_id       = app_id
    @id           = id
    @service_type = service_type
  end

  def start
    return if status.running?
    perform('start')
  end

  def stop
    return if !status.running?
    perform('stop')
  end

  def status
    ServiceStatus.for cmd_string('status')
  end

  def running?
    status.running?
  end

  def to_s
    @id
  end

  private

  def cmd_string(action)
    %{ service #{@service_type} "#{action} #{@app_id}" }
  end

  def perform(action)
    if !%w(start stop).include?(action.to_s)
      raise ArgumentError, "Cannot perform action: [#{action}]"
    end
    spawned_process = Process.spawn cmd_string(action)
    Process.detach(spawned_process)
  end
end
