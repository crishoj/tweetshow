
window.Tweetshow =

  init: ->
    @fetchCount = 20
    @registerHashtagLinkifier()
    @fetchInterval = 30000
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
    $.extend $.fn.linkify.plugins, 
      twitterHashtag: 
        re: new RegExp('(^|[^0-9A-Z&\\/]+)(#|＃)([0-9A-Z_]*[A-Z_]+[a-z0-9_ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþ\\303\\277]*)', 'ig')
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
    @status.createdAtISO = new Date(@status.createdAt).toISOString()
    e = ich.tweetTpl(@status)
    e.find('.text')
      .linkify
        use: []
        handleLinks: (links) => @links = links.addClass('url').attr('target', '_blank')
      .linkify
        use: 'twitterHashtag'
        handleLinks: (tags) -> tags.addClass('hashtag').attr('target', '_blank')
    e.find("abbr.timeago").timeago()
    if @hasLink() 
      # Display tweet in footer, preview of last link as content
      @link = @links[@links.length - 1]
      $('#footerarea').html e
      $('#contentarea').html ich.previewTpl(@link)
    else 
      # Display tweet as content
      $('#contentarea').html e.addClass('big')
      $('#tweet').css('margin-top', -$('#tweet').height()/2)
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

  fetchNew: ->
    @trackEvent('api', 'fetchNew')
    @debug("fetching new since #{@statuses[0].id}/#{@statuses[0].text[0..10]} (#{@statuses[0].createdAt})")
    @timelineCallback
      count: @fetchCount
      since_id: @statuses[0].id
    .first @fetchCount, (statuses) => 
      newStatuses = (status for status in statuses.array when status.id != @statuses[0].id)
      @debug("#{statuses.array.length} received statuses filtered to #{newStatuses.length} new")
      if newStatuses.length > 0
        @receiveNew newStatuses
        @trackEvent('api', 'newFetched')
      @scheduleFetching()

  fetch: ->
    return if @fetching
    @fetching = true
    last = @statuses[@statuses.length-1]
    @debug("fetching old before #{last.id}/#{last.text[0..10]} (#{last.createdAt})")
    @timelineCallback
      count: @fetchCount
      max_id: last.id
    .first @fetchCount, (statuses) => 
      @receive statuses.array
      @fetching = false
    @trackEvent('api', 'fetch')

  receiveNew: (statuses) ->
    @receive statuses, true

  receive: (statuses, newer = false) ->
    @debug("got #{statuses.length} statuses")
    statuses = for status in statuses
      # Monkey patch
      status.id = status.idStr
      status.attributes.id = status.attributes.id_str
      status
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
    # @Anywhere doesn't seem to maintain state, so force it
    @status.retweeted = true
    $('#tweet').addClass('retweeted')
    $('#tweet .actions a.retweet').unbind()
    @trackEvent('status', 'retweet')

  toggleFavorite: ->
    if @status.favorited
      @trackEvent('status', 'unfavourite')
      @status.unfavorite()
      # @Anywhere doesn't seem to maintain state, so force it
      @status.favorited = false
      $('#tweet').removeClass('favorited')
      $('#tweet .actions a.favorite b').text('Favorite')
    else
      @trackEvent('status', 'favourite')
      @status.favorite()
      @status.favorited = true 
      $('#tweet').addClass('favorited')
      $('#tweet .actions a.favorite b').text('Unfavorite')

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

  showNew: ->
    if @newCount > 0
      @changeStatus 0
      @newCount = 0
      @trackEvent('status', 'new')

  clearNew: ->
    $('.buttonnew .count').text(0)
    @disableButton $('.buttonnew')

  hasLink: ->
    @links.length > 0

  open: ->
    if @hasLink()
      @ignoreUnload()
      window.location = @link.href 
      @trackEvent('status', 'open')

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
    $('#preview').remove()
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

$(document).ready -> Tweetshow.init()
