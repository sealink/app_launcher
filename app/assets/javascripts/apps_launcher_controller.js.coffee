class AppCollection
  constructor: (@appIds) ->
    @refresh()

  doDelayedRefresh: ->
    setTimeout(@refresh, 5000)

  refresh: =>
    return unless $('.js-auto-refresh').is(':checked')
    for appId in appIds
      @reloadApp(appId)
    @doDelayedRefresh()

  reloadApp: (appId) ->
    appRow = new AppRow(appId)
    $.get "/apps/#{appId}/show", appRow.update


class AppRow
  constructor: (@id) ->

  $appRow: ->
    $("#app-#{@id}")

  update: (html) =>
    return unless @$appRow().data('original-html') != html
    console.log "App #{@id} changed"
    @$appRow().data('original-html', html)
    @$appRow().html(html)
    @initTooltips()

  initTooltips: ->
    @$appRow().find('.dependent-service').tooltip
      container: 'body'
      placement: 'top'


window.AppLauncherController =
  start: (@appIds) ->
    @appCollection = new AppCollection(@appIds)
