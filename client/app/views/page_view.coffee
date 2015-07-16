BaseView  = require '../lib/base_view'
Page      = require '../models/page'

module.exports = class PageView extends BaseView

  el: 'body.application'
  template: require './templates/page'

  error: ''

  getRenderData: ->
    res =
      url: @url

  renderPage: (pageid, oldpage) =>
    if typeof oldpage is 'undefined'
      oldpage =
        url: 'moodle'
    return $.get 'authUrl/'+pageid, '', (data) =>
      if data.error
        $("#errorText").html data.error
        $("#errors").addClass 'on-error'
      else
        @url = data.url
        @render()
    , 'json'

  logout: ->
    $.get 'logout', '', =>
      window.location = "#login"

  afterRender: =>
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
        $("#errorText").html err.status + " : " + err.statusText + "<br>" + err.responseText
        $("#errors").addClass 'on-error'
