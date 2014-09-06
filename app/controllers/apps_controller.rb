class AppsController < ApplicationController
  before_filter :load_app, only: [:start, :stop, :status]

  def index
    @apps = AppRepository.all
  end

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
    app = AppRepository.find_by_id(params[:id])
    render partial: 'app', locals: { app: app }
  end

  private

  def load_app
    @app = AppRepository.find_by_id(params[:id])
  end
end

