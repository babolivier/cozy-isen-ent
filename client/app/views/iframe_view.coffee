BaseView = require '../lib/base_view'

module.exports = class IframeView extends BaseView

    el: 'body.application'
    template: require('./templates/iframe')

    setUrl: (url) ->
      @url = "https://web.isen-bretagne.fr/"+url

    getRenderData: ->
      res =
        url: @url
