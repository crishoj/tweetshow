window.Sweetshow =

  init: ->
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

  registerHashtagLinkifier: ->
    $.extend $.fn.linkify.plugins, 
      twitterHashtag: 
        re: new RegExp('(^|[^0-9A-Z&\\/]+)(#|＃)([0-9A-Z_]*[A-Z_]+[a-z0-9_ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþ\\303\\277]*)', 'ig')
        tmpl: (match, pre, hash, tag) ->
          pre+'<a href="http://twitter.com/search?q=%23'+tag+'" title="#'+tag+'">'+hash+tag+'</a>'

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
    @foundLink = false
    $("#tweet .text").linkify(use: [], handleLinks: (links) => @handleLinks(links))
    $.log("Found link? #{@foundLink}")
    if @foundLink and $('#tweet').hasClass('big')
      $('#tweet').detach()
        .removeClass('big').appendTo('#contentarea')
    else if not @foundLink and not $('#tweet').hasClass('big')
      $('#tweet').detach()
        .addClass('big').appendTo('#tweetcontainer')
    $("#tweet .text").linkify(use: 'twitterHashtag', handleLinks: @handleHashtags)
    $("abbr.timeago").timeago()
    @twitter('.tweet').hovercards()
    if idx < @statuses.length()
      @enableButton $('.buttonprevious'), => @changeStatus(@curIdx+1)
    else
      @disableButton $('.buttonprevious')
    if idx > 1
      @enableButton $('.buttonnext'), => @changeStatus(@curIdx-1)
    else
      @disableButton $('.buttonnext')

  disableButton: (elem) ->
    if elem.hasClass('enabled')
      elem.attr("disabled", true).removeClass('enabled').addClass('disabled').unbind()

  enableButton: (elem, callback) ->
    if elem.hasClass('disabled')
      elem.removeAttr("disabled").removeClass('disabled').addClass('enabled').bind('click', callback)

  changeStatus: (idx) ->
    $('#preview').remove()
    $.log "changeStatus(#{idx}) out of #{@statuses.length()}"
    @showStatus(idx)

  handleHashtags: (links) -> 
    links
      .addClass('hashtag')
      .attr('target', '_blank')

  handleLinks: (links) -> 
    $.log("handleLinks() with #{links.length} links")
    @foundLink = true
    links.addClass('url').attr('target', '_blank')
    $('#contentarea')
      .height($(window).height() - 220)
      .html(ich.previewTpl(links[0]))

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
