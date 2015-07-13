BaseView  = require '../lib/base_view'
Page      = require '../models/page'

module.exports = class PageView extends BaseView

  el: 'body.application'
  template: require './templates/page'

  status: ''

  events: =>
    'click .exitButton' : @logout

  getRenderData: ->
    res =
      url: @url

  renderPage: (pageid) ->
    $.get 'authUrl/'+pageid, '', (data) =>
      @url = data.url
      @render()
    , 'json'

  logout: ->
    $.get 'logout', '', =>
      window.location = "#login"
