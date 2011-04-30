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
	
    ///////////////
    // FRONTPAGE //
    ///////////////
    $("#listitem").nucombo();
	
    $('#listitem').change(function() {
        //alert( 'Value=' + $(this).attr("value") );
        $("#listitem").nucombo("remove");
        $('#container').load('subpage.html', function() {
            resizeIframe();
        });
    });
	

});