window.Adr = window.Adr || {}

window.Adr =

	selector: '.wikia-ad'

	init: ->
		self = @
		chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
			console.log self, request
			sendResponse self[request.exec] request.args...

	getPositions: (callback) ->
		result = []
		$(@selector).each (index, ad) ->
			$ad = $(ad)
			result.push
				id: $ad.attr 'id'
				height: $ad.height()
				width: $ad.width()
		console.log result
		result

$ ->
	Adr.init()
	console.log 'installed'
