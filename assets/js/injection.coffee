window.Adr = window.Adr || {}

window.Adr =

	selector: '.wikia-ad'

	init: ->
		self = @
		chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
			console.log request
			sendResponse self[request.exec] request.args... if self[request.exec]

	getPositions: (callback) ->
		result = []
		$(@selector).each (index, ad) ->
			$ad = $(ad)
			result.push
				id: $ad.attr 'id'
				height: $ad.height()
				width: $ad.width()
				html: $ad.html()
			true
		result

	updatePositions: (data, callback) ->
		self = @
		$.each data, (index, ad) ->
			self.updateAd $('#'+ad.id), ad
		'done'

	generateColor: (r, g, b) ->
		return '#' +
		(r || 0 % 255).toString(16) +
		(g || 0 % 255).toString(16) +
		(b || 0 % 255).toString(16)

generateImage: (id, width, height, color) ->
		canvas = document.createElement 'canvas'
		$(canvas).attr 'width', width
		$(canvas).attr 'height', height
		canvas.widht = width
		canvas.height = height
		ctx = canvas.getContext '2d'
		ctx.fillStyle = color || @generateColor(width, height, 0)
		ctx.fillRect 0, 0, width, height
		ctx.fillStyle = '#000'
		ctx.fillText id, 2, 10
		$('<img>')
			.attr('src', canvas.toDataURL('image/png'))
			.css
				width: width + 'px'
				height: height + 'px'

	replaceHTML: ($el, ad) ->
		if ad.html == '[image]'
			$el.html @generateImage ad.id, parseInt(ad.width, 10), parseInt(ad.height, 10)
		else
			$el.html ad.html
		true

	updateAd: ($ad, ad) ->
		changed = false
		if $ad.width() != ad.with
			$ad.width(ad.width)
			changed = true
		if $ad.height() != ad.height
			$ad.height(ad.height)
			changed = true
		if $ad.html() != ad.html
			@replaceHTML $ad, ad
			changed = true;
		$ad.css 'overflow', 'hidden' if changed
		true

	highlight: (id) ->
		$el = $('#'+id)
		$el.css 'border', '3px solid #f00'
		setTimeout () ->
			$el.css 'border', 'none'
		, 500
		true

$ ->
	Adr.init()
