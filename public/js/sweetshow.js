(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.Sweetshow = {
    init: function() {
      this.registerHashtagLinkifier();
      return twttr.anywhere(__bind(function(T) {
        this.twitter = T;
        $.log('anywhere loaded');
        if (T.isConnected()) {
          $.log('connected');
          return this.begin();
        } else {
          $.log('not connected');
          $('#connect').show();
          return T("#connectButton").connectButton({
            size: "xlarge",
            authComplete: function() {
              return this.begin();
            }
          });
        }
      }, this));
    },
    begin: function() {
      this.user = this.twitter.currentUser;
      $('#container').html(ich.sweetTpl(this.user));
      this.user.lists().each(function(list) {
        return $('#lists').append(ich.listTpl(list));
      });
      return this.showTimeline(this.user.homeTimeline());
    },
    registerHashtagLinkifier: function() {
      return $.extend($.fn.linkify.plugins, {
        twitterHashtag: {
          re: new RegExp('(^|[^0-9A-Z&\\/]+)(#|＃)([0-9A-Z_]*[A-Z_]+[a-z0-9_ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþ\\303\\277]*)', 'ig'),
          tmpl: function(match, pre, hash, tag) {
            return pre + '<a href="http://twitter.com/search?q=%23' + tag + '" title="#' + tag + '">' + hash + tag + '</a>';
          }
        }
      });
    },
    showTimeline: function(timeline) {
      $.log('showTimeline');
      this.timeline = timeline;
      return this.timeline.first(100, __bind(function(statuses) {
        return this.handleStatuses(statuses);
      }, this));
    },
    handleStatuses: function(statuses) {
      $.log('handleStatuses');
      this.statuses = statuses;
      return this.showStatus(1);
    },
    showStatus: function(idx) {
      this.curIdx = idx;
      this.status = this.statuses.get(idx);
      this.status.createdAtISO = new Date(this.status.createdAt).toISOString();
      $.log("showStatus(" + this.curIdx + ") out of " + (this.statuses.length()));
      $('#tweet').html(ich.tweetTpl(this.status));
      $("#tweet .text").linkify({
        use: [],
        handleLinks: this.handleLinks
      });
      $("#tweet .text").linkify({
        use: 'twitterHashtag',
        handleLinks: this.handleHashtags
      });
      $("abbr.timeago").timeago();
      this.twitter('.tweet').hovercards();
      if (idx < this.statuses.length()) {
        $('.buttonprevious').bind('click', __bind(function() {
          return this.changeStatus(idx + 1);
        }, this));
      } else {
        $('.buttonprevious').unbind();
      }
      if (idx > 1) {
        return $('.buttonnext').bind('click', __bind(function() {
          return this.changeStatus(idx - 1);
        }, this));
      } else {
        return $('.buttonnext').unbind();
      }
    },
    changeStatus: function(idx) {
      $('#preview').remove();
      return this.showStatus(idx);
    },
    handleHashtags: function(links) {
      return links.addClass('hashtag').attr('target', '_blank');
    },
    handleLinks: function(links) {
      links.addClass('url').attr('target', '_blank');
      Sweetshow.catchUnload();
      $('#contentarea').height($(window).height() - 220).html(ich.previewTpl(links[0]));
      return $('iframe.preview').one('load', function() {
        return this.ignoreUnload;
      });
    },
    catchUnload: function() {
      $.log('catching unload');
      return $(window).bind('beforeunload', function() {
        return 'You (or the previewed tweet URL) is trying to leave Sweetshow. Do you wish to leave?';
      });
    },
    ignoreUnload: function() {
      $.log('ignoring unload');
      return $(window).unbind('beforeunload');
    }
  };
  $(document).ready(function() {
    return Sweetshow.init();
  });
}).call(this);
