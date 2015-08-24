(function() {
  'use strict';

  var globals = typeof window === 'undefined' ? global : window;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};
  var has = ({}).hasOwnProperty;

  var aliases = {};

  var endsWith = function(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
  };

  var unalias = function(alias, loaderPath) {
    var start = 0;
    if (loaderPath) {
      if (loaderPath.indexOf('components/' === 0)) {
        start = 'components/'.length;
      }
      if (loaderPath.indexOf('/', start) > 0) {
        loaderPath = loaderPath.substring(start, loaderPath.indexOf('/', start));
      }
    }
    var result = aliases[alias + '/index.js'] || aliases[loaderPath + '/deps/' + alias + '/index.js'];
    if (result) {
      return 'components/' + result.substring(0, result.length - '.js'.length);
    }
    return alias;
  };

  var expand = (function() {
    var reg = /^\.\.?(\/|$)/;
    return function(root, name) {
      var results = [], parts, part;
      parts = (reg.test(name) ? root + '/' + name : name).split('/');
      for (var i = 0, length = parts.length; i < length; i++) {
        part = parts[i];
        if (part === '..') {
          results.pop();
        } else if (part !== '.' && part !== '') {
          results.push(part);
        }
      }
      return results.join('/');
    };
  })();
  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var absolute = expand(dirname(path), name);
      return globals.require(absolute, path);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    cache[name] = module;
    definition(module.exports, localRequire(name), module);
    return module.exports;
  };

  var require = function(name, loaderPath) {
    var path = expand(name, '.');
    if (loaderPath == null) loaderPath = '/';
    path = unalias(name, loaderPath);

    if (has.call(cache, path)) return cache[path].exports;
    if (has.call(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has.call(cache, dirIndex)) return cache[dirIndex].exports;
    if (has.call(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '" from '+ '"' + loaderPath + '"');
  };

  require.alias = function(from, to) {
    aliases[to] = from;
  };

  require.register = require.define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (has.call(bundle, key)) {
          modules[key] = bundle[key];
        }
      }
    } else {
      modules[bundle] = fn;
    }
  };

  require.list = function() {
    var result = [];
    for (var item in modules) {
      if (has.call(modules, item)) {
        result.push(item);
      }
    }
    return result;
  };

  require.brunch = true;
  globals.require = require;
})();
require.register("application", function(exports, require, module) {
module.exports = {
  initialize: function() {
    var Router;
    Router = require('router');
    this.router = new Router();
    Backbone.history.start();
    if (typeof Object.freeze === 'function') {
      return Object.freeze(this);
    }
  }
};
});

;require.register("initialize", function(exports, require, module) {
var app;

app = require('application');

$(function() {
  require('lib/app_helpers');
  return app.initialize();
});
});

;require.register("lib/app_helpers", function(exports, require, module) {
(function() {
  return (function() {
    var console, dummy, method, methods, _results;
    console = window.console = window.console || {};
    method = void 0;
    dummy = function() {};
    methods = 'assert,count,debug,dir,dirxml,error,exception, group,groupCollapsed,groupEnd,info,log,markTimeline, profile,profileEnd,time,timeEnd,trace,warn'.split(',');
    _results = [];
    while (method = methods.pop()) {
      _results.push(console[method] = console[method] || dummy);
    }
    return _results;
  })();
})();
});

;require.register("lib/base_view", function(exports, require, module) {
var BaseView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = BaseView = (function(_super) {
  __extends(BaseView, _super);

  function BaseView() {
    return BaseView.__super__.constructor.apply(this, arguments);
  }

  BaseView.prototype.template = function() {};

  BaseView.prototype.initialize = function() {};

  BaseView.prototype.getRenderData = function() {
    var _ref;
    return {
      model: (_ref = this.model) != null ? _ref.toJSON() : void 0
    };
  };

  BaseView.prototype.render = function() {
    this.beforeRender();
    this.$el.html(this.template(this.getRenderData()));
    this.afterRender();
    return this;
  };

  BaseView.prototype.beforeRender = function() {};

  BaseView.prototype.afterRender = function() {};

  BaseView.prototype.destroy = function() {
    this.undelegateEvents();
    this.$el.removeData().unbind();
    this.remove();
    return Backbone.View.prototype.remove.call(this);
  };

  return BaseView;

})(Backbone.View);
});

;require.register("lib/client", function(exports, require, module) {
exports.request = function(type, url, data, callbacks) {
  var error, success;
  success = callbacks.success || function(res) {
    return callbacks(null, res);
  };
  error = callbacks.error || function(err) {
    return callbacks(err);
  };
  return $.ajax({
    type: type,
    url: url,
    data: data,
    success: success,
    error: error
  });
};

exports.get = function(url, callbacks) {
  return exports.request("GET", url, null, callbacks);
};

exports.post = function(url, data, callbacks) {
  return exports.request("POST", url, data, callbacks);
};

exports.put = function(url, data, callbacks) {
  return exports.request("PUT", url, data, callbacks);
};

exports.del = function(url, callbacks) {
  return exports.request("DELETE", url, null, callbacks);
};
});

