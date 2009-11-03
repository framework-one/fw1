// prepare all behaviors when the DOM is ready
$(document).ready(function(){
    
	// find all links and dynamically add the same handler for all 
	// since all of them will load a new page, in this case we intercept 
	// that event and load the content via AJAX and dynamically insert 
	// it into the DOM without refreshing/leaving the page
	$("body a").live("click", function(){
		var url = $(this).attr("href");
		
		$("#primary").load(url, {}, primaryLoadHandler);
		
		return false;
	});
	
	// dynamic content loaded handler
	function primaryLoadHandler(responseText, textStatus, XMLHttpRequest) 
	{
		var userForm = $('#userForm');
		
		// since we are loading page content into the DOM dynamically 
		// we need to find any new elements that are being added, in this 
		// case we are most interested in the User Form this way we can 
		// use the forms plugin to make our form submit using AJAX instead
		if (userForm.length == 1) 
		{
			var options = {
				target: '#primary', // target element(s) to be updated with server response 
				beforeSubmit: showRequest, // pre-submit callback 
				success: showResponse // post-submit callback 
				
				// other available options: 
				//url:       url         // override for form's 'action' attribute 
				//type:      type        // 'get' or 'post', override for form's 'method' attribute 
				//dataType:  null        // 'xml', 'script', or 'json' (expected server response type) 
				//clearForm: true        // clear all form fields after successful submit 
				//resetForm: true        // reset the form after successful submit 
				
				// $.ajax options can be used here too, for example: 
				//timeout:   3000 
			};
			
			// check for the UserForm and bind form using 'ajaxForm' 
			$('#userForm').ajaxForm(options);
		}
	}
	
	// pre-submit callback 
	function showRequest(formData, jqForm, options) {
	    // formData is an array; here we use $.param to convert it to a string to display it 
	    // but the form plugin does this for you automatically when it submits the data 
	    var queryString = $.param(formData)
 		
	    // jqForm is a jQuery object encapsulating the form element.  To access the 
	    // DOM element for the form do this: 
	    // var formElement = jqForm[0];
 		
	    //alert('About to submit: \n\n' + queryString);
 		
	    // here we could return false to prevent the form from being submitted; 
	    // returning anything other than false will allow the form submit to continue 
	    return true;
	}
	
	// post-submit callback 
	function showResponse(responseText, statusText) {
	    // for normal html responses, the first argument to the success callback 
	    // is the XMLHttpRequest object's responseText property 
 		
	    // if the ajaxForm method was passed an Options Object with the dataType 
	    // property set to 'xml' then the first argument to the success callback 
	    // is the XMLHttpRequest object's responseXML property 
 		
	    // if the ajaxForm method was passed an Options Object with the dataType 
	    // property set to 'json' then the first argument to the success callback 
	    // is the json data object returned by the server 
 		
	    //alert('status: ' + statusText + '\n\nThe output div should be updated with the responseText.');
	}
	
});