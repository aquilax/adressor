// Generated by CoffeeScript 1.6.1
(function() {

  window.Adr = window.Adr || {};

  window.Adr = {
    selector: '.wikia-ad',
    init: function() {
      var self;
      self = this;
      return chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
        console.log(self, request);
        return sendResponse(self[request.exec].apply(self, request.args));
      });
    },
    getPositions: function(callback) {
      var result;
      result = [];
      $(this.selector).each(function(index, ad) {
        var $ad;
        $ad = $(ad);
        return result.push({
          id: $ad.attr('id'),
          height: $ad.height(),
          width: $ad.width()
        });
      });
      console.log(result);
      return result;
    }
  };

  $(function() {
    Adr.init();
    return console.log('installed');
  });

}).call(this);
