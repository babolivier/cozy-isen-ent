AppView     = require 'views/app_view'
PageView    = require 'views/page_view'

module.exports = class Router extends Backbone.Router

    routes:
      ''         : 'init'
      'login'   : 'init'
      ':pagename': 'page'

    init: ->
      mainView = new AppView()
      mainView.isLoggedIn()
      mainView.render()

    page: (pagename) ->
      if not pagename
        pagename = ""
      mainView = new PageView()
      mainView.renderPage(pagename)
