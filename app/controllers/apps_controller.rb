class AppsController < ApplicationController
  before_filter :load_app, only: [:start, :stop, :status]

  def start
    @app.start
    redirect_to action: 'index'
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
    @app = App.find_by_id(params[:name])
  end
end

