(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.Tweetshow = {
    init: function() {
      $.log('init');
      this.fetchCount = 20;
      this.lists = {};
      this.registerHashtagLinkifier();
      this.fetchInterval = 60000;
      this.newCount = 0;
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
      var key, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3;
      this.user = this.twitter.currentUser;
      $('#container').html(ich.mainTpl(this.user));
      $('#signout').click(__bind(function() {
        return this.signout();
      }, this));
      this.user.lists().each(__bind(function(list) {
        $('#lists').append(ich.listTpl(list));
        return this.lists[list.id] = list;
      }, this));
      $('#lists a').live('click', __bind(function(e) {
        return this.handleListChange(e);
      }, this));
      this.showTimeline(this.user.homeTimeline);
      _ref = ['return', 'o'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        $(document).bind('keyup', key, __bind(function() {
          return this.open();
        }, this));
      }
      _ref2 = ['right', 'j', 'space'];
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        key = _ref2[_j];
        $(document).bind('keyup', key, __bind(function() {
          return this.previous();
        }, this));
      }
      _ref3 = ['left', 'k', 'backspace'];
      for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
        key = _ref3[_k];
        $(document).bind('keyup', key, __bind(function() {
          return this.next();
        }, this));
      }
      $(window).resize(__bind(function() {
        return this.resize();
      }, this));
      this.catchUnload();
      this.scheduleFetching();
      return $('#tweet').live('mouseenter', function() {
        return $('#tweet .actions').stop(true, true).fadeIn(200);
      }).live('mouseleave', function() {
        return $('#tweet .actions').stop(true, true).fadeOut(200);
      });
    },
    scheduleFetching: function() {
      return window.setTimeout((__bind(function() {
        return this.fetchNew();
      }, this)), this.fetchInterval);
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
    handleListChange: function(event) {
      var list, listId;
      listId = $(event.target).attr('listid');
      $.log("changing to list " + listId);
      if (listId === 'home') {
        this.showTimeline(this.user.homeTimeline);
        return $('#currentList').text('home');
      } else {
        list = this.lists[listId];
        this.showTimeline(list.statuses);
        return $('#currentList').text(list.name);
      }
    },
    showTimeline: function(callback) {
      $.log('showTimeline');
      this.timelineCallback = callback;
      return this.timelineCallback({
        count: this.fetchCount
      }).first(this.fetchCount, __bind(function(statuses) {
        this.statuses = statuses;
        return this.showStatus(1);
      }, this));
    },
    showStatus: function(idx) {
      var e;
      $.log("showStatus(" + idx + ") out of " + (this.statuses.length()) + ": " + (this.statuses.get(idx).text));
      this.curIdx = idx;
      this.status = this.statuses.get(this.curIdx);
      this.status.createdAtISO = new Date(this.status.createdAt).toISOString();
      e = ich.tweetTpl(this.status);
      e.find('.text').linkify({
        use: [],
        handleLinks: __bind(function(links) {
          return this.links = links.addClass('url').attr('target', '_blank');
        }, this)
      }).linkify({
        use: 'twitterHashtag',
        handleLinks: function(tags) {
          return tags.addClass('hashtag').attr('target', '_blank');
        }
      });
      e.find("abbr.timeago").timeago();
      if (this.hasLink()) {
        $('#footerarea').html(e);
        $('#contentarea').html(ich.previewTpl(this.links[0]));
      } else {
        $('#contentarea').html(e.addClass('big'));
        $('#tweet').css('margin-top', -$('#tweet').height() / 2);
      }
      $('#contentarea').height($(window).height() - 220);
      this.twitter('.tweet').hovercards();
      if (this.status.favorited) {
        $('#tweet').addClass('favorited');
        $('#tweet .actions a.favorite b').text('Unfavorite');
      }
      $('#tweet .actions a.favorite').click(__bind(function() {
        return this.toggleFavorite();
      }, this));
      if (this.status.retweeted) {
        $('#tweet').addClass('retweeted');
      } else {
        $('#tweet .actions a.retweet').click(__bind(function() {
          return this.retweet();
        }, this));
      }
      this.toggleButton(this.hasPrevious(), $('.buttonprevious'), __bind(function() {
        return this.previous();
      }, this));
      this.toggleButton(this.hasNext(), $('.buttonnext'), __bind(function() {
        return this.next();
      }, this));
      if (!this.hasPrevious(5)) {
        return this.fetch();
      }
    },
    fetchNew: function() {
      $.log('fetching new');
      return this.timelineCallback({
        count: this.fetchCount,
        since_id: this.statuses.first().id
      }).first(this.fetchCount, __bind(function(statuses) {
        $.log("received " + (statuses.length()) + " new statuses");
        if (statuses.length() > 0) {
          this.statuses.array = statuses.array.concat(this.statuses.array);
          this.curId += statuses.length();
          this.newCount += statuses.length();
          $(".buttonnew .count").text(this.newCount);
          this.enableButton($('.buttonnew'), __bind(function() {
            return this.showNew();
          }, this));
        }
        return this.scheduleFetching();
      }, this));
    },
    fetch: function() {
      if (this.fetching) {
        return $.log('already fetching');
      }
      this.fetching = true;
      $.log('fetching');
      return this.timelineCallback({
        count: this.fetchCount,
        max_id: this.statuses.last().id
      }).first(this.fetchCount, __bind(function(statuses) {
        $.log("received another " + (statuses.length()) + " statuses");
        this.statuses.array = this.statuses.array.concat(statuses.array);
        return this.fetching = false;
      }, this));
    },
    retweet: function() {
      this.status.retweet();
      this.status.retweeted = true;
      $('#tweet').addClass('retweeted');
      return $('#tweet .actions a.retweet').unbind();
    },
    toggleFavorite: function() {
      if (this.status.favorited) {
        this.status.unfavorite();
        this.status.favorited = false;
        $('#tweet').removeClass('favorited');
        return $('#tweet .actions a.favorite b').text('Favorite');
      } else {
        this.status.favorite();
        this.status.favorited = true;
        $('#tweet').addClass('favorited');
        return $('#tweet .actions a.favorite b').text('Unfavorite');
      }
    },
    hasNext: function(count) {
      if (count == null) {
        count = 1;
      }
      return this.curIdx - count > 0;
    },
    hasPrevious: function(count) {
      if (count == null) {
        count = 1;
      }
      return this.curIdx + count - 1 < this.statuses.length();
    },
    next: function() {
      if (this.hasNext()) {
        return this.changeStatus(this.curIdx - 1);
      }
    },
    previous: function() {
      if (this.hasPrevious()) {
        return this.changeStatus(this.curIdx + 1);
      }
    },
    showNew: function() {
      if (this.newCount > 0) {
        this.changeStatus(1);
        return this.newCount = 0;
      }
    },
    clearNew: function() {
      $('.disablebutton .count').text(0);
      return this.disableButton($('.buttonnew'));
    },
    hasLink: function() {
      return this.links.length > 0;
    },
    open: function() {
      if (this.hasLink()) {
        this.ignoreUnload();
        return window.location = this.links[0].href;
      }
    },
    toggleButton: function(enabled, elem, callback) {
      if (enabled) {
        return this.enableButton(elem, callback);
      } else {
        return this.disableButton(elem);
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
      $('#preview').remove();
      $('#tweet').remove();
      this.showStatus(idx);
      if (idx === 1) {
        return this.clearNew();
      }
    },
    catchUnload: function() {
      $.log('catching unload');
      return $(window).bind('beforeunload', function() {
        return 'You (or the previewed tweet URL) is trying to leave tweetshow. Do you wish to leave?';
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
    },
    resize: function() {
      return $("#contentarea").height($(window).height() - 220);
    }
  };
  $(document).ready(function() {
    return Tweetshow.init();
  });
}).call(this);