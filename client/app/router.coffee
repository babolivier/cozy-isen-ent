AppView     = require 'views/app_view'
PageView    = require 'views/page_view'
LogoutView  = require 'views/logout_view'

module.exports = class Router extends Backbone.Router

    # We try to maintain some continuity within the display, like still displaying
    # a correct page even when we have an error

    routes:
      ''         : 'init'
      'login'    : 'login'
      'logout'   : 'logout'
      ':pagename': 'page'

    init: ->
      mainView = new AppView()
      mainView.render()

    login: ->
      mainView = new AppView()
      mainView.render()

    page: (pagename) =>
      if not pagename
        pagename = ""
      mainView = new PageView()
      mainView.renderPage(pagename)

    logout: =>
      @url = ''
      mainView = new LogoutView()
      mainView.render()