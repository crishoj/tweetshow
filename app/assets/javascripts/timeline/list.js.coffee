window.tsw.List = class extends tsw.Timeline

  constructor: (@list) ->

  show: ->
    super()
    $('#timeline').text(@list.slug)

  fetch: (arg) ->
    @list.statuses(arg)
