(function() {
  var Status;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  }, __slice = Array.prototype.slice;
  window.Tweetshow = {
    init: function() {
      this.fetchCount = 20;
      this.registerHashtagLinkifier();
      this.fetchInterval = 30000;
      this.preloadDelay = 4000;
      this.newCount = 0;
      this.statuses = [];
      return twttr.anywhere(__bind(function(T) {
        $('#connect .loading').remove();
        this.twitter = T;
        if (T.isConnected()) {
          return this.begin();
        } else {
          $('#connect').show();
          return T("#connectButton").connectButton({
            size: "xlarge",
            authComplete: __bind(function() {
              this.trackEvent('auth', 'connect');
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
      this.showTimeline(this.user.homeTimeline);
      _ref = ['return', 'o'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        $(document).bind('keyup', key, __bind(function() {
          this.trackEvent('ui', 'key', key);
          return this.open();
        }, this));
      }
      _ref2 = ['right', 'j', 'space'];
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        key = _ref2[_j];
        $(document).bind('keyup', key, __bind(function() {
          this.trackEvent('ui', 'key', key);
          return this.previous();
        }, this));
      }
      _ref3 = ['left', 'k', 'backspace'];
      for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
        key = _ref3[_k];
        $(document).bind('keyup', key, __bind(function() {
          this.trackEvent('ui', 'key', key);
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
      this.timelineCallback = callback;
      return this.timelineCallback({
        count: this.fetchCount
      }).first(this.fetchCount, __bind(function(statuses) {
        this.receive(statuses.array);
        return this.showStatus(0);
      }, this));
    },
    showStatus: function(idx) {
      this.curIdx = idx;
      this.status = this.statuses[this.curIdx];
      if (this.status.link != null) {
        $('#footerarea').html(this.status.render());
        if (this.status.previewLoaded()) {
          this.debug('Found preload');
          this.status.previewElem().addClass('current');
          this.preload();
        } else {
          this.debug('No preload found');
          $('#contentarea').append(this.status.renderPreview().addClass('current'));
          window.setTimeout((__bind(function() {
            return this.preload();
          }, this)), this.preloadDelay);
        }
      } else {
        $('#contentarea').prepend(this.status.render().addClass('big'));
        $('#tweet').css('margin-top', -$('#tweet').height() / 2);
        this.preload();
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
    preload: function() {
      var candidate, idx, keep, preloading, status, _i, _len, _ref, _ref2, _ref3, _ref4, _results;
      this.debug("Commencing preload");
      keep = [];
      preloading = false;
      for (idx = _ref = this.curIdx - 1, _ref2 = this.curIdx + 10; _ref <= _ref2 ? idx < _ref2 : idx > _ref2; _ref <= _ref2 ? idx++ : idx--) {
        if (keep.length >= 3) {
          break;
        }
        candidate = this.statuses[idx];
        if (candidate == null) {
          continue;
        }
        if (!(candidate.link != null)) {
          continue;
        }
        keep.push(candidate.id());
        if (candidate.previewLoaded()) {
          continue;
        }
        if (!preloading) {
          this.debug("Preloading " + candidate + "...");
          preloading = true;
          $('#contentarea').append(candidate.renderPreview());
        }
      }
      this.debug("Statuses to keep: " + (keep.join(', ')));
      _ref3 = this.statuses;
      _results = [];
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        status = _ref3[_i];
        _results.push(status.previewLoaded() ? (_ref4 = status.id(), __indexOf.call(keep, _ref4) < 0) ? status.unloadPreview() : void 0 : void 0);
      }
      return _results;
    },
    fetchNew: function() {
      this.trackEvent('api', 'fetchNew');
      return this.timelineCallback({
        count: this.fetchCount,
        since_id: this.statuses[0].id()
      }).first(this.fetchCount, __bind(function(statuses) {
        var newStatuses, s;
        newStatuses = (function() {
          var _i, _len, _ref, _results;
          _ref = statuses.array;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            s = _ref[_i];
            if (s.id !== this.statuses[0].id()) {
              _results.push(s);
            }
          }
          return _results;
        }).call(this);
        this.debug("" + statuses.array.length + " received statuses filtered to " + newStatuses.length + " new");
        if (newStatuses.length > 0) {
          this.receiveNew(newStatuses);
          this.trackEvent('api', 'newFetched');
        }
        return this.scheduleFetching();
      }, this));
    },
    fetch: function() {
      var last;
      if (this.fetching) {
        return;
      }
      this.fetching = true;
      last = this.statuses[this.statuses.length - 1];
      this.debug("fetching old before " + last);
      this.timelineCallback({
        count: this.fetchCount,
        max_id: last.id()
      }).first(this.fetchCount, __bind(function(statuses) {
        this.receive(statuses.array);
        return this.fetching = false;
      }, this));
      return this.trackEvent('api', 'fetch');
    },
    receiveNew: function(statuses) {
      return this.receive(statuses, true);
    },
    receive: function(statuses, newer) {
      var s;
      if (newer == null) {
        newer = false;
      }
      this.debug("got " + statuses.length + " statuses");
      statuses = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = statuses.length; _i < _len; _i++) {
          s = statuses[_i];
          _results.push(new Status(s));
        }
        return _results;
      })();
      if (statuses.count === 0) {
        return;
      }
      if (this.statuses.count === 0) {
        return this.statuses = statuses;
      } else if (newer) {
        this.statuses = statuses.concat(this.statuses);
        this.curIdx += statuses.length;
        this.newCount += statuses.length;
        $(".buttonnew .count").text(this.newCount);
        return this.enableButton($('.buttonnew'), __bind(function() {
          return this.showNew();
        }, this));
      } else {
        return this.statuses = this.statuses.concat(statuses);
      }
    },
    retweet: function() {
      this.status.retweet();
      $('#tweet').addClass('retweeted');
      $('#tweet .actions a.retweet').unbind();
      return this.trackEvent('status', 'retweet');
    },
    toggleFavorite: function() {
      if (this.status.toggleFavorite()) {
        this.trackEvent('status', 'favourite');
        $('#tweet').addClass('favorited');
        return $('#tweet .actions a.favorite b').text('Unfavorite');
      } else {
        this.trackEvent('status', 'unfavourite');
        $('#tweet').removeClass('favorited');
        return $('#tweet .actions a.favorite b').text('Favorite');
      }
    },
    hasNext: function(count) {
      if (count == null) {
        count = 1;
      }
      return this.curIdx - count >= 0;
    },
    hasPrevious: function(count) {
      if (count == null) {
        count = 1;
      }
      return this.curIdx + count < this.statuses.length;
    },
    next: function() {
      if (this.hasNext()) {
        this.changeStatus(this.curIdx - 1);
        return this.trackEvent('status', 'next');
      }
    },
    previous: function() {
      if (this.hasPrevious()) {
        this.changeStatus(this.curIdx + 1);
        return this.trackEvent('status', 'previous');
      }
    },
    open: function() {
      if (this.status.link != null) {
        this.ignoreUnload();
        window.location = this.status.link.href;
        return this.trackEvent('status', 'open');
      }
    },
    showNew: function() {
      if (this.newCount > 0) {
        this.changeStatus(0);
        this.newCount = 0;
        return this.trackEvent('status', 'new');
      }
    },
    clearNew: function() {
      $('.buttonnew .count').text(0);
      return this.disableButton($('.buttonnew'));
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
      $('#contentarea .current').removeClass('current');
      $('#tweet').remove();
      this.showStatus(idx);
      if (idx === 0) {
        return this.clearNew();
      }
    },
    catchUnload: function() {
      return $(window).bind('beforeunload', function() {
        return 'You (or the previewed tweet URL) is trying to leave tweetshow. Do you wish to leave?';
      });
    },
    ignoreUnload: function() {
      return $(window).unbind('beforeunload');
    },
    signout: function() {
      this.ignoreUnload();
      this.trackEvent('auth', 'signout');
      twttr.anywhere.signOut();
      return window.location.reload();
    },
    resize: function() {
      return $("#contentarea").height($(window).height() - 220);
    },
    trackEvent: function(category, action) {
      return _gaq.push('_trackEvent', category, action);
    },
    debug: function() {
      var messages;
      messages = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (!window.location.href.match('\.dev/')) {
        return;
      }
      if (typeof console === "undefined" || console === null) {
        return;
      }
      return console.log(messages.join(' '));
    }
  };
  Status = (function() {
    function Status(status) {
      this.status = status;
      this.favorited = this.status.favorited;
      this.retweeted = this.status.retweeted;
      this.status.id = this.status.idStr;
      this.status.attributes.id = this.status.attributes.id_str;
      this.status.createdAtISO = new Date(status.createdAt).toISOString();
      this.render();
    }
    Status.prototype.id = function() {
      return this.status.id;
    };
    Status.prototype.render = function() {
      if (this.renderedStatus == null) {
        this.renderedStatus = ich.tweetTpl(this.status);
        this.renderedStatus.find('.text').linkify({
          use: [],
          handleLinks: __bind(function(links) {
            this.links = links.addClass('url').attr('target', '_blank');
            if (this.links.length > 0) {
              return this.link = this.links[this.links.length - 1];
            }
          }, this)
        }).linkify({
          use: 'twitterHashtag',
          handleLinks: function(tags) {
            return tags.addClass('hashtag').attr('target', '_blank');
          }
        });
        this.renderedStatus.find("abbr.timeago").timeago();
      }
      return this.renderedStatus;
    };
    Status.prototype.renderPreview = function() {
      var _ref;
      return (_ref = this.renderedPreview) != null ? _ref : this.renderedPreview = $(ich.previewTpl(this.link)).addClass("s" + (this.id()));
    };
    Status.prototype.retweet = function() {
      this.status.retweet();
      return this.retweeted = true;
    };
    Status.prototype.toggleFavorite = function() {
      if (this.favorited) {
        this.status.unfavorite();
        this.favorited = false;
      } else {
        this.status.favorite();
        this.favorited = true;
      }
      return this.favorited;
    };
    Status.prototype.previewLoaded = function() {
      return this.previewElem().length > 0;
    };
    Status.prototype.previewElem = function() {
      return $(".preview.s" + (this.id())).first();
    };
    Status.prototype.unloadPreview = function() {
      Tweetshow.debug("Unloading " + this);
      return this.previewElem().remove();
    };
    Status.prototype.toString = function() {
      return "" + this.status.id + "/" + this.status.text.slice(0, 11) + " (" + this.status.createdAt + ")";
    };
    return Status;
  })();
  $(document).ready(function() {
    return Tweetshow.init();
  });
}).call(this);
