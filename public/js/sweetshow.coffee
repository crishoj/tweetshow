window.Sweetshow =

  init: ->
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
          authComplete: -> @begin()

  begin: ->
    @user = @twitter.currentUser
    $('#container').html ich.sweetTpl(@user)
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
    @curIdx = idx
    @status = @statuses.get(idx)
    @status.createdAtISO = new Date(@status.createdAt).toISOString()
    $.log "showStatus(#{@curIdx}) out of #{@statuses.length()}"
    $('#tweet').html ich.tweetTpl(@status)
    $("#tweet .text").linkify(use: [], handleLinks: @handleLinks)
    $("#tweet .text").linkify(use: 'twitterHashtag', handleLinks: @handleHashtags)
    $("abbr.timeago").timeago()
    @twitter('.tweet').hovercards()
    if idx < @statuses.length()
      $('.buttonprevious').bind('click', => @changeStatus(idx+1))
    else
      $('.buttonprevious').unbind()
    if idx > 1
      $('.buttonnext').bind('click', => @changeStatus(idx-1))
    else
      $('.buttonnext').unbind()

  changeStatus: (idx) ->
    $('#preview').remove()
    @showStatus(idx)

  handleHashtags: (links) -> 
    links
      .addClass('hashtag')
      .attr('target', '_blank')

  handleLinks: (links) -> 
    links
      .addClass('url')
      .attr('target', '_blank')
    Sweetshow.catchUnload()
    $('#contentarea')
      .height($(window).height() - 220)
      .html(ich.previewTpl(links[0]))
    $('iframe.preview').one('load', -> @ignoreUnload)

  catchUnload: ->
    $.log 'catching unload'
    $(window).bind 'beforeunload', -> 'You (or the previewed tweet URL) is trying to leave Sweetshow. Do you wish to leave?'

  ignoreUnload: ->
    $.log 'ignoring unload'
    $(window).unbind 'beforeunload'


$(document).ready -> Sweetshow.init()
