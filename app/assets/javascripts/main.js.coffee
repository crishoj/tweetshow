window.Tweetshow =

  init: ->
    @fetchCount = 20
    @registerHashtagLinkifier()
    @fetchInterval = 30000
    @preloadDelay = 4000
    @newCount = 0
    @statuses = []
    twttr.anywhere (T) => 
      $('#connect .loading').remove()
      @twitter = T
      if T.isConnected()
        @begin()
      else
        $('#connect').show()
        T("#connectButton").connectButton
          size: "xlarge"
          authComplete: => 
            @trackEvent('auth', 'connect')
            @begin()

  begin: ->
    @user = @twitter.currentUser
    $('#container').html ich.mainTpl(@user)
    $('#signout').click => @signout()
    @showTimeline @user.homeTimeline
    for key in ['return', 'o']
      $(document).bind 'keyup', key, => 
        @trackEvent('ui', 'key', key)
        @open() 
    for key in ['right', 'j', 'space']
      $(document).bind 'keyup', key, => 
        @trackEvent('ui', 'key', key)
        @previous() 
    for key in ['left', 'k', 'backspace']
      $(document).bind 'keyup', key, => 
        @trackEvent('ui', 'key', key)
        @next() 
    $(window).resize => @resize()
    @catchUnload()
    @scheduleFetching()
    $('#tweet')
      .live('mouseenter', -> $('#tweet .actions').stop(true, true).fadeIn(200))
      .live('mouseleave', -> $('#tweet .actions').stop(true, true).fadeOut(200))

  scheduleFetching: ->
    window.setTimeout (=> @fetchNew()), @fetchInterval

  registerHashtagLinkifier: ->
    charCodes = [
      192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212,
      213, 214, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234,
      235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 248, 249, 250, 251, 252, 253, 254, 277, 303,
    ]
    chars = (String.fromCharCode(code) for code in charCodes).join('')
    hashChars = ['#', String.fromCharCode(65283)].join('|')
    $.extend $.fn.linkify.plugins, 
      twitterHashtag: 
        re: new RegExp("(^|[^0-9a-z&\\/]+)(#{hashChars})([0-9a-z_]*[a-z_]+[a-z0-9_#{chars}]*)", 'ig')
        tmpl: (match, pre, hash, tag) -> pre + """
          <a href="http://twitter.com/search?q=%23#{tag}" title="\##{tag}">#{hash+tag}</a>
        """

  handleListChange: (event) ->
    listId = $(event.target).attr('listid') 
    if listId == 'home'
      @showTimeline @user.homeTimeline
      $('#currentList').text('home')
    else
      list = @lists[listId]
      @showTimeline list.statuses
      $('#currentList').text(list.name)

  showTimeline: (callback) ->
    @timelineCallback = callback
    @timelineCallback(count: @fetchCount).first @fetchCount, (statuses) => 
      @receive statuses.array
      @showStatus 0

  showStatus: (idx) -> 
    @curIdx = idx
    @status = @statuses[@curIdx]            
    if @status.link?
      # Display tweet in footer, preview of last link as content      
      $('#footerarea').html @status.render()
      if @status.previewLoaded()         
        @debug('Found preload')
        @status.previewElem().addClass('current')
        @preload() 
      else
        @debug('No preload found')
        $('#contentarea').append @status.renderPreview().addClass('current')        
        window.setTimeout (=> @preload()), @preloadDelay
    else 
      # Display tweet as content
      $('#contentarea').prepend @status.render().addClass('big')
      $('#tweet').css('margin-top', -$('#tweet').height()/2)
      @preload()
    $('#contentarea').height($(window).height()-220)
    @twitter('.tweet').hovercards()
    if @status.favorited
      $('#tweet').addClass('favorited')
      $('#tweet .actions a.favorite b').text('Unfavorite')
    $('#tweet .actions a.favorite').click => @toggleFavorite()
    if @status.retweeted
      $('#tweet').addClass 'retweeted' 
    else
      $('#tweet .actions a.retweet').click => @retweet()
    @toggleButton @hasPrevious(), $('.buttonprevious'), => @previous()
    @toggleButton @hasNext(), $('.buttonnext'), => @next()
    @fetch() unless @hasPrevious(5)    

  preload: ->
    @debug "Commencing preload"
    keep = []
    preloading = false
    for idx in [@curIdx-1...@curIdx+10]
      break if keep.length >= 3
      candidate = @statuses[idx]
      continue unless candidate?
      continue if not candidate.link?
      keep.push candidate.id()
      continue if candidate.previewLoaded()
      unless preloading 
        @debug("Preloading #{candidate}...")
        preloading = true
        $('#contentarea').append candidate.renderPreview()
    @debug "Statuses to keep: #{keep.join ', '}"
    for status in @statuses
      if status.previewLoaded() 
        status.unloadPreview() unless status.id() in keep

  fetchNew: ->
    @trackEvent('api', 'fetchNew')
    @timelineCallback
      count: @fetchCount
      since_id: @statuses[0].id()
    .first @fetchCount, (statuses) => 
      newStatuses = (s for s in statuses.array when s.id != @statuses[0].id())
      @debug("#{statuses.array.length} received statuses filtered to #{newStatuses.length} new")
      if newStatuses.length > 0
        @receiveNew newStatuses
        @trackEvent('api', 'newFetched')
      @scheduleFetching()

  fetch: ->
    return if @fetching
    @fetching = true
    last = @statuses[@statuses.length-1]
    @debug("fetching old before #{last}")
    @timelineCallback
      count: @fetchCount
      max_id: last.id()
    .first @fetchCount, (statuses) => 
      @receive statuses.array
      @fetching = false
    @trackEvent('api', 'fetch')

  receiveNew: (statuses) ->
    @receive statuses, true

  receive: (statuses, newer = false) ->
    @debug("got #{statuses.length} statuses")
    statuses = (new Status(s) for s in statuses)
    return if statuses.count == 0
    if @statuses.count == 0
      @statuses = statuses
    else if newer
      @statuses = statuses.concat(@statuses)
      @curIdx   += statuses.length
      @newCount += statuses.length
      $(".buttonnew .count").text(@newCount)
      @enableButton $('.buttonnew'), => @showNew()
    else
      @statuses = @statuses.concat(statuses)

  retweet: ->
    @status.retweet()
    $('#tweet').addClass('retweeted')
    $('#tweet .actions a.retweet').unbind()
    @trackEvent('status', 'retweet')

  toggleFavorite: ->
    if @status.toggleFavorite()
      @trackEvent('status', 'favourite')
      $('#tweet').addClass('favorited')
      $('#tweet .actions a.favorite b').text('Unfavorite')
    else
      @trackEvent('status', 'unfavourite')
      $('#tweet').removeClass('favorited')
      $('#tweet .actions a.favorite b').text('Favorite')

  hasNext: (count = 1) -> 
    @curIdx - count >= 0

  hasPrevious: (count = 1) ->
    @curIdx + count < @statuses.length

  next: ->
    if @hasNext()
      @changeStatus(@curIdx-1)
      @trackEvent('status', 'next')

  previous: ->
    if @hasPrevious()
      @changeStatus(@curIdx+1)
      @trackEvent('status', 'previous')

  open: ->
    if @status.link?
      @ignoreUnload()
      window.location = @status.link.href 
      @trackEvent('status', 'open')

  showNew: ->
    if @newCount > 0
      @changeStatus 0
      @newCount = 0
      @trackEvent('status', 'new')

  clearNew: ->
    $('.buttonnew .count').text(0)
    @disableButton $('.buttonnew')

  toggleButton: (enabled, elem, callback) ->
    if enabled
      @enableButton(elem, callback)
    else
      @disableButton(elem)

  disableButton: (elem) ->
    if elem.hasClass('enabled')
      elem.attr("disabled", true).removeClass('enabled').addClass('disabled').unbind()

  enableButton: (elem, callback) ->
    if elem.hasClass('disabled')
      elem.removeAttr("disabled").removeClass('disabled').addClass('enabled').bind('click', callback)

  changeStatus: (idx) ->
    $('#contentarea .current').removeClass('current')
    $('#tweet').remove()
    @showStatus(idx)
    @clearNew() if idx == 0

  catchUnload: ->
    $(window).bind 'beforeunload', -> 'You (or the previewed tweet URL) is trying to leave tweetshow. Do you wish to leave?'

  ignoreUnload: ->
    $(window).unbind 'beforeunload'

  signout: ->
    @ignoreUnload()
    @trackEvent('auth', 'signout')
    twttr.anywhere.signOut()
    window.location.reload()

  resize: ->
    $("#contentarea").height($(window).height()-220)

  trackEvent: (category, action) ->
    _gaq.push('_trackEvent', category, action)

  debug: (messages...) ->
    return unless window.location.href.match '\.dev/'
    return unless console?
    console.log messages.join(' ')



