# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
class window.AppCollection 
  constructor: (@apps) ->
    @refresh()

  doDelayedRefresh: ->
    setTimeout(@refresh, 5000)

  refresh: =>
    for app in @apps
      @reloadApp(app)
    @doDelayedRefresh()


  reloadApp: (app) ->
    $.get "/apps/#{app.id}/show", (response) ->
      $("#app-#{app.id}").html(response)
  
