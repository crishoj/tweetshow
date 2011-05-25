window.Sweetshow =

  init: ->
    $.log 'init'
    @catchUnload()
    @registerHashtagLinkifier()
    twttr.anywhere (T) => 
      @twitter = T
      $.log 'anywhere loaded'
      if T.isConnected()
        $.log 'connected'
        @begin()
      else
        $.log 'not connected'
        $('#connect').show()
        T("#connectButton").connectButton
          size: "xlarge"
          authComplete: => @begin()

  begin: ->
    @user = @twitter.currentUser
    $('#container').html ich.sweetTpl(@user)
    $('#signout').click => @signout()
    @user.lists().each (list) ->
      $('#lists').append ich.listTpl(list)
    @showTimeline @user.homeTimeline()
    for key in ['return', 'o']
      $(document).bind 'keyup', key, => @open() 
    for key in ['right', 'j', 'space']
      $(document).bind 'keyup', key, => @previous() 
    for key in ['left', 'k', 'backspace']
      $(document).bind 'keyup', key, => @next() 

  registerHashtagLinkifier: ->
    $.extend $.fn.linkify.plugins, 
      twitterHashtag: 
        re: new RegExp('(^|[^0-9A-Z&\\/]+)(#|＃)([0-9A-Z_]*[A-Z_]+[a-z0-9_ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþ\\303\\277]*)', 'ig')
        tmpl: (match, pre, hash, tag) -> pre + """
          <a href="http://twitter.com/search?q=%23#{tag}" title="\##{tag}">#{hash+tag}</a>
        """

  showTimeline: (timeline) ->
    $.log 'showTimeline'
    @timeline = timeline
    @timeline.first 100, (statuses) => @handleStatuses(statuses)

  handleStatuses: (statuses) ->
    $.log 'handleStatuses'
    @statuses = statuses
    @showStatus 1

  showStatus: (idx) -> 
    $.log "showStatus(#{idx}) out of #{@statuses.length()}"
    @curIdx = idx
    @status = @statuses.get(idx)
    @status.createdAtISO = new Date(@status.createdAt).toISOString()
    $('#tweet').html ich.tweetTpl(@status)
    $("#tweet .text").linkify(use: [], handleLinks: (links) => @handleLinks(links))
    if @hasLink()
      if $('#tweet').hasClass('big')
        $('#tweet').detach().removeClass('big').appendTo('#contentarea')
    else # no link
      if not $('#tweet').hasClass('big')
        $('#tweet').detach().addClass('big').appendTo('#tweetcontainer')
    $("#tweet .text").linkify(use: 'twitterHashtag', handleLinks: @handleHashtags)
    $("abbr.timeago").timeago()
    @twitter('.tweet').hovercards()
    @toggleButton @hasPrevious(), $('.buttonprevious'), => @previous()
    @toggleButton @hasNext(), $('.buttonnext'), => @next()

  hasNext: -> 
    @curIdx > 1

  hasPrevious: ->
    @curIdx < @statuses.length()

  next: ->
    if @hasNext()
      @changeStatus(@curIdx-1)

  previous: ->
    if @hasPrevious()
      @changeStatus(@curIdx+1)

  hasLink: ->
    @links.length > 0

  open: ->
    $.log('open')
    if @hasLink()
      @ignoreUnload()
      window.location = @links[0].href 

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
    @showStatus(idx)

  handleHashtags: (links) -> 
    links
      .addClass('hashtag')
      .attr('target', '_blank')

  handleLinks: (links) -> 
    @links = links
    $.log("handleLinks() with #{@links.length} links")
    @links.addClass('url').attr('target', '_blank')
    $('#contentarea')
      .height($(window).height() - 220)
      .html(ich.previewTpl(@links[0]))

  catchUnload: ->
    $.log 'catching unload'
    $(window).bind 'beforeunload', -> 'You (or the previewed tweet URL) is trying to leave Sweetshow. Do you wish to leave?'

  ignoreUnload: ->
    $.log 'ignoring unload'
    $(window).unbind 'beforeunload'

  signout: ->
    $.log 'signout'
    @ignoreUnload()
    twttr.anywhere.signOut()
    window.location.reload()

$(document).ready -> Sweetshow.init()