class Status

  constructor: (@status) ->
    # @Anywhere doesn't seem to maintain state, so we keep track in the wrapper
    @favorited = @status.favorited
    @retweeted = @status.retweeted
    # Monkey patch
    @status.id = @status.idStr
    @status.attributes.id = @status.attributes.id_str
    @status.createdAtISO = new Date(status.createdAt).toISOString()
    @render()

  id: ->
    @status.id

  render: ->
    unless @renderedStatus?
      @renderedStatus = ich.tweetTpl(@status)
      @renderedStatus.find('.text')
        .linkify
          use: []
          handleLinks: (links) =>
            @links = links.addClass('url').attr('target', '_blank')
            @link = @links[@links.length - 1] if @links.length > 0
        .linkify
          use: 'twitterHashtag'
          handleLinks: (tags) -> tags.addClass('hashtag').attr('target', '_blank')
      @renderedStatus.find("abbr.timeago").timeago()
    @renderedStatus

  renderPreview: ->
    @renderedPreview ?= $(ich.previewTpl(@link)).addClass("s#{@id()}")

  retweet: ->
    @status.retweet()
    @retweeted = true

  toggleFavorite: ->
    if @favorited
      @status.unfavorite()
      @favorited = false
    else
      @status.favorite()
      @favorited = true
    @favorited

  previewLoaded: ->
    @previewElem().length > 0 # check existence

  previewElem: ->
    $(".preview.s#{@id()}").first()

  unloadPreview: ->
    Tweetshow.debug "Unloading #{@}"
    @previewElem().remove()

  toString: ->
    "#{@status.id}/#{@status.text[0..10]} (#{@status.createdAt})"



$(document).ready -> Tweetshow.init()

