# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
class window.AppCollection 
  constructor: (@app_ids) ->
    @refresh()

  doDelayedRefresh: ->
    setTimeout(@refresh, 5000)

  refresh: =>
    for app_id in app_ids
      @reloadApp(app_id)
    @doDelayedRefresh()


  reloadApp: (app_id) ->
    $.get "/apps/#{app_id}/show", (response) ->
      $("#app-#{app_id}").html(response)
  
