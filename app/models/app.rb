class App
  attr_reader :id, :name, :url, :color, :category

  def initialize(id, options)
    @id       = id
    @name     = options.fetch(:name, @id)
    @url      = options.fetch(:url, '')
    @color    = options[:color]
    @category = options.fetch(:category, 'Uncategorized')
    @services = {}
  end

  def add_service(service_id, service_type)
    @services[service_id] = Service.new(@id, service_id, service_type)
  end

  def services
    @services.values
  end

  def start
    services.each(&:start)
  end

  def stop
    services.each(&:stop)
  end

  def running?
    services_statuses.values.all?(&:running?)
  end

  def any_running?
    services_statuses.values.any?(&:running?)
  end

  def services_statuses
    @services_statuses ||= lookup_services_statuses
  end

  def lookup_services_statuses
    services.map { |service| [service, service.status] }.to_h
  end

  def to_s
    @name
  end
end

