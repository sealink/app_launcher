class AppsController < ApplicationController
  before_filter :load_app, only: [:start, :stop, :status]

  def start
    @app.start
    sleep 5
    #raise @app.subapps.values.first.url.class.inspect << @app.subapps.values.first.url.inspect
    #redirect_to "http://fantasea.testing.quicktravel.com.au" #@app.subapps.values.first.url
    redirect_to @app.subapps.values.first.url
  end

  def stop
    @app.stop
    redirect_to action: "index"
  end

  def status
    render json: @app.status
  end

  def show_app
    @app = App.find_by_id(params[:id])
    render partial: 'app', layout: false
  end

  private

  def load_app
    @app = App.find_by_name(params[:name])
  end
end

