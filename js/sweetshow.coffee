window.Sweetshow =

  show: (user) ->
    @user = user;
    $('#container').html ich.sweetTpl(user)
    user.lists().each (list) ->
      $('#lists').append ich.listTpl(list)
    @showTimeline user.homeTimeline()

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
    twttr.anywhere (T) ->
      T.linkifyUsers()
      T.hovercards()
    $("abbr.timeago").timeago()
    $("#tweet .text").linkify(handleLinks: @handleLinks)
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
  twttr.anywhere (T) -> 
    $.log 'anywhere loaded'
    $("#loading").hide()
    if T.isConnected()
      $.log 'connected'
      Sweetshow.show(T.currentUser)
    else
      $.log 'not connected'
      $('#connect').show()
      T("#connectButton").connectButton
        size: "xlarge"
        authComplete: -> Sweetshow.show(T.currentUser)

