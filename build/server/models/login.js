// Generated by CoffeeScript 1.9.3
var Login, conf, cozydb, htmlparser, log, printit, requestRoot, tough,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

cozydb = require('cozydb');

requestRoot = require('request');

htmlparser = require('htmlparser2');

tough = require('tough-cookie');

conf = require('../../conf.coffee');

printit = require('printit');

log = printit({
  prefix: 'ent-isen',
  date: true
});

module.exports = Login = (function(superClass) {
  extend(Login, superClass);

  function Login() {
    return Login.__super__.constructor.apply(this, arguments);
  }

  Login.docType = 'CASLogin';

  Login.schema = {
    username: String,
    password: String,
    tgc: Object,
    jsessionid: Object
  };

  Login.casUrl = conf.casUrl;

  Login.auth = function(username, password, callback) {
    var j, jsessionid, lt, parser, request, service;
    log.info('Attempting connection as ' + username + '.');
    service = 'https://ent-proxy.cozycloud.cc/';
    if (!username || !password) {
      log.error('No data received.');
      return callback(null, false);
    } else {
      j = requestRoot.jar();
      request = requestRoot.defaults({
        jar: j
      });
      lt = "";
      jsessionid = "";
      parser = new htmlparser.Parser({
        onopentag: function(name, attribs) {
          var action;
          if (name === 'input' && attribs.name === 'lt' && attribs.type === 'hidden') {
            lt = attribs.value;
          }
          if (name === 'form' && attribs.id === 'fm1') {
            action = attribs.action;
            if (action.match(/;jsessionid=(.+)/) !== null) {
              return jsessionid = action.match(/;jsessionid=(.+)/)[0];
            } else {
              return jsessionid = "";
            }
          }
        }
      }, {
        decodeEntities: true
      });
      return request({
        url: Login.casUrl + 'login?service=' + service
      }, function(err, status, body) {
        if (err) {
          return callback(err);
        } else {
          parser.write(body);
          parser.end();
          return request.post({
            url: Login.casUrl + 'login' + jsessionid + '?service=' + service,
            form: {
              username: username,
              password: password,
              lt: lt,
              submit: "LOGIN",
              _eventId: "submit"
            }
          }, function(err, status, body) {
            var cookies, tgc;
            if (err) {
              return callback(err);
            } else {
              if (status.statusCode === 302) {
                log.info('Connection successful, saving user data...');
                tgc = "";
                jsessionid = "";
                cookies = j.getCookies(Login.casUrl);
                cookies.forEach(function(cookie) {
                  if (cookie.key === "CASTGC") {
                    tgc = cookie.toJSON();
                  }
                  if (cookie.key === "JSESSIONID") {
                    return jsessionid = cookie.toJSON();
                  }
                });
                return Login.create({
                  username: username,
                  password: password,
                  tgc: tgc,
                  jsessionid: jsessionid
                }, function() {
                  log.info('User data saved in the Data System.');
                  return callback(null, true);
                });
              } else {
                log.error('Attempted to connect as ' + username + ' with no success');
                return callback(null, false);
              }
            }
          });
        }
      });
    }
  };

  Login.authRequest = function(service, callback) {
    return Login.request('all', function(err, logins) {
      var login;
      if (err) {
        return next(err);
      } else {
        if (logins.length === 0) {
          return callback("No user logged in");
        } else {
          login = logins[logins.length - 1];
          return Login.getConfiguredRequest(service, login, function(err, request) {
            if (err) {
              return callback(err);
            } else {
              return request({
                uri: ''
              }, function(err, status, body) {
                var password, username;
                if (err) {
                  return log.error(err);
                } else {
                  if (status.statusCode === 200) {
                    username = login.username;
                    password = login.password;
                    return login.destroy(function(err) {
                      if (err) {
                        return callback(err);
                      } else {
                        log.info('Cookies expired, logging back in');
                        return Login.auth(username, password, function(err, status) {
                          if (err) {
                            return callback(err);
                          } else {
                            if (status) {
                              return Login.authRequest(service, callback);
                            } else {
                              return callback("Can't connect to CAS");
                            }
                          }
                        });
                      }
                    });
                  } else if (status.statusCode === 302) {
                    log.info('Sending ' + status.headers.location);
                    return callback(null, status.headers.location);
                  }
                }
              });
            }
          });
        }
      }
    });
  };

  Login.logAllOut = function(callback) {
    return Login.request('all', function(err, logins) {
      var i, nbToDelete;
      if (err) {
        return callback(err);
      } else {
        i = 0;
        nbToDelete = logins.length;
        return logins.forEach(function(login) {
          var Cookie, j, jsessionid, tgc;
          j = requestRoot.jar();
          Cookie = tough.Cookie;
          tgc = Cookie.fromJSON(login.tgc);
          jsessionid = Cookie.fromJSON(login.jsessionid);
          return j.setCookie(tgc.toString(), Login.casUrl, function() {
            return j.setCookie(jsessionid.toString(), Login.casUrl, function() {
              var request;
              request = requestRoot.defaults({
                jar: j,
                followRedirect: true
              });
              return request({
                url: Login.casUrl + 'logout'
              }, function(err, status, body) {
                if (err) {
                  return callback(err);
                } else {
                  return login.destroy(function(err) {
                    i++;
                    if (err) {
                      return callback(err);
                    } else if (i === nbToDelete) {
                      log.info('All credentials removed from the Data System');
                      return callback(null, true);
                    }
                  });
                }
              });
            });
          });
        });
      }
    });
  };

  Login.getConfiguredRequest = function(serviceSlug, login, callback) {
    var Cookie, j, jsessionid, k, len, ref, service, tgc, url;
    url = null;
    ref = conf.servicesList;
    for (k = 0, len = ref.length; k < len; k++) {
      service = ref[k];
      if (serviceSlug === service.clientServiceUrl) {
        log.info('Requesting ' + serviceSlug + ' as ' + login.username);
        url = service.serverServiceUrl;
      }
    }
    if (url === null) {
      return callback("Unknown service '" + serviceSlug + "'");
    } else {
      j = requestRoot.jar();
      Cookie = tough.Cookie;
      tgc = Cookie.fromJSON(login.tgc);
      jsessionid = Cookie.fromJSON(login.jsessionid);
      return j.setCookie(tgc.toString(), this.casUrl, (function(_this) {
        return function() {
          return j.setCookie(jsessionid.toString(), _this.casUrl, function() {
            var request;
            request = requestRoot.defaults({
              jar: j,
              followRedirect: false,
              baseUrl: _this.casUrl + 'login?service=' + url
            });
            return callback(null, request);
          });
        };
      })(this));
    }
  };

  return Login;

})(cozydb.CozyModel);