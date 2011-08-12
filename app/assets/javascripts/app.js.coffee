window.tsw = {}

window.tsw.App =
  fetchInterval: 30000
  preloadDelay: 4000

  init: ->
    @registerHashtagLinkifier()
    twttr.anywhere (T) =>
      $('#connect .loading').remove()
      @twitter = T
      if T.isConnected()
        @show()
      else
        $('#connect').show()
        T("#connectButton").connectButton
          size: "xlarge"
          authComplete: => 
            @trackEvent('auth', 'connect')
            @show()

  show: ->
    @user = @twitter.currentUser
    $('#container').html ich.mainTpl(@user)
    @showTimeline(new tsw.HomeTimeline(@user))
    $('#home').click => @showTimeline(new tsw.HomeTimeline(@user))
    $('#signout').click => @signout()
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
    @user.lists (lists) =>
      @lists = lists
      @lists.each (list) ->
        $('#lists').append("<li><a listid=\"#{list.idStr}\">#{list.name}</a></li>")
      $('#lists a').bind 'click', (event) => @handleListChange(event)

  showTimeline: (timeline) ->
    @timeline = timeline
    timeline.show()

  scheduleFetching: ->
    window.setTimeout (=> @timeline.fetchNew(); @scheduleFetching()), @fetchInterval

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
    @debug("List id: #{listId}")
    @lists.each (l) =>
      if l.idStr == listId
        @showTimeline(new tsw.List(l))

  handleReceived: ->
    @timeline.showStatus 0 unless @timeline.curIdx?
    @updateButtons()

  updateButtons: ->
    @toggleButton @timeline.hasPrevious(), $('.buttonprevious'), => @previous()
    @toggleButton @timeline.hasNext(), $('.buttonnext'), => @next()
    @toggleButton (@timeline.newCount > 0), $('.buttonnew'), => @showNew()
    $(".buttonnew .count").text @timeline.newCount

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

  showStatus: (@status) ->
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
    @updateButtons()

  preload: ->
    keep = []
    preloading = false
    for idx in [@timeline.curIdx...@timeline.curIdx+3]
      break if keep.length >= 3
      candidate = @timeline.statuses[idx]
      continue unless candidate?
      continue if not candidate.link?
      keep.push candidate.id()
      continue if candidate.previewLoaded()
      unless preloading
        @debug("Preloading #{candidate}...")
        preloading = true
        $('#contentarea').append candidate.renderPreview()
    @debug "Statuses to keep: #{keep.join ', '}"
    for status in @timeline.statuses
      if status.previewLoaded()
        status.unloadPreview() unless status.id() in keep

  next: ->
    if @timeline.hasNext()
      @changeStatus(@timeline.curIdx-1)
      @trackEvent('status', 'next')

  previous: ->
    if @timeline.hasPrevious()
      @changeStatus(@timeline.curIdx+1)
      @trackEvent('status', 'previous')

  open: ->
    if @status.link?
      @ignoreUnload()
      window.location = @status.link.href
      @trackEvent('status', 'open')

  showNew: ->
    if @timeline.newCount > 0
      @changeStatus 0
      @timeline.newCount = 0
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
    @timeline.showStatus(idx)
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

$(document).ready -> tsw.App.init()
