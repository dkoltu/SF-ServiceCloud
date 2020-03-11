/**
* @author Magnet360
* @date 2019
*
* @group Case
* @group-content ../../ApexDocContent/Case.htm
*
* @description Publicly Exposed Apex Class that is responsible for updating CCPA cases
* when a user clicks the links in the emails. Works in conjunction with a flow.
*/
@RestResource(urlMapping='/public/v1/privacy/*')
global class Privacy_ProcessResponse_API  {


    @HttpGet
    global static void restGet() {
		RestRequest req = RestContext.request;
		
		//Input variables available - These must be the same as the inputs for the Flow!!
		//String in_caseid = (String) req.params.get('in_caseid');
		//String in_response = (String) req.params.get('in_response');
		//String in_verificationCode =  (String) req.params.get('in_verificationCode');

		RestResponse resp = RestContext.response;
		

		Flow.Interview.updateCaseWithEmailResponse flow1 = new Flow.Interview.updateCaseWithEmailResponse(req.params);
		flow1.start();
		


		//TODO - try/catch for Flow exception and set a clean body
		String respMessage = 'Your response was not successfully processed. Please email customer support';
		if (flow1.getVariableValue('out_success').equals(true)){
		   respMessage = 'Your response was successfully processed. Click here to close the window';
		}

		String response =  '<html><head><title>PVH Privacy Request Processing</title><script type="text/javascript">' +
		'    function closeCurrentTab(){ ' +
		'		var conf=confirm("Are you sure, you want to close this tab?"); ' +
		'		if(conf==true){ ' +
		'			close(); ' +
		'		} ' +
		'	} ' +
		'</script> ' +
		'</head><body style="text-align: center;">' +
		'<p><input type="button" value="' + respMessage + '" onclick="window.close()"' + '</body></html>' ;

		resp.responseBody = Blob.valueOf(response);

		resp.headers.put('Content-Type', 'text/html; charset=utf-8');
		
    }   


}