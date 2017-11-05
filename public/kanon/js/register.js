$(document).ready(function() {

  $("#registerButton").attr('disabled', true);
  $("#newPassword, #confirmNewPassword").keyup(checkPasswordMatch);

	$("#login_form").submit( function(eventObj) {
      $('<input />').attr('type', 'hidden')
          .attr('name', "_csrf")
          .attr('value', getCsrfToken())
          .appendTo(this);
      return true;
 	});

  $("#register_form").submit( function(eventObj) {
      $('<input />').attr('type', 'hidden')
          .attr('name', "_csrf")
          .attr('value', getCsrfToken())
          .appendTo(this);
      return true;
  });
});

function checkPasswordMatch() {
    var password = $("#newPassword").val();
    var confirmPassword = $("#confirmNewPassword").val();

    if (password.length > 8){
    	if (password == confirmPassword) {
	    	$("#registerButton").attr('disabled', false);
	        $("#divCheckPasswordMatch").html("Passwords match!");
	    }  	
	    else {
	    	$("#registerButton").attr('disabled', true);
	        $("#divCheckPasswordMatch").html("Passwords do not match.");
	    } 
    } else {
    	$("#registerButton").attr('disabled', true);
	    $("#divCheckPasswordMatch").html("Password is too short!");
    }    	
}

function validateOTPForm() {
    if ($("#otpCode").val() == ""){
        console.log("otp code empty");
    } else {
        $('#register_form').submit();
    }
}
function validateLoginForm() {
    if ($("#username").val() == "" || $("#password").val() == "" ){
        console.log("username or password empty");
    } else {
        $('#login_form').submit();
    }
}