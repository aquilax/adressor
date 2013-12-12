window.Adr = window.Adr || {}

window.Adr =

	selector: '.wikia-ad'

	init: ->
		self = @
		chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
			sendResponse self[request.exec] request.args... if self[request.exec]

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

	updatePositions: (data, callback) ->
		self = @
		$.each data, (index, ad) ->
			self.updateAd $('#'+ad.id), ad
		'done'

	updateAd: ($ad, ad) ->
		console.log $ad, ad
		changed = false
		if $ad.width() != ad.with
			$ad.width(ad.width)
			changed = true
		if $ad.height() != ad.height
			$ad.height(ad.height)
			changed = true
		$ad.css 'overflow', 'hidden' if changed

$ ->
	Adr.init()
	console.log 'installed'
