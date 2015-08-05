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
var Utils,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

module.exports = Utils = (function() {
  function Utils() {
    this.importContacts = __bind(this.importContacts, this);
    this.importMailAccount = __bind(this.importMailAccount, this);
  }

  Utils.prototype.importMailAccount = function() {};

  Utils.prototype.importContacts = function(callback) {
    return $.ajax({
      type: "GET",
      dataType: "text",
      async: true,
      url: 'contacts',
      complete: (function(_this) {
        return function(xhr) {
          switch (xhr.status) {
            case 202:
              return callback(null);
            default:
              return callback(xhr.responseText);
          }
        };
      })(this)
    });
  };

  Utils.prototype.getImportContactStatus = function(callback) {
    return $.ajax({
      type: "GET",
      dataType: "json",
      async: true,
      url: 'contactImportStatus',
      complete: (function(_this) {
        return function(xhr) {
          if (xhr.status === 200 || xhr.status === 304 || xhr.status === 201) {
            return callback(null, xhr.responseJSON);
          } else {
            return callback(xhr.responseText);
          }
        };
      })(this)
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
    return mainView.renderIfNotLoggedIn();
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

Utils = new Utils();

module.exports = AppView = (function(_super) {
  __extends(AppView, _super);

  function AppView() {
    this.checkStatus = __bind(this.checkStatus, this);
    this.importContacts = __bind(this.importContacts, this);
    this.importMailAccount = __bind(this.importMailAccount, this);
    this.setDetails = __bind(this.setDetails, this);
    this.setProgress = __bind(this.setProgress, this);
    this.setStatusText = __bind(this.setStatusText, this);
    this.setOperationName = __bind(this.setOperationName, this);
    this.buildOperationTodoList = __bind(this.buildOperationTodoList, this);
    this.goToDefaultService = __bind(this.goToDefaultService, this);
    this.loginCAS = __bind(this.loginCAS, this);
    this.renderIfNotLoggedIn = __bind(this.renderIfNotLoggedIn, this);
    this.events = __bind(this.events, this);
    return AppView.__super__.constructor.apply(this, arguments);
  }

  AppView.prototype.el = 'body.application';

  AppView.prototype.template = require('./templates/home');

  AppView.prototype.events = function() {
    return {
      'submit': this.loginCAS
    };
  };

  AppView.prototype.renderIfNotLoggedIn = function() {
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
              return _this.render();
            case 500:
              return console.log(xhr.responseJSON);
            default:
              return console.log(xhr.responseText);
          }
        };
      })(this)
    });
  };

  AppView.prototype.loginCAS = function() {
    $('#status').html('En cours');
    return $.ajax({
      url: 'login',
      method: 'POST',
      data: {
        username: $('input#username').val(),
        password: $('input#password').val()
      },
      dataType: 'json',
      success: (function(_this) {
        return function(data) {
          if (data.status) {
            $('input#username').attr("readonly", "");
            $('input#password').attr("readonly", "");
            _this.buildOperationTodoList();
            if (_this.operations.length > 0) {
              $('#ImportingStatus').css('display', 'block');
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
                    _this.setOperationName("Opération(s) terminée(s)");
                    _this.setStatusText("Les bisounours préparent l'application, redirection iminente...");
                    _this.setProgress(0);
                    _this.setDetails("");
                    return setTimeout(function() {
                      return _this.goToDefaultService();
                    }, 3000);
                  }
                }
              }, 500);
            } else {
              return _this.goToDefaultService();
            }
          } else {
            return $('#status').html('Erreur');
          }
        };
      })(this),
      error: (function(_this) {
        return function() {
          return $('#status').html('Erreur HTTP');
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
      success: function(data) {
        return window.location = "#" + data;
      }
    });
  };

  AppView.prototype.buildOperationTodoList = function() {
    this.operations = new Array;
    this.operations.push({
      functionToCall: this.importMailAccount,
      launched: false,
      terminated: false
    });
    return this.operations.push({
      functionToCall: this.importContacts,
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

  AppView.prototype.importMailAccount = function() {
    Utils.importMailAccount();
    console.log("The magic unicorn is in the kitchen, eating a delicious apple.");
    this.setOperationName("Importation de votre compte mail ISEN");
    this.setStatusText("Importation en cour...");
    this.setDetails("");
    this.setProgress(0);
    return setTimeout((function(_this) {
      return function() {
        return _this.operations[_this.currentOperation].terminated = true;
      };
    })(this), 5000);
  };

  AppView.prototype.importContacts = function() {
    this.setOperationName("Importation des contacts");
    this.setStatusText("Etape 1/2: Récupération des contacts depuis le serveur...");
    this.setDetails("");
    this.setProgress(0);
    return Utils.importContacts((function(_this) {
      return function(err) {
        if (err) {
          _this.setDetails("Une erreur est survenue: " + err + "<br>Vous pourez relancer l'importation des contacts depuis le menu configuration de l'application.");
          return setTimeout(function() {
            return _this.operations[_this.currentOperation].terminated = true;
          }, 5000);
        } else {
          _this.setStatusText("Etape 2/2: Enregistrement des contacts dans votre cozy...");
          _this.lastStatus = new Object;
          _this.lastStatus.done = 0;
          Utils.getImportContactStatus(_this.checkStatus);
          return _this.timer = setInterval(function() {
            return Utils.getImportContactStatus(_this.checkStatus);
          }, 200);
        }
      };
    })(this));
  };

  AppView.prototype.checkStatus = function(err, status) {
    var details;
    if (err) {
      return console.log(err);
    } else {
      if (status.done >= this.lastStatus.done) {
        this.lastStatus = status;
        details = status.done + " contact(s) importés sur " + status.total + ".";
        if (status.succes !== 0) {
          details += "<br>" + status.succes + "contact(s) crée(s).";
        }
        if (status.modified !== 0) {
          details += "<br>" + status.modified + "contact(s) modifié(s).";
        }
        if (status.notmodified !== 0) {
          details += "<br>" + status.notmodified + "contact(s) non modifié(s).";
        }
        if (status.error !== 0) {
          details += "<br>" + status.error + "contact(s) n'ont pu être importé(s).";
        }
        this.setDetails(details);
        this.setProgress((100 * status.done) / status.total);
        if (status.done === status.total) {
          this.setStatusText("Importation des contacts terminés.");
          clearInterval(this.timer);
          return setTimeout((function(_this) {
            return function() {
              return _this.operations[_this.currentOperation].terminated = true;
            };
          })(this), 3000);
        }
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
      success: (function(_this) {
        return function(data) {
          var key, service;
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
        };
      })(this),
      error: (function(_this) {
        return function(err) {
          return _this.serviceData.err = err;
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
      success: (function(_this) {
        return function(data) {
          if (data.error) {
            return console.log("L'application cozy à renvoyée l'erreur suivante: " + data.error);
          } else {
            console.log("L'application cozy est déconnectée du serveur CAS.");
            return _this.checkLogout();
          }
        };
      })(this),
      error: (function(_this) {
        return function(err) {
          return console.log("Impossible de joindre l'application cozy: " + err);
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
var AppView, BaseView, PageView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

AppView = require('views/app_view');

module.exports = PageView = (function(_super) {
  __extends(PageView, _super);

  function PageView() {
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
            default:
              _this.error = xhr.responseJSON || xhr.responseText;
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
    return $.ajax({
      type: "GET",
      dataType: "json",
      async: false,
      url: 'servicesList',
      complete: (function(_this) {
        return function(xhr) {
          var data, idCurrentService, key, li, service, _results;
          if (xhr.status === 200) {
            data = xhr.responseJSON;
            _results = [];
            for (key in data) {
              service = data[key];
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
              _results.push($("#servicesMenu").append(li));
            }
            return _results;
          } else {
            data = xhr;
            return _this.showError(data.status + " : " + data.statusText + "<br>" + data.responseText);
          }
        };
      })(this)
    });
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

  return PageView;

})(BaseView);
});

;require.register("views/templates/home", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<div id=\"content\"><div id=\"home\"><h1>ENT ISEN</h1><h2>Merci de rentrer vos identifiants</h2><form onSubmit=\"return false\"><input type=\"text\" id=\"username\" placeholder=\"Nom d'utilisateur\"/><br/><input type=\"password\" id=\"password\" placeholder=\"Mot de passe\"/><br/><input type=\"submit\" id=\"submit\" value=\"Se connecter\"/></form><div id=\"status\"></div><div id=\"ImportingStatus\"><p id=\"OperationName\"></p><p id=\"statusText\"></p><div id=\"progress\"></div><p id=\"details\"></p></div></div></div>");;return buf.join("");
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
buf.push("<div id=\"content\"><div id=\"errors\"><p>Erreur</p><p id=\"errorText\"></p><span id=\"closeError\" class=\"on-error\">ok</span></div><div id=\"sidebar\"><ul id=\"servicesMenu\"></ul><span class=\"exitButton\"><a href=\"#logout\"><i class=\"fa fa-sign-out\"></i><span>Déconnexion</span></a></span></div><iframe id=\"app\"" + (jade.attr("src", "" + (url) + "", true, false)) + "></iframe></div>");;return buf.join("");
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