window.log = (args...) ->
	console.log args

window.Adr = window.Adr || {}

window.Adr.Config =

	_key: 'Adressor'
	_presetKey: 'presets'
	_data: {}
	_default:
		adsClass: '.wikia-ad'
		presets: {}

	load: (callback) ->
		self = @
		chrome.storage.local.get @_key, (items) ->
			self._data = items[self._key] || self._default
			callback(items) if callback?
		true

	save: (callback) ->
		callback = callback || ->
		data = {}
		data[@_key] = @_data
		chrome.storage.local.set data,  callback
		true

	get: (key) ->
		@_data[key]
	
	set: (key, value) ->
		@_data[key] = value
		@save()
	
	addPreset: (name, data) ->
		@_data[@_presetKey][name] = data
		@save()
	
	getPreset: (name) ->
		@_data[@_presetKey][name]

	removePreset: (name) ->
		delete @_data[@_presetKey][name]
		@save()

	getPresets: ->
		Object.keys @_data[@_presetKey]

	jExport: ->
		JSON.stringify @_data
	
	jImport: (json) ->
		@_data = JSON.parse json
		@_data = @_default if !@_data?
		@save()

	reset: ->
		@_data = @_default
		@save();

window.Adr.Popup =

	_config: Adr.Config
	$positions: null

	init: ->
		self = @
		chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
			self[request.exec] request.args..., sendResponse if self[request.exec]?
		# TODO: Load is async
		@_config.load ->
			self.updatePresets()
	
	installInTab: ($positions, $throbber, callback) ->
		self = @
		@$positions = $positions
		@$throbber = $throbber
		@lShow()
		@getCurrentTab (tab) ->
			self.install tab, ->
				self.getPositions (callback)
				self.lHide()
					

	install: (tab, callback) ->
		@sendCS 'ping', (response) ->
			if response == undefined
				chrome.tabs.executeScript tab.id,
					file: "assets/js/external/jquery-2.0.3.min.js"
					allFrames: false
				, () ->
					chrome.tabs.executeScript tab.id,
						file: "assets/js/injection.js"
						allFrames: false
					, () ->
						callback()
			else
				callback()

	getCurrentTab: (callback)->
		chrome.tabs.query
			active: true,
			currentWindow: true
		, (tabs) ->
			callback tabs[0]

	send: (cmd, args..., callback) ->
		chrome.runtime.sendMessage
			exec:	cmd
			args:	args
		, callback || () ->

	sendCS: (exec, args..., callback) ->
		@getCurrentTab (tab) ->
			chrome.tabs.sendMessage tab.id,
				exec: exec,
				args: args
			, callback || ()->

	getPositions: (callback) ->
		self = @
		@sendCS 'getPositions', @_config.get('adsClass'), (response) ->
			self.renderPositions response
			callback() if callback?

	renderPositions: (positions)->
		@$positions.empty()
		if positions? && positions.length
			$('#command').show();
			template = $('#t_positions').text();
			content = Mustache.render template, ads: positions
		else
			template = $('#t_wrong_tab').text();
			content = Mustache.render template, {}

		@$positions.append(content)


	update: () ->
		self = @
		@lShow()
		data = @collectData @$positions, true
		@sendCS 'updatePositions', data, (response) ->
			self.lHide()

	collectData: ($container, changesOnly) ->
		data = []

		isChanged = ($el) ->
			changed = false
			$el.find('[data-val]').each (index, element) ->
				$element = $ element
				if String($element.val()) != String($element.data('val'))
					changed = true
			changed

		$container.find('tbody tr').each (index, element) ->
			$el = $ element
			row =
				id: $el.data 'id'
				width: $el.find('.width').val()
				height: $el.find('.height').val()
				html: $el.find('.html').val()
			if changesOnly
				if isChanged $el
					data.push row
			else
				data.push row
		data

	highlight: (id) ->
		@sendCS 'highlight', id, ->
	
	loadPreset: (preset) ->
		positions = @_config.getPreset preset
		@renderPositions positions if positions?

	savePreset: (preset) ->
		if preset != ''
			@_config.addPreset preset, @collectData @$positions
			@updatePresets()

	updatePresets: ->
		presets = @_config.getPresets()
		template = $('#t_options').text();
		content = Mustache.render template, presets: presets
		$('#presets').html content

	lShow: ->
		@$throbber.show()

	lHide: ->
		@$throbber.fadeOut()


Adr.Popup.init()

$ ->
	$positions = $ '#positions'
	$presets = $ '#presets'
	$settings = $ '#settings'
	$throbber = $ '#throbber'

	Adr.Popup.installInTab $positions, $throbber, () ->

		$('#update').bind 'click', (event) ->
			event.preventDefault()
			Adr.Popup.update()

		$positions.on 'click', 'input.reset', () ->
			$row = $(this).parent().parent()

			$width = $row.find '.width'
			$width.val $width.data 'val'

			$height = $row.find '.height'
			$height.val $height.data 'val'

			$html = $row.find '.html'
			$html.val $html.data 'val'

		$positions.on 'click', 'input.image', () ->
			$row = $(this).parent().parent()
			$row.find('.html').html('[image]')

		$(document).on
			mouseenter: ->
				$row = $(this).parent()
				id = $row.data 'id'
				Adr.Popup.highlight id
		, '#positions td.title'

		$('#load_preset').bind 'click', (event) ->
			event.preventDefault()
			preset = $presets.val()
			Adr.Popup.loadPreset(preset) if preset != ''
		
		$('#save_preset').bind 'click', (event) ->
			event.preventDefault()
			preset = window.prompt("Please enter name for the preset","")
			Adr.Popup.savePreset(preset) if preset != ''

		$('#config').bind 'click', (event) ->
			event.preventDefault()
			$positions.toggle()
			$settings.toggle()

		$('#export').bind 'click', (event) ->
			event.preventDefault()
			Adr.Popup.lShow()
			$('#data').val Adr.Config.jExport()
			Adr.Popup.lHide()

		$('#import').bind 'click', (event) ->
			event.preventDefault()
			Adr.Popup.lShow()
			Adr.Config.jImport $('#data').val()
			Adr.Popup.updatePresets()
			Adr.Popup.lHide()

		$('#clear').bind 'click', (event) ->
			event.preventDefault()
			Adr.Popup.lShow()
			Adr.Config.reset()
			Adr.Popup.updatePresets()
			Adr.Popup.lHide()
