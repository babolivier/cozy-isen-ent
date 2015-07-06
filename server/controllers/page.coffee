requestRoot   = require 'request'
ent           = "https://web.isen-bretagne.fr/"

module.exports.get = (req, res, next) ->
  request = requestRoot.defaults
    jar:true
  if typeof req.params.pageid is 'undefined'
    page = ""
  else
    page = req.params.pageid
  request ent+page, (err, response, body) ->
    if err
      console.log err
      content = "Erreur : "+err.code
    else
      content = body
    res.send content
