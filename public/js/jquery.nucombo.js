// jQuery nucombo Plugin
// The jquery.nucombo plugin can be used to style <select> elements, as the existing HTML <select> element has limited CSS// styling options.
// It is fully compatible with the ASP.NET DropDownList control and integrates fully with the ASP.NET page cycle and AJAX.
//
// Version 1.01
//
// Edwill Leighton
// Protocol Software Development (http://www.protosoft.co.za/)
// 2 March 2011
//
// Usage:
//		$(SELECTOR).nucombo();
//      $(SELECTER).nucombo("remove"); <== removes nucombo
//
// Example:
//      $("#ddl").nucombo();
// 
// History:
//
//      1.00 - Released (2 March 2011)
//      1.01 - Updated to hide dropdown when clicked outside the dropdown area (18 March 2011)
//
// License:
// 
// This plugin is dual-licensed under the GNU General Public License and the MIT License and
// is copyright 2011 Protocol Software Development. 
//
(function ($) {

    var methods = {
        init: function () {

            var ret = this.each(function () {
                var ddl = $(this);
                var ddlos = ddl.offset();
                var divstr = "<div class='cb-dropdown' onclick='$(this).nucombo(\"dropdown\");' ddmain='" + ddl.attr("id") + "' style='top:" + ddlos.top + "px;left:" + ddlos.left + "px;width:" + ddl.outerWidth() + "px;'><div class='cb-dropdowninner'>" + ddl.find("option:selected").text() + "</div></div>";
                divstr += "<div class='cb-hidden cb-items' ddmain='" + ddl.attr("id") + "' style='top:" + (ddlos.top + ddl.outerHeight()) + "px;left:" + (ddlos.left) + "px;width:" + ddl.outerWidth() + "px;'>";
                ddl.find("option").each(function () { divstr += "<div class='cb-item' val='" + $(this).val() + "' onclick='$(this).nucombo(\"selectitem\");'>" + $(this).text() + "</div>"; });
                divstr += "</div>";

                $(divstr).appendTo("body");

                ddl.addClass("cb-hidden");
            });

            $('body').click(function () {
                $(".cb-items").addClass("cb-hidden");
            });
            $('.cb-dropdown').click(function (event) { event.stopPropagation(); });            

            $(window).resize(function () {
                $(".cb-dropdown").each(function () {
                    var ddl = $(this);
                    var orgdd = $("#" + ddl.attr("ddmain"));
                    orgdd.removeClass("cb-hidden");
                    var orgddos = orgdd.offset();
                    var items = $(".cb-items[ddmain='" + ddl.attr("ddmain") + "']");
                    ddl.css("left", orgddos.left + "px");
                    ddl.css("top", orgddos.top + "px");
                    items.css("left", orgddos.left + "px");
                    items.css("top", (orgddos.top + orgdd.outerHeight()) + "px");
                    orgdd.addClass("cb-hidden");
                });
            });

            try {
                var prm = Sys.WebForms.PageRequestManager.getInstance();
                prm.add_endRequest(EndRequestHandler);

                function EndRequestHandler(sender, args) {
                    $(".cb-dropdown").each(function () {
                        $("#" + $(this).attr("ddmain")).nucombo("remove").nucombo();
                    });
                }
            }
            catch (e) { }

            return ret;
        },

        remove: function () {
            return this.each(function () {
                var id = $(this).attr("id");
                $(".cb-dropdown[ddmain='" + id + "']").remove();
                $(".cb-items[ddmain='" + id + "']").remove();
                $("#" + id).removeClass("cb-hidden");
            });
        },

        dropdown: function () {
            $(".cb-items").addClass("cb-hidden");
            $(".cb-items[ddmain='" + $(this).attr("ddmain") + "']").removeClass("cb-hidden");
        },

        selectitem: function () {
            var item = $(this);
            var items = item.parent();
            var orgdd = $("#" + items.attr("ddmain"));
            var dd = $(".cb-dropdown[ddmain='" + items.attr("ddmain") + "'] .cb-dropdowninner");
            dd.html(item.html());
            items.addClass("cb-hidden");
            orgdd.val(item.attr("val"));
            orgdd.change();
        }
    };

    $.fn.nucombo = function (method) {
        if (methods[method]) {
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        } else if (typeof method === 'object' || !method) {
            return methods.init.apply(this, arguments);
        } else {
            $.error('Method ' + method + ' does not exist on jQuery.nucombo');
        }
    };

})(jQuery);