;require.register("lib/utils", function(exports, require, module) {
var Utils;

module.exports = Utils = (function() {
  function Utils() {}

  Utils.changepsw = function(username, oldPassword, newPassword, callback) {
    return $.ajax({
      type: "POST",
      async: true,
      url: 'changePassword',
      data: {
        login: username,
        newpassword: newPassword,
        oldpassword: oldPassword
      },
      complete: function(xhr) {
        switch (xhr.status) {
          case 200:
            return callback(null);
          case 304:
            return callback(null);
          case 504:
            return callback("Connection timed out");
          default:
            callback(xhr.responseText);
            return console.error(xhr.responseJSON);
        }
      }
    });
  };

  Utils.importMailAccount = function(credentials, callback) {
    return $.ajax({
      type: "PUT",
      async: true,
      url: 'email',
      data: {
        username: credentials.username,
        password: credentials.password
      },
      complete: function(xhr) {
        switch (xhr.status) {
          case 200:
            return callback(null, true);
          case 304:
            return callback(null, false);
          case 504:
            return callback("Connection timed out");
          default:
            callback(xhr.responseText);
            return console.error(xhr.responseJSON);
        }
      }
    });
  };

  Utils.isMailActive = function(callback) {
    return $.ajax({
      type: "GET",
      async: true,
      url: 'email',
      complete: function(xhr) {
        switch (xhr.status) {
          case 200:
            return callback(null, true);
          case 418:
            return callback(null, false);
          case 504:
            return callback("Connection timed out");
          default:
            callback(xhr.responseText);
            return console.error(xhr.responseJSON);
        }
      }
    });
  };

  Utils.isAdminContactsActive = function(callback) {
    return $.ajax({
      type: "GET",
      async: true,
      url: 'isAdminContactsActive',
      complete: function(xhr) {
        switch (xhr.status) {
          case 200:
            return callback(null, true);
          case 418:
            return callback(null, false);
          case 504:
            return callback("Connection timed out");
          default:
            callback(xhr.responseText);
            return console.error(xhr.responseJSON);
        }
      }
    });
  };

  Utils.importAdminContacts = function(callback) {
    return $.ajax({
      type: "PUT",
      dataType: "text",
      async: true,
      url: 'contactsAdmin',
      complete: function(xhr) {
        switch (xhr.status) {
          case 202:
            return callback(null);
          case 504:
            return callback("Connection timed out");
          default:
            callback(xhr.responseText);
            return console.error(xhr.responseJSON);
        }
      }
    });
  };

  Utils.getAdminImportContactStatus = function(callback) {
    return $.ajax({
      type: "GET",
      dataType: "json",
      async: true,
      url: 'contactsAdmin',
      complete: function(xhr) {
        if (xhr.status === 200 || xhr.status === 304 || xhr.status === 201) {
          return callback(null, xhr.responseJSON);
        } else if (xhr.status === 504) {
          return callback("Connection timed out");
        } else {
          callback(xhr.responseText);
          return console.error(xhr.responseJSON);
        }
      }
    });
  };

  Utils.isStudentsContactsActive = function(callback) {
    return $.ajax({
      type: "GET",
      async: true,
      url: 'trombino/active',
      complete: function(xhr) {
        switch (xhr.status) {
          case 200:
            return callback(null, true);
          case 418:
            return callback(null, false);
          case 504:
            return callback("Connection timed out");
          default:
            callback(xhr.responseText);
            return console.error(xhr.responseJSON);
        }
      }
    });
  };

  Utils.importStudentsContacts = function(callback) {
    return $.ajax({
      type: "PUT",
      dataType: "text",
      async: true,
      timeout: 600000,
      url: 'trombino/import',
      complete: function(xhr) {
        switch (xhr.status) {
          case 202:
            return callback(null);
          case 504:
            return callback("Connection timed out");
          default:
            callback(xhr.responseText);
            return console.error(xhr.responseJSON);
        }
      }
    });
  };

  Utils.getStudentsImportContactStatus = function(callback) {
    return $.ajax({
      type: "GET",
      dataType: "json",
      async: true,
      url: 'trombino/import',
      complete: function(xhr) {
        if (xhr.status === 200 || xhr.status === 304 || xhr.status === 201) {
          return callback(null, xhr.responseJSON);
        } else if (xhr.status === 504) {
          return callback("Connection timed out");
        } else {
          callback(xhr.responseText);
          return console.error(xhr.responseJSON);
        }
      }
    });
  };

  Utils.getStudentsImportRetrieveStatus = function(callback) {
    return $.ajax({
      type: "GET",
      dataType: "json",
      async: true,
      url: 'trombino/status',
      complete: function(xhr) {
        if (xhr.status === 201) {
          return callback(null, xhr.responseJSON, true);
        } else if (xhr.status === 200 || xhr.status === 304) {
          return callback(null, xhr.responseJSON, false);
        } else if (xhr.status === 504) {
          return callback("Connection timed out");
        } else {
          callback(xhr.responseText);
          return console.error(xhr.responseJSON);
        }
      }
    });
  };

  return Utils;

})();
});

;require.register("lib/view_collection", function(exports, require, module) {
var BaseView, ViewCollection,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('lib/base_view');

module.exports = ViewCollection = (function(_super) {
  __extends(ViewCollection, _super);

  function ViewCollection() {
    this.removeItem = __bind(this.removeItem, this);
    this.addItem = __bind(this.addItem, this);
    return ViewCollection.__super__.constructor.apply(this, arguments);
  }

  ViewCollection.prototype.itemview = null;

  ViewCollection.prototype.views = {};

  ViewCollection.prototype.template = function() {
    return '';
  };

  ViewCollection.prototype.itemViewOptions = function() {};

  ViewCollection.prototype.collectionEl = null;

  ViewCollection.prototype.onChange = function() {
    return this.$el.toggleClass('empty', _.size(this.views) === 0);
  };

  ViewCollection.prototype.appendView = function(view) {
    return this.$collectionEl.append(view.el);
  };

  ViewCollection.prototype.initialize = function() {
    var collectionEl;
    ViewCollection.__super__.initialize.apply(this, arguments);
    this.views = {};
    this.listenTo(this.collection, "reset", this.onReset);
    this.listenTo(this.collection, "add", this.addItem);
    this.listenTo(this.collection, "remove", this.removeItem);
    if (this.collectionEl == null) {
      return collectionEl = el;
    }
  };

  ViewCollection.prototype.render = function() {
    var id, view, _ref;
    _ref = this.views;
    for (id in _ref) {
      view = _ref[id];
      view.$el.detach();
    }
    return ViewCollection.__super__.render.apply(this, arguments);
  };

  ViewCollection.prototype.afterRender = function() {
    var id, view, _ref;
    this.$collectionEl = $(this.collectionEl);
    _ref = this.views;
    for (id in _ref) {
      view = _ref[id];
      this.appendView(view.$el);
    }
    this.onReset(this.collection);
    return this.onChange(this.views);
  };

  ViewCollection.prototype.remove = function() {
    this.onReset([]);
    return ViewCollection.__super__.remove.apply(this, arguments);
  };

  ViewCollection.prototype.onReset = function(newcollection) {
    var id, view, _ref;
    _ref = this.views;
    for (id in _ref) {
      view = _ref[id];
      view.remove();
    }
    return newcollection.forEach(this.addItem);
  };

  ViewCollection.prototype.addItem = function(model) {
    var options, view;
    options = _.extend({}, {
      model: model
    }, this.itemViewOptions(model));
    view = new this.itemview(options);
    this.views[model.cid] = view.render();
    this.appendView(view);
    return this.onChange(this.views);
  };

  ViewCollection.prototype.removeItem = function(model) {
    this.views[model.cid].remove();
    delete this.views[model.cid];
    return this.onChange(this.views);
  };

  return ViewCollection;

})(BaseView);
});

;require.register("router", function(exports, require, module) {
var AppView, LogoutView, PageView, Router,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

AppView = require('views/app_view');

PageView = require('views/page_view');

LogoutView = require('views/logout_view');

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    this.logout = __bind(this.logout, this);
    this.page = __bind(this.page, this);
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.routes = {
    '': 'init',
    'login': 'login',
    'logout': 'logout',
    ':pagename': 'page'
  };

  Router.prototype.init = function() {
    var mainView;
    mainView = new AppView();
    return mainView.render();
  };

  Router.prototype.login = function() {
    var mainView;
    mainView = new AppView();
    return mainView.render();
  };

  Router.prototype.page = function(pagename) {
    var mainView;
    if (!pagename) {
      pagename = "";
    }
    mainView = new PageView();
    return mainView.renderPage(pagename);
  };

  Router.prototype.logout = function() {
    var mainView;
    this.url = '';
    mainView = new LogoutView();
    return mainView.render();
  };

  return Router;

})(Backbone.Router);
});

