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
