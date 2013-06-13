# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
window.Apps =
  init: (apps) ->
    for app in apps
      @reloadApp(app)

  reloadApp: (app) ->
    $.get "/apps/#{app.id}/show", (response) ->
      $("#app-#{app.id}").html(response)
  
