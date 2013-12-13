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
		data = {}
		data[@key] = @_data
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
	
	removePreset: (name) ->
		delete @_data[@_presetKey][name]

	jExport: ->
		JSON.stringify @_data
	
	jImport: (json) ->
		@_data = JSON.parse json
		@_data = @_default if !@_data?

window.Adr.Popup =

	_config: Adr.Config
	$positions: null

	init: ->
		self = @
		chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
			self[request.exec] request.args..., sendResponse if self[request.exec]?
		# TODO: Load is async
		@_config.load()
	
	installInTab: ($positions, callback) ->
		self = @
		@$positions = $positions
		@getCurrentTab (tab) ->
			self.install tab, ->
				self.getPositions (callback)
					

	install: (tab, callback) ->
		chrome.tabs.executeScript tab.id,
			file: "assets/js/external/jquery-2.0.3.min.js"
			allFrames: false
		, () ->
			chrome.tabs.executeScript tab.id,
				file: "assets/js/injection.js"
				allFrames: false
			, () ->
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
			template = $('#t_positions').text();
			content = Mustache.render template, ads: positions
		else
			template = $('#t_wrong_tab').text();
			content = Mustache.render template, {}

		@$positions.append(content)


	update: () ->
		data = @collectData @$positions
		@sendCS 'updatePositions', data, (response) ->
			log response

	collectData: ($container) ->
		data = []
		$container.find('tr').each (index, element) ->
			$el = $ element
			data.push
				id: $el.data 'id'
				width: $el.find('.width').val()
				height: $el.find('.height').val()
				html: $el.find('.html').val()
		data

	highlight: (id) ->
		@sendCS 'highlight', id, ->

Adr.Popup.init()

$ ->
	$positions = $ '#positions'

	Adr.Popup.installInTab $positions, () ->

		$('#update').bind 'click', (event) ->
			event.preventDefault()
			Adr.Popup.update()

		$positions.on 'click', 'button.reset', () ->
			$row = $(this).parent().parent()

			$width = $row.find '.width'
			$width.val $width.data 'val'

			$height = $row.find '.height'
			$height.val $height.data 'val'

			$html = $row.find '.html'
			$html.val $html.data 'val'

		$positions.on 'click', 'button.image', () ->
			$row = $(this).parent().parent()
			$row.find('.html').html('[image]')

		$(document).on
			mouseenter: ->
				$row = $(this).parent()
				id = $row.data 'id'
				Adr.Popup.highlight id
		, '#positions td.title'
