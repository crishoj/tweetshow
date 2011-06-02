window.Tweetshow =

  init: ->
    $.log 'init'
    @fetchCount = 20
    @lists = {}
    @registerHashtagLinkifier()
    @fetchInterval = 60000
    @newCount = 0
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
    $('#container').html ich.mainTpl(@user)
    $('#signout').click => @signout()
    @user.lists().each (list) =>
      $('#lists').append ich.listTpl(list)
      @lists[list.id] = list
    $('#lists a').live 'click', (e) => @handleListChange(e)
    @showTimeline @user.homeTimeline
    for key in ['return', 'o']
      $(document).bind 'keyup', key, => @open() 
    for key in ['right', 'j', 'space']
      $(document).bind 'keyup', key, => @previous() 
    for key in ['left', 'k', 'backspace']
      $(document).bind 'keyup', key, => @next() 
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
    $.log("changing to list #{listId}")
    if listId == 'home'
      @showTimeline @user.homeTimeline
      $('#currentList').text('home')
    else
      list = @lists[listId]
      @showTimeline list.statuses
      $('#currentList').text(list.name)

  showTimeline: (callback) ->
    $.log 'showTimeline'
    @timelineCallback = callback
    @timelineCallback(count: @fetchCount).first @fetchCount, (statuses) => 
      @statuses = statuses
      @showStatus 1

  showStatus: (idx) -> 
    $.log "showStatus(#{idx}) out of #{@statuses.length()}: #{@statuses.get(idx).text}"
    @curIdx = idx
    @status = @statuses.get(@curIdx)
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
      # Display tweet in footer, preview as content
      $('#footerarea').html e
      $('#contentarea').html ich.previewTpl(@links[0])
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
    $.log('fetching new')
    @timelineCallback
      count: @fetchCount
      since_id: @statuses.first().id
    .first @fetchCount, (statuses) => 
      $.log("received #{statuses.length()} new statuses")
      if statuses.length() > 0
        @statuses.array = statuses.array.concat(@statuses.array)
        @curId += statuses.length()
        @newCount += statuses.length()
        $(".buttonnew .count").text(@newCount)
        @enableButton $('.buttonnew'), => @showNew()
      @scheduleFetching()

  fetch: ->
    return $.log('already fetching') if @fetching
    @fetching = true
    $.log('fetching')
    @timelineCallback
      count: @fetchCount
      max_id: @statuses.last().id
    .first @fetchCount, (statuses) => 
      $.log("received another #{statuses.length()} statuses")
      @statuses.array = @statuses.array.concat(statuses.array)
      @fetching = false

  retweet: ->
    @status.retweet()
    # @Anywhere doesn't seem to maintain state, so force it
    @status.retweeted = true
    $('#tweet').addClass('retweeted')
    $('#tweet .actions a.retweet').unbind()

  toggleFavorite: ->
    if @status.favorited
      @status.unfavorite()
      # @Anywhere doesn't seem to maintain state, so force it
      @status.favorited = false
      $('#tweet').removeClass('favorited')
      $('#tweet .actions a.favorite b').text('Favorite')
    else
      @status.favorite()
      @status.favorited = true 
      $('#tweet').addClass('favorited')
      $('#tweet .actions a.favorite b').text('Unfavorite')

  hasNext: (count = 1) -> 
    @curIdx - count > 0

  hasPrevious: (count = 1) ->
    @curIdx + count - 1 < @statuses.length()

  next: ->
    if @hasNext()
      @changeStatus(@curIdx-1)

  previous: ->
    if @hasPrevious()
      @changeStatus(@curIdx+1)

  showNew: ->
    if @newCount > 0
      @changeStatus 1
      @newCount = 0

  clearNew: ->
    $('.disablebutton .count').text(0)
    @disableButton $('.buttonnew')

  hasLink: ->
    @links.length > 0

  open: ->
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
    $('#tweet').remove()
    @showStatus(idx)
    @clearNew() if idx == 1

  catchUnload: ->
    $.log 'catching unload'
    $(window).bind 'beforeunload', -> 'You (or the previewed tweet URL) is trying to leave tweetshow. Do you wish to leave?'

  ignoreUnload: ->
    $.log 'ignoring unload'
    $(window).unbind 'beforeunload'

  signout: ->
    $.log 'signout'
    @ignoreUnload()
    twttr.anywhere.signOut()
    window.location.reload()

  resize: ->
    $("#contentarea").height($(window).height()-220)

$(document).ready -> Tweetshow.init()