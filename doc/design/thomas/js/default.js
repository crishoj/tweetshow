$(function(){

	/*
	$(".gallery a").hover(function(){
	  $(this).animate({"marginTop": "-2px"}, "fast");
	}, function () {
	  $(this).animate({"marginTop": "0px"}, "fast");
	});
	
	$("article a").hover(function() {
		$(this).stop().animate( { color:'#fff' }, 400);
	}, function() {
		$(this).animate( { color:'#999' }, 400);
	});
	
	$(".subnavigation li:not(:first-child):not(.selected) a").hover(function() {
		$(this).stop().css( { color:'#fff' }, 400);
	}, function() {
		$(this).animate( { color:'#999' }, 400);
	});
	*/
	
	
	////////////////////
	// MISC FUNCTIONS //
	////////////////////
	function resizeIframe() {
		$("#contentarea").height( $(window).height() - 220 );
	}
	
	$("input").focus(function() { 
		$(this).select();
	});
	
	
	/////////////
	// SUBPAGE //
	/////////////
	$(window).resize(function() {
		  resizeIframe();
	});
	
	$('.buttonnext').live('click', function() {
		alert("Next");
	});
	
	$('.buttonprevious').live('click', function() {
		alert("Previous");
	});
	
	$('.buttonall').live('click', function() {
		alert("All");
	});
	
	$('.buttonnew').live('click', function() {
		alert("New");
	});
	
	$('.item2 li a').live('click', function() {
		$('#contentarea').load('list.html', function() {
			$('#contentarea').css("overflow","auto");
			resizeIframe();
		});
	});
	
	$('.item3 a').live('click', function() {
		alert("LOGGING OUT");
	});
	
	
	
	///////////////
	// FRONTPAGE //
	///////////////
	$("#listitem").nucombo();
	
	// LOG IN AND LOAD
	$('#listitem').change(function() {
		//alert( 'Value=' + $(this).attr("value") );
		$("#listitem").nucombo("remove");
		$('#container').load('subpage.php', function() {
			resizeIframe();
		});
	});
	
	// LOGIN
	$('#logind').submit(function() {
	 
		$.ajax({
		  url: 'login-and-load-list.html',
		  data: 'name='+$('#accountname').val()+'&kode='+$('#accountpassword').val(),
		  success: function(data) {
			  if(data=="notLoggedIn")
			  {
				$('#message').html('<p>We could not log you in</p>');
				$('#message').removeClass('hidden').show().delay(2000).fadeOut('slow');
			  } else {
				$("#disabled").remove();
				$('#listitem').html(data);
				$("#listitem").nucombo("remove"); 
				$("#listitem").nucombo();
			  }
		  },
		  error: function(data) {
				$('#message').html('<p>Error</p>');
				$('#message').removeClass('hidden').show().delay(2000).fadeOut('slow');
		  }
		});
		
		return false;
	});


var a=navigator.userAgent.toLowerCase();var p=navigator.platform.toLowerCase();if (p.match('^win')) {$('body').addClass('windows');}else if(p.match('^mac')){$('body').addClass('mac');}else if(p.match('^linux')){$('body').addClass('linux');}else if(p.match('^iphone')){$('body').addClass('mobile');$('body').addClass('iphone');}else if(p.match('^android')){$('body').addClass('mobile');$('body').addClass('android');}$.browser.chrome=/chrome/.test(navigator.userAgent.toLowerCase());if($.browser.msie){$('body').addClass('browserIE');$('body').addClass('browserIE'+$.browser.version.substring(0,1))}if($.browser.chrome){$('body').addClass('browserChrome');a=a.substring(a.indexOf('chrome/')+7);a=a.substring(0,1);$('body').addClass('browserChrome'+a);$.browser.safari=false}if($.browser.safari){$('body').addClass('browserSafari');a=a.substring(a.indexOf('version/')+8);a=a.substring(0,1);$('body').addClass('browserSafari'+a)}if($.browser.mozilla){if(navigator.userAgent.toLowerCase().indexOf('firefox')!=-1){$('body').addClass('browserFirefox');a=a.substring(a.indexOf('firefox/')+8);a=a.substring(0,1);$('body').addClass('browserFirefox'+a)}else{$('body').addClass('browserMozilla')}}if($.browser.opera){$('body').addClass('browserOpera')}

});