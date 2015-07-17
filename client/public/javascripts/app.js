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
var AppView, PageView, Router,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

AppView = require('views/app_view');

PageView = require('views/page_view');

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
    mainView = new PageView();
    return mainView.logout();
  };

  return Router;

})(Backbone.Router);
});

;require.register("views/app_view", function(exports, require, module) {
var AppView, BaseView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

module.exports = AppView = (function(_super) {
  __extends(AppView, _super);

  function AppView() {
    this.loginCAS = __bind(this.loginCAS, this);
    this.renderIfNotLoggedIn = __bind(this.renderIfNotLoggedIn, this);
    this.events = __bind(this.events, this);
    return AppView.__super__.constructor.apply(this, arguments);
  }

  AppView.prototype.el = 'body.application';

  AppView.prototype.template = require('./templates/home');

  AppView.prototype.canclick = true;

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
      success: (function(_this) {
        return function(data) {
          if (data.isLoggedIn) {
            return window.location = "#moodle";
          } else {
            return _this.render();
          }
        };
      })(this)
    });
  };

  AppView.prototype.loginCAS = function() {
    if (this.canclick) {
      this.canclick = false;
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
              return window.location = "#moodle";
            } else {
              $('#status').html('Erreur');
              return _this.canclick = true;
            }
          };
        })(this),
        error: (function(_this) {
          return function() {
            $('#status').html('Erreur HTTP');
            return _this.canclick = true;
          };
        })(this)
      });
    }
  };

  return AppView;

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

  PageView.prototype.renderPage = function(pageid, oldpage) {
    if (typeof oldpage === 'undefined') {
      oldpage = {
        url: 'moodle'
      };
    }
    return $.get('authUrl/' + pageid, '', (function(_this) {
      return function(data) {
        if (data.error) {
          if (data.error === "No user logged in") {
            window.location = "#login";
            return;
          } else {
            _this.error = data.error;
            _this.url = "";
          }
        } else {
          _this.url = data.url;
        }
        return _this.render();
      };
    })(this), 'json');
  };

  PageView.prototype.logout = function() {
    return $.get('logout', '', (function(_this) {
      return function() {
        return window.location = "#login";
      };
    })(this));
  };

  PageView.prototype.afterRender = function() {
    if (this.error) {
      this.showError(this.error);
    }
    return $.ajax({
      type: "GET",
      dataType: "json",
      async: false,
      url: 'services',
      success: function(data) {
        var key, li, service, _results;
        _results = [];
        for (key in data) {
          service = data[key];
          li = '<li class="serviceButton"> <a href="#' + service.clientServiceUrl + '"> <i class="' + service.clientIcon + '"></i> <span>' + service.displayName + '</span> </a> </li>';
          _results.push($("#servicesMenu").append(li));
        }
        return _results;
      },
      error: (function(_this) {
        return function(err) {
          return _this.showError(err.status + " : " + err.statusText + "<br>" + err.responseText);
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

buf.push("<div id=\"content\"><div id=\"home\"><h1>ENT ISEN</h1><h2>Merci de rentrer vos identifiants</h2><form onSubmit=\"return false\"><input type=\"text\" id=\"username\" placeholder=\"Nom d'utilisateur\"/><br/><input type=\"password\" id=\"password\" placeholder=\"Mot de passe\"/><br/><input type=\"submit\" id=\"submit\" value=\"Se connecter\"/></form><div id=\"status\"></div></div></div>");;return buf.join("");
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
buf.push("<div id=\"content\"><div id=\"errors\"><p>Erreur</p><p id=\"errorText\"></p><span id=\"closeError\" class=\"on-error\">ok</span></div><div id=\"sidebar\"><ul id=\"servicesMenu\"><li class=\"serviceButton\"><a href=\"#lol\"><i class=\"fa fa-heart\"></i><span>LOL, service non existant!</span></a></li></ul><span class=\"exitButton\"><a href=\"#logout\"><i class=\"fa fa-sign-out\"></i><span>Déconnexion</span></a></span></div><iframe" + (jade.attr("src", "" + (url) + "", true, false)) + "></iframe></div>");;return buf.join("");
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