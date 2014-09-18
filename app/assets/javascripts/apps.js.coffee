# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
class window.AppCollection
  constructor: (@app_ids) ->
    @refresh()
    @initTabs()
    @initButtons()

  doDelayedRefresh: ->
    setTimeout(@refresh, 50000)

  refresh: =>
    for app_id in app_ids
      @reloadApp(app_id)
    @doDelayedRefresh()


  reloadApp: (app_id) ->
    $.get "/apps/#{app_id}/show", (response) =>
      $("#app-#{app_id}").html(response)
      @initTooltips()


  initTooltips: ->
    $('.dependent-service').tooltip
      container: 'body'
      placement: 'top'

  initTabs: ->
    # remembers the tab you were on
    $('.app-launcher').on 'click', '.js-tab-btn', (e) ->
      that = $(e.currentTarget)
      e.preventDefault()
      window.location.hash = that.attr('href')
      that.tab('show')

    # click right tab on load (read hash from address bar)
    $ ->
      if window.location.hash.length > 0
        $('.navbar-nav a[href="'+window.location.hash+'"]').click().trigger('shown.bs.tab')
      # else
      #   $('.navbar-nav a:first').click()

  initButtons: ->
    $('.app-launcher').on 'click', '.start-btn, .stop-btn', (e) =>
      e.preventDefault()
      button = $(e.currentTarget)
      action = button.attr('href')
      button.button('loading')

      $.post( action, =>
        button.button('reset')
      ).done =>
        @refresh()