;require.register("views/app_view", function(exports, require, module) {
var AppView, BaseView, Utils,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

Utils = require('../lib/utils');

module.exports = AppView = (function(_super) {
  __extends(AppView, _super);

  function AppView() {
    this.checkStudentsContactsRetrieveStatus = __bind(this.checkStudentsContactsRetrieveStatus, this);
    this.checkStudentsContactsImportStatus = __bind(this.checkStudentsContactsImportStatus, this);
    this.importStudentsContacts = __bind(this.importStudentsContacts, this);
    this.retrieveStudentsContacts = __bind(this.retrieveStudentsContacts, this);
    this.checkAdminContactsImportStatus = __bind(this.checkAdminContactsImportStatus, this);
    this.importAdminContacts = __bind(this.importAdminContacts, this);
    this.importMailAccount = __bind(this.importMailAccount, this);
    this.changepsw = __bind(this.changepsw, this);
    this.saveFormData = __bind(this.saveFormData, this);
    this.showNextStepButton = __bind(this.showNextStepButton, this);
    this.showProgressBar = __bind(this.showProgressBar, this);
    this.setDetails = __bind(this.setDetails, this);
    this.setProgress = __bind(this.setProgress, this);
    this.setStatusText = __bind(this.setStatusText, this);
    this.setOperationName = __bind(this.setOperationName, this);
    this.buildOperationTodoList = __bind(this.buildOperationTodoList, this);
    this.goToDefaultService = __bind(this.goToDefaultService, this);
    this.loginCAS = __bind(this.loginCAS, this);
    this.afterRender = __bind(this.afterRender, this);
    this.beforeRender = __bind(this.beforeRender, this);
    this.events = __bind(this.events, this);
    return AppView.__super__.constructor.apply(this, arguments);
  }

  AppView.prototype.el = 'body.application';

  AppView.prototype.template = require('./templates/home');

  AppView.prototype.events = function() {};

  AppView.prototype.beforeRender = function() {
    return $.ajax({
      url: 'login',
      method: 'GET',
      dataType: 'json',
      complete: (function(_this) {
        return function(xhr) {
          switch (xhr.status) {
            case 200:
              return _this.goToDefaultService();
            case 401:
              break;
            default:
              return console.error(xhr.responseJSON || xhr.responseText);
          }
        };
      })(this)
    });
  };

  AppView.prototype.afterRender = function() {
    return $('form').on('submit', (function(_this) {
      return function() {
        return _this.loginCAS();
      };
    })(this));
  };

  AppView.prototype.loginCAS = function() {
    $('#authStatus').html('');
    $('#submitButton').html('<img src="spinner-white.svg">');
    return $.ajax({
      url: 'login',
      method: 'POST',
      data: {
        username: $('input#username').val(),
        password: $('input#password').val()
      },
      dataType: 'json',
      complete: (function(_this) {
        return function(xhr) {
          if (xhr.status === 200) {
            $('input#username').attr("readonly", "");
            $('input#password').attr("readonly", "");
            _this.saveFormData();
            _this.buildOperationTodoList();
            if (_this.operations.length > 0) {
              _this.currentOperation = 0;
              return _this.globalTimer = setInterval(function() {
                if (_this.operations[_this.currentOperation].launched === false) {
                  _this.operations[_this.currentOperation].functionToCall();
                  return _this.operations[_this.currentOperation].launched = true;
                } else if (_this.operations[_this.currentOperation].terminated === true) {
                  if (_this.currentOperation + 1 !== _this.operations.length) {
                    return _this.currentOperation++;
                  } else {
                    clearInterval(_this.globalTimer);
                    _this.setOperationName("Configuration terminée");
                    _this.setStatusText("N'oubliez pas que vous pouvez relancer ces opérations depuis le menu de configuration de l'application.");
                    _this.showProgressBar(false);
                    _this.setDetails("");
                    return _this.showNextStepButton(true, true);
                  }
                }
              }, 500);
            } else {
              return _this.goToDefaultService();
            }
          } else if (xhr.status === 401) {
            $('#authStatus').html('Login/mot de passe incorrect(s).');
            return $('#submitButton').html('Se connecter');
          } else {
            $('#authStatus').html('Une erreur est survenue du côté du serveur, merci de réessayer ultérieurement.');
            $('#submitButton').html('Se connecter');
            return console.error(xhr);
          }
        };
      })(this)
    });
  };

  AppView.prototype.goToDefaultService = function() {
    return $.ajax({
      type: "GET",
      dataType: "text",
      async: false,
      url: 'defaultService',
      complete: function(xhr) {
        if (xhr.status === 200) {
          return window.location = "#" + xhr.responseText;
        } else if (xhr.status === 504) {
          return $('#authStatus').html("Request timed out");
        } else {
          $('#authStatus').html('Une erreur est survenue du côté du serveur, merci de réessayer ultérieurement.');
          return console.error(xhr);
        }
      }
    });
  };

  AppView.prototype.buildOperationTodoList = function() {
    this.operations = new Array;
    this.operations.push({
      functionToCall: this.changepsw,
      launched: false,
      terminated: false
    });
    this.operations.push({
      functionToCall: this.importMailAccount,
      launched: false,
      terminated: false
    });
    this.operations.push({
      functionToCall: this.importAdminContacts,
      launched: false,
      terminated: false
    });
    this.operations.push({
      functionToCall: this.retrieveStudentsContacts,
      launched: false,
      terminated: false
    });
    return this.operations.push({
      functionToCall: this.importStudentsContacts,
      launched: false,
      terminated: false
    });
  };

  AppView.prototype.setOperationName = function(operationName) {
    return $('#OperationName').html(operationName);
  };

  AppView.prototype.setStatusText = function(statusText) {
    return $('#statusText').html(statusText);
  };

  AppView.prototype.setProgress = function(progress) {
    return $('#progress').width(progress + "%");
  };

  AppView.prototype.setDetails = function(details) {
    return $('#details').html(details);
  };

  AppView.prototype.showProgressBar = function(bool) {
    if (bool) {
      return $('#progressParent').css('display', 'block');
    } else {
      return $('#progressParent').css('display', 'none');
    }
  };

  AppView.prototype.showNextStepButton = function(bool, end) {
    if (bool) {
      if (end) {
        $('#nextStepButton').html("Terminer");
        $('#nextStepButton').one('click', (function(_this) {
          return function() {
            _this.goToDefaultService();
            return _this.showNextStepButton(false);
          };
        })(this));
      } else {
        $('#nextStepButton').one('click', (function(_this) {
          return function() {
            _this.operations[_this.currentOperation].terminated = true;
            return _this.showNextStepButton(false);
          };
        })(this));
      }
      return $('#nextStepButton').css('display', 'block');
    } else {
      return $('#nextStepButton').css('display', 'none');
    }
  };

  AppView.prototype.saveFormData = function() {
    this.formData = new Object;
    this.formData.username = $('input#username').val();
    return this.formData.password = $('input#password').val();
  };

  AppView.prototype.changepsw = function() {
    var form;
    this.setOperationName("Changement de votre mot de passe");
    this.setStatusText("Il devrait contenir au moins 8 caractères. Les caractères spéciaux sont fortement recommandés.");
    this.setDetails("");
    this.showProgressBar(false);
    form = "<form onSubmit=\"return false\" id=\"authForm\">\n    <input type=\"password\" id=\"newpassword\" placeholder=\"Nouveau mot de passe\" required/><br/>\n    <button type=\"submit\" id=\"submitButton\" class=\"button\">Changer mon mot de passe</button>\n</form>\n<div id=\"authStatus\"></div>";
    this.setDetails(form);
    return $('form').one('submit', (function(_this) {
      return function() {
        $('#submitButton').html('<img src="spinner-white.svg">');
        $('#newpassword').attr("readonly", "");
        return Utils.changepsw(_this.formData.username, _this.formData.password, $('#newpassword').val(), function(err) {
          if (err) {
            $('#submitButton').css('display', 'none');
            _this.setDetails("Une erreur est survenue: " + err + "<br>Vous pourez changer votre mot de passe ultérieurement depuis le menu configuration de l'application.");
            return _this.showNextStepButton(true);
          } else {
            $('#submitButton').css('display', 'none');
            _this.formData.password = $('#newpassword').val();
            _this.setStatusText("Votre mot de passe à bien été mis à jour.");
            _this.setDetails("");
            return _this.showNextStepButton(true);
          }
        });
      };
    })(this));
  };

  AppView.prototype.importMailAccount = function() {
    this.setOperationName("Importation de votre compte mail ISEN");
    this.setStatusText("");
    this.setDetails("");
    this.showProgressBar(false);
    return Utils.isMailActive((function(_this) {
      return function(err, active) {
        if (err) {
          _this.setDetails("Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation du compte mail depuis le menu configuration de l'application.");
          return _this.showNextStepButton(true);
        } else if (active) {
          _this.setStatusText('Importation en cours...<img id=spinner src="spinner.svg">');
          return Utils.importMailAccount({
            username: _this.formData.username,
            password: _this.formData.password
          }, function(err, imported) {
            if (err) {
              _this.setStatusText('Importation en cours...');
              _this.setDetails("Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation de votre mail ISEN depuis le menu configuration de l'application.");
              return _this.showNextStepButton(true);
            } else if (imported) {
              _this.setStatusText("Importation du compte e-mail terminée.");
              _this.setDetails("");
              _this.setProgress(100);
              return _this.showNextStepButton(true);
            } else {
              _this.setStatusText("Votre compte e-mail ISEN est déjà configuré dans votre Cozy.");
              _this.setDetails("");
              _this.setProgress(100);
              return _this.showNextStepButton(true);
            }
          });
        } else {
          _this.setStatusText("Cette fonctionnalité a été désactivée par l'administrateur de l'application.");
          _this.setDetails("");
          _this.setProgress(100);
          return _this.showNextStepButton(true);
        }
      };
    })(this));
  };

  AppView.prototype.importAdminContacts = function() {
    this.setOperationName("Importation des contacts administratifs");
    this.setStatusText("");
    this.setDetails("");
    this.showProgressBar(false);
    return Utils.isAdminContactsActive((function(_this) {
      return function(err, active) {
        if (err) {
          _this.setDetails("Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts administratifs depuis le menu configuration de l'application.");
          return _this.showNextStepButton(true);
        } else if (active) {
          _this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur...<img id=spinner src="spinner.svg">');
          return Utils.importAdminContacts(function(err) {
            if (err) {
              _this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur...');
              _this.setDetails("Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation des contacts administratifs depuis le menu configuration de l'application.");
              return _this.showNextStepButton(true);
            } else {
              _this.setStatusText('Etape 2/2 : Enregistrement des contacts administratifs dans votre cozy...<img id=spinner src="spinner.svg">');
              _this.setProgress(0);
              _this.showProgressBar(true);
              _this.lastStatus = new Object;
              _this.lastStatus.done = 0;
              Utils.getAdminImportContactStatus(_this.checkAdminContactsImportStatus);
              return _this.timer = setInterval(function() {
                return Utils.getAdminImportContactStatus(_this.checkAdminContactsImportStatus);
              }, 200);
            }
          });
        } else {
          _this.setStatusText("Cette fonctionnalité a été désactivée par l'administrateur de l'application.");
          _this.setDetails("");
          _this.setProgress(100);
          return _this.showNextStepButton(true);
        }
      };
    })(this));
  };

  AppView.prototype.checkAdminContactsImportStatus = function(err, status) {
    var details;
    if (err) {
      return console.log(err);
    } else {
      if (status.done > this.lastStatus.done) {
        this.lastStatus = status;
        details = status.done + " contact(s) traités sur " + status.total + ".";
        if (status.succes !== 0) {
          details += "<br>" + status.succes + " contact(s) crée(s).";
        }
        if (status.modified !== 0) {
          details += "<br>" + status.modified + " contact(s) modifié(s).";
        }
        if (status.notmodified !== 0) {
          details += "<br>" + status.notmodified + " contact(s) non modifié(s).";
        }
        if (status.error !== 0) {
          details += "<br>" + status.error + " contact(s) n'ont pu être importé(s).";
        }
        this.setDetails(details);
        this.setProgress((100 * status.done) / status.total);
        if (status.done === status.total) {
          this.setStatusText("Importation des contacts terminée.");
          clearInterval(this.timer);
          return this.showNextStepButton(true);
        }
      }
    }
  };

  AppView.prototype.retrieveStudentsContacts = function() {
    this.setOperationName("Importation des contacts élèves");
    this.setStatusText("");
    this.setDetails("");
    this.lastGroup = "";
    this.showProgressBar(false);
    return Utils.isStudentsContactsActive((function(_this) {
      return function(err, active) {
        if (err) {
          _this.setDetails("Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts élèves depuis le menu configuration de l'application.");
          return _this.showNextStepButton(true);
        } else if (active) {
          _this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur. Cette opération peut prendre plusieurs minutes...<img id=spinner src="spinner.svg">');
          return Utils.importStudentsContacts(function(err) {
            if (err) {
              _this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur.');
              _this.setDetails("Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts élèves depuis le menu configuration de l'application.");
              return _this.showNextStepButton(true);
            } else {
              Utils.getStudentsImportRetrieveStatus(_this.checkStudentsContactsRetrieveStatus);
              return _this.timer = setInterval(function() {
                return Utils.getStudentsImportRetrieveStatus(_this.checkStudentsContactsRetrieveStatus);
              }, 500);
            }
          });
        } else {
          _this.setStatusText("Cette fonctionnalité a été désactivée par l'administrateur de l'application.");
          _this.setDetails("");
          _this.setProgress(100);
          return _this.showNextStepButton(true);
        }
      };
    })(this));
  };

  AppView.prototype.importStudentsContacts = function() {
    this.setOperationName("Importation des contacts élèves");
    this.setStatusText("");
    this.setDetails("");
    this.showProgressBar(true);
    this.setStatusText('Etape 2/2 : Enregistrement des contacts élèves dans votre cozy...<img id=spinner src="spinner.svg">');
    this.setProgress(0);
    this.showProgressBar(true);
    this.lastStatus = new Object;
    this.lastStatus.done = 0;
    Utils.getStudentsImportContactStatus(this.checkStudentsContactsImportStatus);
    return this.timer = setInterval((function(_this) {
      return function() {
        return Utils.getStudentsImportContactStatus(_this.checkStudentsContactsImportStatus);
      };
    })(this), 200);
  };

  AppView.prototype.checkStudentsContactsImportStatus = function(err, status) {
    var details;
    if (err) {
      return console.log(err);
    } else {
      if (status.done > this.lastStatus.done) {
        this.lastStatus = status;
        details = status.done + " contact(s) traités sur " + status.total + ".";
        if (status.succes !== 0) {
          details += "<br>" + status.succes + " contact(s) crée(s).";
        }
        if (status.modified !== 0) {
          details += "<br>" + status.modified + " contact(s) modifié(s).";
        }
        if (status.notmodified !== 0) {
          details += "<br>" + status.notmodified + " contact(s) non modifié(s).";
        }
        if (status.error !== 0) {
          details += "<br>" + status.error + " contact(s) n'ont pu être importé(s).";
        }
        this.setDetails(details);
        this.setProgress((100 * status.done) / status.total);
        if (status.done === status.total) {
          this.setStatusText('Etape 2/2 : Enregistrement des contacts dans votre cozy...');
          this.setStatusText("Importation des contacts terminée.");
          clearInterval(this.timer);
          return this.showNextStepButton(true);
        }
      }
    }
  };

  AppView.prototype.checkStudentsContactsRetrieveStatus = function(err, json, over) {
    this.over = false;
    if (err) {
      console.log(err);
      this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur.');
      this.setDetails("Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts élèves depuis le menu configuration de l'application.");
      return this.showNextStepButton(true);
    } else {
      if (json.group !== this.lastGroup) {
        this.lastGroup = json.group;
        this.setDetails('En train d\'explorer le groupe ' + json.group);
      }
      if (over) {
        this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur.');
        this.setStatusText("Récupération des contacts terminée.");
        clearInterval(this.timer);
        return this.operations[this.currentOperation].terminated = true;
      }
    }
  };

  return AppView;

})(BaseView);
});

