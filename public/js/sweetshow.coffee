window.Sweetshow =

  init: (twitter) ->
    @twitter = twitter
    @user = @twitter.currentUser
    $('#container').html ich.sweetTpl(@user)
    @user.lists().each (list) ->
      $('#lists').append ich.listTpl(list)
    @showTimeline @user.homeTimeline()

  showTimeline: (timeline) ->
    $.log 'showTimeline'
    @timeline = timeline
    @timeline.first(40, (statuses) => @handleStatuses(statuses))

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
    $("#tweet .text").linkify(handleLinks: @handleLinks)
    $("abbr.timeago").timeago()
    @twitter.linkifyUsers()
    @twitter.hovercards()
    if idx < @statuses.length()
      $('.buttonprevious').bind('click', => @changeStatus(idx+1))
    else
      $('.buttonprevious').unbind()
    if idx > 1
      $('.buttonnext').bind('click', => @changeStatus(idx-1))
    else
      $('.buttonnext').unbind()

  changeStatus: (idx) ->
    $('#contentarea').html('')
    @showStatus(idx)

  handleLinks: (links) -> 
    links.addClass 'url'
    $('#contentarea')
      #.css("overflow","auto")
      .height($(window).height() - 220)
      .html(ich.previewTpl(links[0]))

$(document).ready -> 
  $.log 'ready'
  $(window).bind 'beforeunload', -> 'You (or the previewed tweet URL) is trying to leave Sweetshow. Do you wish to leave?'
  twttr.anywhere (T) -> 
    $.log 'anywhere loaded'
    $("#loading").hide()
    if T.isConnected()
      $.log 'connected'
      Sweetshow.init(T)
    else
      $.log 'not connected'
      $('#connect').show()
      T("#connectButton").connectButton
        size: "xlarge"
        authComplete: -> Sweetshow.init(T)
