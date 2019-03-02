$(document).ready(function() {
    var menuTimer;

    $("#Host").focus();

    // Below is a modified copy of function from jquery-ui.js
    $.widget("ui.menu", $.ui.menu, {
        collapseAll: function( event, all ) {
            clearTimeout( this.timer );
            this.timer = this._delay( function() {
    
                // If we were passed an event, look for the submenu that contains the event
                var currentMenu = all ? this.element :
                    $( event && event.target ).closest( this.element.find( ".ui-menu" ) );
    
                // If we found no valid submenu ancestor, use the main menu to close all
                // sub menus anyway
                if ( !currentMenu.length ) {
                    currentMenu = this.element;
                }
    
                this._close( currentMenu );
    
                this.blur( event );
    
                // Work around active item staying active after menu is blurred
                this._removeClass( currentMenu.find( ".ui-state-active" ), null, "ui-state-active" );
    
                this.activeMenu = currentMenu;
                // Below is custom for Westar
                clearTimeout(menuTimer);
                menuTimer = setTimeout(
                    function() {
                        if (!($("#Menu li div").hasClass("ui-state-active"))) {
                            $("#AppsDiv").fadeTo("fast", 1);
                        }
                    },
                    400
                );
                // Above is custom for Westar
            }, this.delay );
        }
    });
    // Above is a modified copy of function from jquery-ui.js

    $("#Menu").menu({
        select: function(event, ui) {
            $("#Host").val($(ui.item).find("div").attr("tag"));
            $("#Menu").menu("collapseAll", null, true);
            $("#AppsDiv").fadeTo("fast", 1);
        },
        focus: function(event, ui) {
            clearTimeout(menuTimer);
            menuTimer = setTimeout(
                function() {
                    if ($("#Menu li div").hasClass("ui-state-active")) {
                        $("#AppsDiv").fadeTo("fast", 0.25);
                    }
                },
                400
            );
        },
        blur: function(event, ui) {
            clearTimeout(menuTimer);
            menuTimer = setTimeout(
                function() {
                    if (!($("#Menu li div").hasClass("ui-state-active"))) {
                        $("#AppsDiv").fadeTo("fast", 1);
                    }
                },
                400
            );
        }
    });

    $("#Menu").show();

    $(".AppTile").click(function() {
        var Host = $("#Host").val();
        if (!Host) {
            alert("Please enter a host in the text field.");
        }
        else if (window.external.InvokePowerShell("return Test-Connection -ComputerName " + Host + " -Count 1 -Quiet") == "False") {
            alert("Unable to ping the host entered.");
        }
        else {
            var Command = $(this).attr("Command");
            var Parameters = $(this).attr("Parameters").replace("DUMMYCOMPUTERNAME", Host).replace(/\"/g, "`\"");
            
            $(this).effect(
                "highlight", 
                { color: "#444444" }
            );

            window.external.InvokePowerShell("Start-Process -FilePath \"" + Command + "\" -ArgumentList \"" + Parameters + "\""); // -WindowStyle Maximized
        }
        $("#Host").focus();
    });
});