;require.register("views/logout_view", function(exports, require, module) {
var BaseView, LogoutView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

module.exports = LogoutView = (function(_super) {
  __extends(LogoutView, _super);

  function LogoutView() {
    this.checkLogout = __bind(this.checkLogout, this);
    this.afterRender = __bind(this.afterRender, this);
    this.beforeRender = __bind(this.beforeRender, this);
    this.events = __bind(this.events, this);
    return LogoutView.__super__.constructor.apply(this, arguments);
  }

  LogoutView.prototype.el = 'body';

  LogoutView.prototype.template = require('./templates/logout');

  LogoutView.prototype.events = function() {};

  LogoutView.prototype.getRenderData = function() {
    var res;
    return res = {
      url: this.url
    };
  };

  LogoutView.prototype.beforeRender = function() {
    this.serviceData = new Array;
    return $.ajax({
      type: "GET",
      dataType: "json",
      async: false,
      url: 'servicesList',
      complete: (function(_this) {
        return function(xhr) {
          var data, key, service;
          if (xhr.status === 200) {
            data = xhr.responseJSON;
            for (key in data) {
              service = data[key];
              if (service.clientLogoutUrl) {
                _this.serviceData.push({
                  name: service.displayName,
                  logOutUrl: service.clientLogoutUrl
                });
              }
            }
            return _this.logoutStatus = {
              numServicesToLogOut: _this.serviceData.length + 1,
              numServicesLoggedOut: 0
            };
          } else if (xhr.status === 504) {
            return _this.serviceData.err = "Connection timed out";
          } else {
            return _this.serviceData.err = err;
          }
        };
      })(this)
    });
  };

  LogoutView.prototype.logout = function() {};

  LogoutView.prototype.afterRender = function() {
    var key, onLoad, service, _ref, _results;
    this.timoutId = setTimeout((function(_this) {
      return function() {
        console.log("Certains services n'ont pas répondus à temps sur leur url de déconnexion. Vous allez être tout de même redirigé sur la page de login.");
        return window.location = "#login";
      };
    })(this), 5000);
    console.log("Déconnexion de l'application cozy...");
    $.ajax({
      type: "GET",
      dataType: "json",
      async: true,
      url: "logout",
      complete: (function(_this) {
        return function(xhr) {
          var data;
          if (xhr.status === 200) {
            data = xhr.responseJSON;
            if (data.error) {
              console.log("L'application cozy à renvoyée l'erreur suivante: " + data.error);
            } else {
              console.log("L'application cozy est déconnectée du serveur CAS.");
              _this.checkLogout();
            }
          }
          if (xhr.status === 504) {
            return console.error("Connection timed out");
          } else {
            return console.log("Impossible de joindre l'application cozy: " + err);
          }
        };
      })(this)
    });
    if (!this.serviceData.err) {
      _ref = this.serviceData;
      _results = [];
      for (key in _ref) {
        service = _ref[key];
        console.log('Déconnexion du service ' + service.name + ' sur l\'url ' + service.logOutUrl + ' ...');
        onLoad = (function(_this) {
          return function() {
            var sname;
            sname = service.name;
            return function() {
              console.log('Service ' + sname + ' déconecté.');
              return _this.checkLogout();
            };
          };
        })(this);
        _results.push($("#logoutIframes").append('<iframe src="' + service.logOutUrl + '"></iframe>').children().last().one("load", onLoad()));
      }
      return _results;
    } else {
      return console.log('Une erreur est survenue lors de la récupération de la liste des services: ' + this.serviceData.err);
    }
  };

  LogoutView.prototype.checkLogout = function() {
    this.logoutStatus.numServicesLoggedOut++;
    if (this.logoutStatus.numServicesLoggedOut === this.logoutStatus.numServicesToLogOut) {
      console.log('Déconnexion de tout les services et du serveur CAS effectuée.');
      clearTimeout(this.timoutId);
      return window.location = "#login";
    }
  };

  return LogoutView;

})(BaseView);
});

