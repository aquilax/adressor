// Generated by CoffeeScript 1.6.1
(function() {
  var __slice = [].slice;

  window.log = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return console.log(args);
  };

  window.Adr = window.Adr || {};

  window.Adr.Config = {
    _key: 'Adressor',
    _presetKey: 'presets',
    _data: {},
    _default: {
      adsClass: '.wikia-ad',
      presets: {}
    },
    load: function(callback) {
      var self;
      self = this;
      chrome.storage.local.get(this._key, function(items) {
        self._data = items[self._key] || self._default;
        if (callback != null) {
          return callback(items);
        }
      });
      return true;
    },
    save: function(callback) {
      var data;
      callback = callback || function() {};
      data = {};
      data[this._key] = this._data;
      chrome.storage.local.set(data, callback);
      return true;
    },
    get: function(key) {
      return this._data[key];
    },
    set: function(key, value) {
      this._data[key] = value;
      return this.save();
    },
    addPreset: function(name, data) {
      this._data[this._presetKey][name] = data;
      return this.save();
    },
    getPreset: function(name) {
      return this._data[this._presetKey][name];
    },
    removePreset: function(name) {
      delete this._data[this._presetKey][name];
      return this.save();
    },
    getPresets: function() {
      return Object.keys(this._data[this._presetKey]);
    },
    jExport: function() {
      return JSON.stringify(this._data);
    },
    jImport: function(json) {
      this._data = JSON.parse(json);
      if (this._data == null) {
        return this._data = this._default;
      }
    }
  };

  window.Adr.Popup = {
    _config: Adr.Config,
    $positions: null,
    init: function() {
      var self;
      self = this;
      chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
        if (self[request.exec] != null) {
          return self[request.exec].apply(self, __slice.call(request.args).concat([sendResponse]));
        }
      });
      return this._config.load(function() {
        return self._updatePresets();
      });
    },
    installInTab: function($positions, callback) {
      var self;
      self = this;
      this.$positions = $positions;
      return this.getCurrentTab(function(tab) {
        return self.install(tab, function() {
          return self.getPositions(callback);
        });
      });
    },
    install: function(tab, callback) {
      return chrome.tabs.executeScript(tab.id, {
        file: "assets/js/external/jquery-2.0.3.min.js",
        allFrames: false
      }, function() {
        return chrome.tabs.executeScript(tab.id, {
          file: "assets/js/injection.js",
          allFrames: false
        }, function() {
          return callback();
        });
      });
    },
    getCurrentTab: function(callback) {
      return chrome.tabs.query({
        active: true,
        currentWindow: true
      }, function(tabs) {
        return callback(tabs[0]);
      });
    },
    send: function() {
      var args, callback, cmd, _i;
      cmd = arguments[0], args = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), callback = arguments[_i++];
      return chrome.runtime.sendMessage({
        exec: cmd,
        args: args
      }, callback || function() {});
    },
    sendCS: function() {
      var args, callback, exec, _i;
      exec = arguments[0], args = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), callback = arguments[_i++];
      return this.getCurrentTab(function(tab) {
        return chrome.tabs.sendMessage(tab.id, {
          exec: exec,
          args: args
        }, callback || function() {});
      });
    },
    getPositions: function(callback) {
      var self;
      self = this;
      return this.sendCS('getPositions', this._config.get('adsClass'), function(response) {
        self.renderPositions(response);
        if (callback != null) {
          return callback();
        }
      });
    },
    renderPositions: function(positions) {
      var content, template;
      this.$positions.empty();
      if ((positions != null) && positions.length) {
        $('#command').show();
        template = $('#t_positions').text();
        content = Mustache.render(template, {
          ads: positions
        });
      } else {
        template = $('#t_wrong_tab').text();
        content = Mustache.render(template, {});
      }
      return this.$positions.append(content);
    },
    update: function() {
      var data;
      data = this.collectData(this.$positions);
      return this.sendCS('updatePositions', data, function(response) {
        return log(response);
      });
    },
    collectData: function($container) {
      var data;
      data = [];
      $container.find('tbody tr').each(function(index, element) {
        var $el;
        $el = $(element);
        return data.push({
          id: $el.data('id'),
          width: $el.find('.width').val(),
          height: $el.find('.height').val(),
          html: $el.find('.html').val()
        });
      });
      return data;
    },
    highlight: function(id) {
      return this.sendCS('highlight', id, function() {});
    },
    loadPreset: function(preset) {
      var positions;
      positions = this._config.getPreset(preset);
      if (positions != null) {
        return this.renderPositions(positions);
      }
    },
    savePreset: function(preset) {
      if (preset !== '') {
        this._config.addPreset(preset, this.collectData(this.$positions));
        return this._updatePresets();
      }
    },
    _updatePresets: function() {
      var content, presets, template;
      presets = this._config.getPresets();
      if (presets.length) {
        template = $('#t_options').text();
        content = Mustache.render(template, {
          presets: presets
        });
        return $('#presets').html(content);
      }
    }
  };

  Adr.Popup.init();

  $(function() {
    var $positions, $presets;
    $positions = $('#positions');
    $presets = $('#presets');
    return Adr.Popup.installInTab($positions, function() {
      $('#update').bind('click', function(event) {
        event.preventDefault();
        return Adr.Popup.update();
      });
      $positions.on('click', 'input.reset', function() {
        var $height, $html, $row, $width;
        $row = $(this).parent().parent();
        $width = $row.find('.width');
        $width.val($width.data('val'));
        $height = $row.find('.height');
        $height.val($height.data('val'));
        $html = $row.find('.html');
        return $html.val($html.data('val'));
      });
      $positions.on('click', 'input.image', function() {
        var $row;
        $row = $(this).parent().parent();
        return $row.find('.html').html('[image]');
      });
      $(document).on({
        mouseenter: function() {
          var $row, id;
          $row = $(this).parent();
          id = $row.data('id');
          return Adr.Popup.highlight(id);
        }
      }, '#positions td.title');
      $('#load_preset').bind('click', function(event) {
        var preset;
        event.preventDefault();
        preset = $presets.val();
        if (preset !== '') {
          return Adr.Popup.loadPreset(preset);
        }
      });
      return $('#save_preset').bind('click', function(event) {
        var preset;
        event.preventDefault();
        preset = window.prompt("Please enter name for the preset", "");
        if (preset !== '') {
          return Adr.Popup.savePreset(preset);
        }
      });
    });
  });

}).call(this);
