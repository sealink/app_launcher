class AppsController < ApplicationController
  APPS = YAML::load(File.read("#{Rails.root}/config/apps.yml"))

  def index
    @subapps = %w(unicorn schedule solr resque cms)
    @apps = APPS
  end

  def start
    action :start
  end

  def stop
    action :stop
  end
  
  private
    def action(action)
      app = APPS[params[:name]]
      Timeout::timeout(20) do
        `sudo #{action} #{params[:name]}`
        sleep(1)
      end
      redirect_to app.values.first
    end

end

