client = require '../lib/client'

module.exports = class Page extends Backbone.Model
  get: (pageid) ->
    $.ajax
      type: "GET"
      dataType: "json"
      async: false
      url: 'page/'+pageid
      success: (data) ->
        content = data