;require.register("views/page_view", function(exports, require, module) {
var AppView, BaseView, PageView, Utils,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

AppView = require('views/app_view');

Utils = require('../lib/utils');

module.exports = PageView = (function(_super) {
  __extends(PageView, _super);

  function PageView() {
    this.checkStudentsContactsRetrieveStatus = __bind(this.checkStudentsContactsRetrieveStatus, this);
    this.checkStudentsContactsImportStatus = __bind(this.checkStudentsContactsImportStatus, this);
    this.importStudentsContacts = __bind(this.importStudentsContacts, this);
    this.retrieveStudentsContacts = __bind(this.retrieveStudentsContacts, this);
    this.checkAdminContactsImportStatus = __bind(this.checkAdminContactsImportStatus, this);
    this.importAdminContacts = __bind(this.importAdminContacts, this);
    this.importMailAccount = __bind(this.importMailAccount, this);
    this.changepsw = __bind(this.changepsw, this);
    this.showEndStepButton = __bind(this.showEndStepButton, this);
    this.showProgressBar = __bind(this.showProgressBar, this);
    this.setDetails = __bind(this.setDetails, this);
    this.setProgress = __bind(this.setProgress, this);
    this.setStatusText = __bind(this.setStatusText, this);
    this.setOperationName = __bind(this.setOperationName, this);
    this.enableButtons = __bind(this.enableButtons, this);
    this.bindMenuOp = __bind(this.bindMenuOp, this);
    this.hideError = __bind(this.hideError, this);
    this.showError = __bind(this.showError, this);
    this.afterRender = __bind(this.afterRender, this);
    this.renderPage = __bind(this.renderPage, this);
    this.events = __bind(this.events, this);
    return PageView.__super__.constructor.apply(this, arguments);
  }

  PageView.prototype.el = 'body';

  PageView.prototype.template = require('./templates/page');

  PageView.prototype.error = '';

  PageView.prototype.events = function() {
    return {
      'click #closeError': 'hideError',
      'keydown': 'hideError'
    };
  };

  PageView.prototype.isOperationActive = false;

  PageView.prototype.getRenderData = function() {
    var res;
    return res = {
      url: this.url
    };
  };

  PageView.prototype.renderPage = function(pageid) {
    this.pageid = pageid;
    return $.ajax({
      type: "GET",
      dataType: "json",
      async: false,
      url: 'authUrl/' + pageid,
      complete: (function(_this) {
        return function(xhr) {
          switch (xhr.status) {
            case 401:
              window.location = "#login";
              break;
            case 400:
              _this.error = "Unknown service " + pageid;
              _this.url = "";
              break;
            case 200:
              _this.url = xhr.responseJSON.url;
              break;
            case 504:
              _this.error = "Request timed out";
              break;
            default:
              _this.error = xhr.responseText;
              console.log(xhr.responseJSON);
          }
          document.title = window.location;
          return _this.render();
        };
      })(this)
    });
  };

  PageView.prototype.afterRender = function() {
    if (this.error) {
      this.showError(this.error);
    }
    $.ajax({
      type: "GET",
      dataType: "json",
      async: false,
      url: 'servicesList',
      complete: (function(_this) {
        return function(xhr) {
          var categorie, data, idCurrentService, key, li, menu, menuList, service, tabService, _results;
          if (xhr.status === 200) {
            data = xhr.responseJSON;
            menu = new Array;
            for (key in data) {
              service = data[key];
              if (menu[service.category] === void 0) {
                menu[service.category] = new Array;
              }
              menu[service.category].push(service);
            }
            _results = [];
            for (categorie in menu) {
              tabService = menu[categorie];
              menuList = '<li><span>' + categorie + '</span><ul>';
              for (key in tabService) {
                service = tabService[key];
                idCurrentService = "";
                if (service.clientServiceUrl === _this.pageid) {
                  idCurrentService = ' id="currentService"';
                  if (service.clientRedirectPage) {
                    _this.redirectUrl = service.clientRedirectPage;
                    if (service.clientRedirectTimeOut) {
                      setTimeout(function() {
                        return $("#app").attr("src", _this.redirectUrl);
                      }, service.clientRedirectTimeOut);
                    } else {
                      $("#app").one("load", function() {
                        return $("#app").attr("src", _this.redirectUrl);
                      });
                    }
                  }
                }
                li = '<li class="serviceButton"' + idCurrentService + '> <a href="#' + service.clientServiceUrl + '"> <i class="' + service.clientIcon + '"></i> <span>' + service.displayName + '</span> </a> </li>';
                menuList += li;
              }
              menuList += '</ul></li>';
              _results.push($("#servicesMenu").append(menuList));
            }
            return _results;
          } else if (xhr.status === 504) {
            return _this.showError("Request timed out");
          } else {
            data = xhr;
            return _this.showError(data.status + " : " + data.statusText + "<br>" + data.responseText);
          }
        };
      })(this)
    });
    return this.bindMenuOp();
  };

  PageView.prototype.showError = function(err) {
    $("#errorText").html(err);
    $("#errors").removeClass('off-error');
    return $("#errors").addClass('on-error');
  };

  PageView.prototype.hideError = function(e) {
    if (e.type === "click" || e.keyCode === 13 || e.keyCode === 27) {
      $("#errors").removeClass('on-error');
      return $("#errors").addClass('off-error');
    }
  };

  PageView.prototype.bindMenuOp = function() {
    var that;
    that = this;
    $('.paramsButton').on('click', function() {
      $('#modalBackground').css('display', 'block');
      return $('#replayOp').css('display', 'block');
    });
    $('#close').on('click', function() {
      if (!that.isOperationActive) {
        $('#modalBackground').css('display', 'none');
        return $('#replayOp').css('display', 'none');
      }
    });
    $('#mail').on('click', function() {
      if (!that.isOperationActive) {
        $(this).addClass('active');
        that.enableButtons(false);
        that.isOperationActive = true;
        return that.importMailAccount();
      }
    });
    $('#ca').on('click', function() {
      if (!that.isOperationActive) {
        $(this).addClass('active');
        that.enableButtons(false);
        that.isOperationActive = true;
        return that.importAdminContacts();
      }
    });
    $('#ce').on('click', function() {
      if (!that.isOperationActive) {
        $(this).addClass('active');
        that.enableButtons(false);
        that.isOperationActive = true;
        return that.retrieveStudentsContacts();
      }
    });
    $('#pass').on('click', function() {
      if (!that.isOperationActive) {
        $(this).addClass('active');
        that.enableButtons(false);
        that.isOperationActive = true;
        return that.changepsw();
      }
    });
    return $('#raz').on('click', (function(_this) {
      return function() {
        if (!that.isOperationActive) {
          $(_this).addClass('active');
          that.enableButtons(false);
          return window.location = '#logout';
        }
      };
    })(this));
  };

  PageView.prototype.enableButtons = function(bool) {
    if (bool) {
      $('#mail').removeClass('active').removeClass('inactive');
      $('#ca').removeClass('active').removeClass('inactive');
      $('#ce').removeClass('active').removeClass('inactive');
      $('#pass').removeClass('active').removeClass('inactive');
      $('#raz').removeClass('active').removeClass('inactive');
      return $('#close').removeClass('closeInactive');
    } else {
      $('#mail').addClass('inactive');
      $('#ca').addClass('inactive');
      $('#ce').addClass('inactive');
      $('#pass').addClass('inactive');
      $('#raz').addClass('inactive');
      return $('#close').addClass('closeInactive');
    }
  };

  PageView.prototype.setOperationName = function(operationName) {
    return $('#OperationName').html(operationName);
  };

  PageView.prototype.setStatusText = function(statusText) {
    return $('#statusText').html(statusText);
  };

  PageView.prototype.setProgress = function(progress) {
    return $('#progress').width(progress + "%");
  };

  PageView.prototype.setDetails = function(details) {
    return $('#details').html(details);
  };

  PageView.prototype.showProgressBar = function(bool) {
    if (bool) {
      return $('#progressParent').css('display', 'block');
    } else {
      return $('#progressParent').css('display', 'none');
    }
  };

  PageView.prototype.showEndStepButton = function() {
    $('#nextStepButton').one('click', (function(_this) {
      return function() {
        _this.isOperationActive = false;
        _this.enableButtons(true);
        _this.setOperationName("");
        _this.setStatusText("");
        _this.setDetails("");
        _this.showProgressBar(false);
        return $('#nextStepButton').css('display', 'none');
      };
    })(this));
    return $('#nextStepButton').css('display', 'block');
  };

  PageView.prototype.changepsw = function() {
    var form;
    this.setOperationName("Changement de votre mot de passe");
    this.setStatusText("Il devrait contenir au moins 8 caractères. Les caractères spéciaux sont fortement recommandés.");
    this.setDetails("");
    this.showProgressBar(false);
    form = "<form onSubmit=\"return false\" id=\"authForm\">\n    <input type=\"text\" id=\"login\" placeholder=\"Login\" required/><br/>\n    <input type=\"password\" id=\"oldpassword\" placeholder=\"Ancien mot de passe\" required/><br/>\n    <input type=\"password\" id=\"newpassword\" placeholder=\"Nouveau mot de passe\" required/><br/>\n    <button type=\"submit\" id=\"submitButton\" class=\"button\">Changer mon mot de passe</button>\n</form>\n<div id=\"authStatus\"></div>";
    this.setDetails(form);
    return $('form').one('submit', (function(_this) {
      return function() {
        $('#submitButton').html('<img src="spinner-white.svg">');
        $('#newpassword').attr("readonly", "");
        return Utils.changepsw($('#login').val(), $('#oldpassword').val(), $('#newpassword').val(), function(err) {
          if (err) {
            $('#submitButton').css('display', 'none');
            _this.setDetails("Une erreur est survenue: " + err);
            return _this.showEndStepButton();
          } else {
            $('#submitButton').css('display', 'none');
            _this.setStatusText("Votre mot de passe à bien été mis à jour.");
            _this.setDetails("");
            return _this.showEndStepButton();
          }
        });
      };
    })(this));
  };

  PageView.prototype.importMailAccount = function() {
    this.setOperationName("Importation de votre compte mail ISEN");
    this.setStatusText("");
    this.setDetails("");
    this.showProgressBar(false);
    return Utils.isMailActive((function(_this) {
      return function(err, active) {
        if (err) {
          _this.setDetails("Une erreur est survenue: " + err);
          return _this.showEndStepButton();
        } else if (active) {
          _this.setStatusText('Importation en cours...<img id=spinner src="spinner.svg">');
          return Utils.importMailAccount({
            username: _this.formData.username,
            password: _this.formData.password
          }, function(err, imported) {
            if (err) {
              _this.setStatusText('Importation en cours...');
              _this.setDetails("Une erreur est survenue: " + err);
              return _this.showEndStepButton();
            } else if (imported) {
              _this.setStatusText("Importation du compte e-mail terminée.");
              _this.setDetails("");
              _this.setProgress(100);
              return _this.showEndStepButton();
            } else {
              _this.setStatusText("Votre compte e-mail ISEN est déjà configuré dans votre Cozy.");
              _this.setDetails("");
              _this.setProgress(100);
              return _this.showEndStepButton();
            }
          });
        } else {
          _this.setStatusText("Cette fonctionnalité a été désactivée par l'administrateur de l'application.");
          _this.setDetails("");
          _this.setProgress(100);
          return _this.showEndStepButton();
        }
      };
    })(this));
  };

  PageView.prototype.importAdminContacts = function() {
    this.setOperationName("Importation des contacts administratifs");
    this.setStatusText("");
    this.setDetails("");
    this.showProgressBar(false);
    return Utils.isAdminContactsActive((function(_this) {
      return function(err, active) {
        if (err) {
          _this.setDetails("Une erreur est survenue: " + err);
          return _this.showEndStepButton();
        } else if (active) {
          _this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur...<img id=spinner src="spinner.svg">');
          return Utils.importAdminContacts(function(err) {
            if (err) {
              _this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur...');
              _this.setDetails("Une erreur est survenue: " + err);
              return _this.showEndStepButton();
            } else {
              _this.setStatusText('Etape 2/2 : Enregistrement des contacts administratifs dans votre cozy...<img id=spinner src="spinner.svg">');
              _this.setProgress(0);
              _this.showProgressBar(true);
              _this.lastStatus = new Object;
              _this.lastStatus.done = 0;
              Utils.getAdminImportContactStatus(_this.checkAdminContactsImportStatus);
              return _this.timer = setInterval(function() {
                return Utils.getAdminImportContactStatus(_this.checkAdminContactsImportStatus);
              }, 200);
            }
          });
        } else {
          _this.setStatusText("Cette fonctionnalité a été désactivée par l'administrateur de l'application.");
          _this.setDetails("");
          _this.setProgress(100);
          return _this.showEndStepButton();
        }
      };
    })(this));
  };

  PageView.prototype.checkAdminContactsImportStatus = function(err, status) {
    var details;
    if (err) {
      return console.log(err);
    } else {
      if (status.done > this.lastStatus.done) {
        this.lastStatus = status;
        details = status.done + " contact(s) traités sur " + status.total + ".";
        if (status.succes !== 0) {
          details += "<br>" + status.succes + " contact(s) crée(s).";
        }
        if (status.modified !== 0) {
          details += "<br>" + status.modified + " contact(s) modifié(s).";
        }
        if (status.notmodified !== 0) {
          details += "<br>" + status.notmodified + " contact(s) non modifié(s).";
        }
        if (status.error !== 0) {
          details += "<br>" + status.error + " contact(s) n'ont pu être importé(s).";
        }
        this.setDetails(details);
        this.setProgress((100 * status.done) / status.total);
        if (status.done === status.total) {
          this.setStatusText("Importation des contacts terminée.");
          clearInterval(this.timer);
          return this.showEndStepButton();
        }
      }
    }
  };

  PageView.prototype.retrieveStudentsContacts = function() {
    this.setOperationName("Importation des contacts élèves");
    this.setStatusText("");
    this.setDetails("");
    this.lastGroup = "";
    this.showProgressBar(false);
    return Utils.isStudentsContactsActive((function(_this) {
      return function(err, active) {
        if (err) {
          _this.setDetails("Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts élèves depuis le menu configuration de l'application.");
          return _this.showNextStepButton(true);
        } else if (active) {
          _this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur. Cette opération peut prendre plusieurs minutes...<img id=spinner src="spinner.svg">');
          return Utils.importStudentsContacts(function(err) {
            if (err) {
              _this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur.');
              _this.setDetails("Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts élèves depuis le menu configuration de l'application.");
              return _this.showNextStepButton(true);
            } else {
              Utils.getStudentsImportRetrieveStatus(_this.checkStudentsContactsRetrieveStatus);
              return _this.timer = setInterval(function() {
                return Utils.getStudentsImportRetrieveStatus(_this.checkStudentsContactsRetrieveStatus);
              }, 500);
            }
          });
        } else {
          _this.setStatusText("Cette fonctionnalité a été désactivée par l'administrateur de l'application.");
          _this.setDetails("");
          _this.setProgress(100);
          return _this.showEndStepButton();
        }
      };
    })(this));
  };

  PageView.prototype.importStudentsContacts = function() {
    this.setOperationName("Importation des contacts élèves");
    this.setStatusText("");
    this.setDetails("");
    this.showProgressBar(true);
    this.setStatusText('Etape 2/2 : Enregistrement des contacts élèves dans votre cozy...<img id=spinner src="spinner.svg">');
    this.setProgress(0);
    this.showProgressBar(true);
    this.lastStatus = new Object;
    this.lastStatus.done = 0;
    Utils.getStudentsImportContactStatus(this.checkStudentsContactsImportStatus);
    return this.timer = setInterval((function(_this) {
      return function() {
        return Utils.getStudentsImportContactStatus(_this.checkStudentsContactsImportStatus);
      };
    })(this), 200);
  };

  PageView.prototype.checkStudentsContactsImportStatus = function(err, status) {
    var details;
    if (err) {
      return console.log(err);
    } else {
      if (status.done > this.lastStatus.done) {
        this.lastStatus = status;
        details = status.done + " contact(s) traités sur " + status.total + ".";
        if (status.succes !== 0) {
          details += "<br>" + status.succes + " contact(s) crée(s).";
        }
        if (status.modified !== 0) {
          details += "<br>" + status.modified + " contact(s) modifié(s).";
        }
        if (status.notmodified !== 0) {
          details += "<br>" + status.notmodified + " contact(s) non modifié(s).";
        }
        if (status.error !== 0) {
          details += "<br>" + status.error + " contact(s) n'ont pu être importé(s).";
        }
        this.setDetails(details);
        this.setProgress((100 * status.done) / status.total);
        if (status.done === status.total) {
          this.setStatusText('Etape 2/2 : Enregistrement des contacts dans votre cozy...');
          this.setStatusText("Importation des contacts terminée.");
          clearInterval(this.timer);
          return this.showEndStepButton();
        }
      }
    }
  };

  PageView.prototype.checkStudentsContactsRetrieveStatus = function(err, json, over) {
    this.over = false;
    if (err) {
      console.log(err);
      this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur.');
      this.setDetails("Une erreur est survenue : " + err + "<br>Vous pourez relancer l'importation des contacts élèves depuis le menu configuration de l'application.");
      return this.showEndStepButton();
    } else {
      if (json.group !== this.lastGroup) {
        this.lastGroup = json.group;
        this.setDetails('En train d\'explorer le groupe ' + json.group);
      }
      if (over) {
        this.setStatusText('Etape 1/2 : Récupération des contacts depuis le serveur.');
        this.setStatusText("Récupération des contacts terminée.");
        clearInterval(this.timer);
        return this.importStudentsContacts();
      }
    }
  };

  return PageView;

})(BaseView);
});

