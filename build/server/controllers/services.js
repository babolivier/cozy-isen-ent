// Generated by CoffeeScript 1.9.3
var conf;

conf = require('../../conf.coffee');

module.exports.getServicesList = function(req, res, next) {
  return res.send(conf.servicesList);
};

module.exports.getDefaultService = function(req, res, next) {
  return res.send(conf.defaultService);
};