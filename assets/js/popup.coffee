window.log = (args...) ->
	$('#debug').val args.join(";")

window.Adr = window.Adr || {}

window.Adr.Popup =


	init: ->
		self = @
		@$positions = $ '#positions'
		chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->	
			self[request.exec] request.args..., sendResponse if self[request.exec]?
		@install().done () ->
			self.getPositions()

	getCurrentTabId: ->
		def = new $.Deferred()
		chrome.tabs.query
			active: true,
			currentWindow: true
		, (tabs) ->
			def.resolve tabs[0]

		def
	send: (cmd, args..., callback) ->
		chrome.runtime.sendMessage
			exec:	cmd
			args:	args
		, callback || () ->

	sendCS: (exec, args..., callback) ->
		@getCurrentTabId().done (tab) ->
			chrome.tabs.sendMessage tab.id,
				exec: exec,
				args: args
			, callback || ()->

	install: ->
		def = new $.Deferred()
		chrome.tabs.executeScript null,
			file: "assets/js/external/jquery-2.0.3.min.js"
			allFrames: false
		, () ->
			chrome.tabs.executeScript null,
				file: "assets/js/injection.js"
				allFrames: false
			, () ->
				def.resolve()
		def

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
				html: $el.find('.html').val()
		data

	highlight: (id) ->
		@sendCS 'highlight', id, ->

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

	$('#positions').on 'click', 'button.reset', () ->
		$row = $(this).parent().parent()

		$width = $row.find '.width'
		$width.val $width.data 'val'

		$height = $row.find '.height'
		$height.val $height.data 'val'

		$html = $row.find '.html'
		$html.val $html.data 'val'

	$('#positions').on 'click', 'button.image', () ->
		$row = $(this).parent().parent()
		$row.find('.html').html('[image]')

	$(document).on
		mouseenter: ->
			$row = $(this).parent()
			id = $row.data 'id'
			Adr.Popup.highlight id
	, '#positions td.title'

