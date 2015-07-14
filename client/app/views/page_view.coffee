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
        $("#errors").html data.error
        console.log data.error
      else
        @url = data.url
        @render()
    , 'json'

  logout: ->
    $.get 'logout', '', =>
      window.location = "#login"
