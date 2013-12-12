window.log = (args...) ->
	$('#debug').val args.join(";")

window.Adr = window.Adr || {}

window.Adr.Popup =

	data: [],

	init: ->
		self = @
		@$positions = $ '#positions'
		chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->	
			self[request.exec] request.args..., sendResponse if self[request.exec]?

	send: (cmd, args..., callback) ->
		chrome.runtime.sendMessage
			exec:	cmd
			args:	args
		, callback || () ->

	sendCS: (exec, args..., callback) ->
		chrome.tabs.query
			active: true,
			currentWindow: true
		, (tabs) ->
			chrome.tabs.sendMessage tabs[0].id,
				exec: exec,
				args: args
			, callback || ()->

	install: ->
		chrome.tabs.executeScript null, {file: "assets/js/external/jquery-2.0.3.min.js"}
		chrome.tabs.executeScript null, {file: "assets/js/injection.js"}
		log 'installed'

	getPositions: ->
		self = @
		@sendCS 'getPositions', (response) ->
			self.renderPositions response

	renderPositions: (positions)->
		@$positions.empty()
		template = $('#t_positions').text();
		items = Mustache.render template,
			ads: positions
		@$positions.append(items)

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
		data



$ ->
	Adr.Popup.init();

	$('#start').bind 'click', (event) ->
		event.preventDefault()
		Adr.Popup.install()

	$('#get_ads').bind 'click', (event) ->
		event.preventDefault()
		Adr.Popup.getPositions()

	$('#update').bind 'click', (event) ->
		event.preventDefault()
		Adr.Popup.update()
	
	#Adr.Popup.getPositions()
