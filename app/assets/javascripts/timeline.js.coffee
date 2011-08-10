window.tsw.Timeline = class
  fetchCount: 20
  fetchMargin: 5

  show: ->
    @newCount = 0
    @statuses = []
    $(".preview").remove()
    $('#tweet').remove()
    @fetch(count: @fetchCount).each (status) =>
      @receive(status)

  showStatus: (idx) ->
    @curIdx = idx
    @status = @statuses[@curIdx]
    tsw.App.showStatus(@status)
    @fetchOld() unless @hasPrevious(@fetchMargin)

  fetchNew: ->
    @trackEvent('api', 'fetchNew')
    @fetch(count: @fetchCount, since_id: @statuses[0].id()).each (status) =>
      if status.id != @statuses[0].id()
        @receiveNew status
        @trackEvent('api', 'newFetched')

  fetchOld: ->
    return if @fetching or @curIdx < (@fetchCount-@fetchMargin)
    @fetching = true
    last = @statuses[@statuses.length-1]
    @debug("fetching old before #{last}")
    @fetch(count: @fetchCount, max_id: last.id()).each (status) =>
      @receive status
      @fetching = false
    @trackEvent('api', 'fetch')

  receiveNew: (status) ->
    @receive status, true

  receive: (status, newer = false) ->
    status = new tsw.Status(status)
    if newer
      @statuses.unshift(status)
      @curIdx++
      @newCount++
    else
      @statuses.push(status)
    tsw.App.handleReceived()

  hasNext: (count = 1) ->
    @curIdx - count >= 0

  hasPrevious: (count = 1) ->
    @curIdx + count < @statuses.length

  trackEvent: (category, action) ->
    tsw.App.trackEvent(category, action)

  debug: (messages...) ->
    tsw.App.debug(messages)