;require.register("views/templates/home", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<div id=\"content\"><div id=\"ImportingStatus\"><img id=\"logo\" src=\"isenlogo.png\"/><p id=\"OperationName\">Connexion à l'ENT</p><p id=\"statusText\">Veuillez renseigner vos identifiants CAS:</p><div id=\"progressParent\"><div id=\"progress\"></div></div><div id=\"details\"><form onSubmit=\"return false\" id=\"authForm\"><input type=\"text\" id=\"username\" placeholder=\"Nom d'utilisateur\" required=\"required\"/><br/><input type=\"password\" id=\"password\" placeholder=\"Mot de passe\" required=\"required\"/><br/><button type=\"submit\" id=\"submitButton\" class=\"button\">Se connecter</button></form><div id=\"authStatus\"></div></div><button type=\"button\" id=\"nextStepButton\" class=\"button\">Passer à l'étape suivante</button></div></div>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/logout", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<div id=\"home\"><div id=\"status\">Déconnexion...</div><div id=\"logoutIframes\" style=\"display:none\"></div></div>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/page", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),url = locals_.url;
buf.push("<div id=\"content\"><div id=\"errors\"><p>Erreur</p><p id=\"errorText\"></p><span id=\"closeError\" class=\"on-error\">ok</span></div><div id=\"modalBackground\"></div><div id=\"replayOp\"><i id=\"close\" class=\"fa fa-times\"></i><p id=\"replayTitle\">Configuration</p><ul><li id=\"mail\">Importer mon compte mail ISEN</li><li id=\"ca\">Importer les contacts administratifs</li><li id=\"ce\">Importer les contacts élèves</li><li id=\"pass\">Changer mon mot de passe</li><li id=\"raz\">Réinitialiser l'application</li></ul><p id=\"OperationName\"></p><p id=\"statusText\"></p><div id=\"progressParent\"><div id=\"progress\"></div></div><div id=\"details\"></div><button type=\"button\" id=\"nextStepButton\" class=\"button\">Terminer</button></div><div id=\"sidebar\"><ul id=\"servicesMenu\"></ul><span class=\"paramsButton\"><i class=\"fa fa-cog\"></i><span>Configuration</span></span></div><iframe id=\"app\"" + (jade.attr("src", "" + (url) + "", true, false)) + "></iframe></div>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;
//# sourceMappingURL=app.js.map