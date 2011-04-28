(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.Sweetshow = {
    show: function(user) {
      this.user = user;
      $('#container').html(ich.sweetTpl(user));
      user.lists().each(function(list) {
        return $('#lists').append(ich.listTpl(list));
      });
      return this.showTimeline(user.homeTimeline());
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
      twttr.anywhere(function(T) {
        T.linkifyUsers();
        return T.hovercards();
      });
      $("abbr.timeago").timeago();
      $("#tweet .text").linkify({
        handleLinks: this.handleLinks
      });
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
    return twttr.anywhere(function(T) {
      $.log('anywhere loaded');
      $("#loading").hide();
      if (T.isConnected()) {
        $.log('connected');
        return Sweetshow.show(T.currentUser);
      } else {
        $.log('not connected');
        $('#connect').show();
        return T("#connectButton").connectButton({
          size: "xlarge",
          authComplete: function() {
            return Sweetshow.show(T.currentUser);
          }
        });
      }
    });
  });
}).call(this);
