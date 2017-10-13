$(function() {
    $("#change-form").submit(function(event) {
        event.preventDefault();
        $.getJSON(
            "make-change.cgi?mode=json" 
              + "&due=" + encodeURIComponent($("#due").val())
              + "&tendered=" + encodeURIComponent($("#tendered").val())
            , function(result) {
                $.each(result.currencies, function(i, field) {
                    window.alert(field.descr);
                });
              }
        );
    });
});

// vim: set sw=4 ts=4 et:
