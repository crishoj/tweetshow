(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.Sweetshow = {
    init: function() {
      this.catchUnload();
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
            authComplete: __bind(function() {
              return this.begin();
            }, this)
          });
        }
      }, this));
    },
    begin: function() {
      this.user = this.twitter.currentUser;
      $('#container').html(ich.sweetTpl(this.user));
      $('#signout').click(__bind(function() {
        return this.signout();
      }, this));
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
            return pre + ("<a href=\"http://twitter.com/search?q=%23" + tag + "\" title=\"\#" + tag + "\">" + (hash + tag) + "</a>");
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
      $.log("showStatus(" + idx + ") out of " + (this.statuses.length()));
      this.curIdx = idx;
      this.status = this.statuses.get(idx);
      this.status.createdAtISO = new Date(this.status.createdAt).toISOString();
      $('#tweet').html(ich.tweetTpl(this.status));
      this.foundLink = false;
      $("#tweet .text").linkify({
        use: [],
        handleLinks: __bind(function(links) {
          return this.handleLinks(links);
        }, this)
      });
      $.log("Found link? " + this.foundLink);
      if (this.foundLink && $('#tweet').hasClass('big')) {
        $('#tweet').detach().removeClass('big').appendTo('#contentarea');
      } else if (!this.foundLink && !$('#tweet').hasClass('big')) {
        $('#tweet').detach().addClass('big').appendTo('#tweetcontainer');
      }
      $("#tweet .text").linkify({
        use: 'twitterHashtag',
        handleLinks: this.handleHashtags
      });
      $("abbr.timeago").timeago();
      this.twitter('.tweet').hovercards();
      if (idx < this.statuses.length()) {
        this.enableButton($('.buttonprevious'), __bind(function() {
          return this.changeStatus(this.curIdx + 1);
        }, this));
      } else {
        this.disableButton($('.buttonprevious'));
      }
      if (idx > 1) {
        return this.enableButton($('.buttonnext'), __bind(function() {
          return this.changeStatus(this.curIdx - 1);
        }, this));
      } else {
        return this.disableButton($('.buttonnext'));
      }
    },
    disableButton: function(elem) {
      if (elem.hasClass('enabled')) {
        return elem.attr("disabled", true).removeClass('enabled').addClass('disabled').unbind();
      }
    },
    enableButton: function(elem, callback) {
      if (elem.hasClass('disabled')) {
        return elem.removeAttr("disabled").removeClass('disabled').addClass('enabled').bind('click', callback);
      }
    },
    changeStatus: function(idx) {
      $.log("changeStatus(" + idx + ") out of " + (this.statuses.length()));
      $('.preview').animate({
        leftMargin: '+9999px',
        complete: function() {
          return this.remove();
        }
      });
      return this.showStatus(idx);
    },
    handleHashtags: function(links) {
      return links.addClass('hashtag').attr('target', '_blank');
    },
    handleLinks: function(links) {
      $.log("handleLinks() with " + links.length + " links");
      this.foundLink = true;
      links.addClass('url').attr('target', '_blank');
      return $('#contentarea').height($(window).height() - 220).html(ich.previewTpl(links[0]));
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
    },
    signout: function() {
      $.log('signout');
      this.ignoreUnload();
      twttr.anywhere.signOut();
      return window.location.reload();
    }
  };
  $(document).ready(function() {
    return Sweetshow.init();
  });
}).call(this);
