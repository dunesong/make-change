$(function() {
    $("#change-form").submit(function(event) {
        event.preventDefault();
        $("#results").empty();
        $.ajax({
            type: "GET"
            , url: "?mode=json" 
              + "&due=" + encodeURIComponent($("#due").val())
              + "&tendered=" + encodeURIComponent($("#tendered").val())
            , error: function(xhr, status, error) {
                result = JSON.parse(xhr.responseText);
                message = "";
                message += '<p class="alert alert-danger">';
                message += '<strong>Error:</strong> ';
                message += result.error;
                message += "</p>";
                $("#results").append(message);
              }
            , success: function(result) {
                message = "";
                message += '<table class="table table-striped">';
                message += '<tbody>';
                message += '<tr scope="row" class="info">';
                message += '<th>Amount Due</th><td>';
                if(result.amount_due || 0 == result.amount_due) {
                    message += '$' + result.amount_due.toFixed(2);
                }
                message += '</td></tr>';
                if(result.currencies && result.currencies.length > 0) {
                    message += '<tr>';
                    message += '<th scope="col" id="quantity-header">';
                    message += 'Quantity';
                    message += '</th>';
                    message += '<th scope="col">Currency</th></tr>';
                    $.each(result.currencies, function(i, field) {
                        message += '<tr><td align="right">';
                        message += field.amount;
                        message += " &times;</td><td>";
                        message += field.descr;
                        message += '</td></tr>';
                    });
                }
                message += '</tbody></table>';
                $("#results").append(message);
              }
        });
    });
});

// vim: set sw=4 ts=4 et:
