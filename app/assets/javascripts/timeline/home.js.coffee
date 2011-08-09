window.tsw.HomeTimeline = class extends tsw.Timeline

  constructor: (@user) ->

  show: ->
    super()
    $('#timeline').text('home')

  fetch: (arg) ->
    @user.homeTimeline(arg)

