BaseView  = require '../lib/base_view'
Page      = require '../models/page'

module.exports = class PageView extends BaseView

  el: 'body.application'
  template: require './templates/page'

  error: ''

  getRenderData: ->
    res =
      url: @url
      error: @error

  renderPage: (pageid) ->
    $.get 'authUrl/'+pageid, '', (data) =>
      if data.error
        @error = data.error
      else
        @url = data.url
      @render()
    , 'json'

  logout: ->
    $.get 'logout', '', =>
      window.location = "#login"
