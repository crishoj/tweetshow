(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.Sweetshow = {
    init: function(twitter) {
      this.twitter = twitter;
      this.user = this.twitter.currentUser;
      $('#container').html(ich.sweetTpl(this.user));
      this.user.lists().each(function(list) {
        return $('#lists').append(ich.listTpl(list));
      });
      return this.showTimeline(this.user.homeTimeline());
    },
    showTimeline: function(timeline) {
      $.log('showTimeline');
      this.timeline = timeline;
      return this.timeline.first(40, __bind(function(statuses) {
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
        handleLinks: this.handleLinks
      });
      $("abbr.timeago").timeago();
      this.twitter.linkifyUsers();
      this.twitter.hovercards();
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
      $('#contentarea').html('');
      return this.showStatus(idx);
    },
    handleLinks: function(links) {
      links.addClass('url');
      return $('#contentarea').height($(window).height() - 220).html(ich.previewTpl(links[0]));
    }
  };
  $(document).ready(function() {
    $.log('ready');
    $(window).bind('beforeunload', function() {
      return 'You (or the previewed tweet URL) is trying to leave Sweetshow. Do you wish to leave?';
    });
    return twttr.anywhere(function(T) {
      $.log('anywhere loaded');
      $("#loading").hide();
      if (T.isConnected()) {
        $.log('connected');
        return Sweetshow.init(T);
      } else {
        $.log('not connected');
        $('#connect').show();
        return T("#connectButton").connectButton({
          size: "xlarge",
          authComplete: function() {
            return Sweetshow.init(T);
          }
        });
      }
    });
  });
}).call(this);
