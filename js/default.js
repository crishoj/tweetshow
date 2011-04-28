$(function(){

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
        twttr.anywhere.signOut();
        location.reload();
    });
	
	
	
    ///////////////
    // FRONTPAGE //
    ///////////////
    $("#listitem").nucombo();
	
    // LOG IN AND LOAD
    $('#listitem').change(function() {
        //alert( 'Value=' + $(this).attr("value") );
        $("#listitem").nucombo("remove");
        $('#container').load('subpage.html', function() {
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


});