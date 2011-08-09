window.tsw.Status = class

  constructor: (@status) ->
    # @Anywhere doesn't seem to maintain state, so we keep track in the wrapper
    @favorited = @status.favorited
    @retweeted = @status.retweeted
    # Monkey patch
    @status.id = @status.idStr
    @status.attributes.id = @status.attributes.id_str
    @status.createdAtISO = new Date(status.createdAt).toISOString()
    @render()

  id: ->
    @status.id

  render: ->
    unless @renderedStatus?
      @renderedStatus = ich.tweetTpl(@status)
      @renderedStatus.find('.text')
        .linkify
          use: []
          handleLinks: (links) =>
            @links = links.addClass('url').attr('target', '_blank')
            @link = @links[@links.length - 1] if @links.length > 0
        .linkify
          use: 'twitterHashtag'
          handleLinks: (tags) -> tags.addClass('hashtag').attr('target', '_blank')
      @renderedStatus.find("abbr.timeago").timeago()
    @renderedStatus

  renderPreview: ->
    @renderedPreview ?= $(ich.previewTpl(@link)).addClass("s#{@id()}")

  retweet: ->
    @status.retweet()
    @retweeted = true

  toggleFavorite: ->
    if @favorited
      @status.unfavorite()
      @favorited = false
    else
      @status.favorite()
      @favorited = true
    @favorited

  previewLoaded: ->
    @previewElem().length > 0 # check existence

  previewElem: ->
    $(".preview.s#{@id()}").first()

  unloadPreview: ->
    tsw.App.debug "Unloading #{@}"
    @previewElem().remove()

  toString: ->
    "#{@status.id}/#{@status.text[0..10]} (#{@status.createdAt})"

