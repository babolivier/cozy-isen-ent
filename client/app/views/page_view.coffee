BaseView  = require '../lib/base_view'
Page      = require '../models/page'
AppView   = require 'views/app_view'

module.exports = class PageView extends BaseView

  el: 'body.application'
  template: require './templates/page'

  error: ''

  events: =>
    'click #closeError': @hideError

  getRenderData: ->
    res =
      url: @url

  renderPage: (pageid, oldpage) =>
    if typeof oldpage is 'undefined'
      oldpage =
        url: 'moodle'
    return $.get 'authUrl/'+pageid, '', (data) =>
      if data.error
        console.log data.error
        if @error is "No user logged in"
          mainView = new AppView()
          mainView.renderIfNotLoggedIn()
          return
        else
          @error = data.error
      else
        @url = data.url
      @render()
    , 'json'

  logout: ->
    $.get 'logout', '', =>
      window.location = "#login"

  afterRender: =>
    if @error
        console.log @error
        @showError @error
    $.ajax
      type: "GET"
      dataType: "json"
      async: false
      url: 'services'
      success: (data) ->
        for key, service of data
          li =
            '<li class="serviceButton">
              <a href="#'+service.clientServiceUrl+'">
                <i class="'+service.clientIcon+'"></i>
                <span>'+service.displayName+'</span>
              </a>
              </li>'
          $("#servicesMenu").append(li)
      error: (err) ->
        @showError err.status + " : " + err.statusText + "<br>" + err.responseText

  showError: (err) =>
    $("#errorText").html err
    $("#errors").removeClass 'off-error'
    $("#errors").addClass 'on-error'

  hideError: =>
      $("#errors").removeClass 'on-error'
      $("#errors").addClass 'off-error'