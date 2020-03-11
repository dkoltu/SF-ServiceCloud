public class MyJWTController {
    
        public MyJWTController() {      
        Auth.JWT jwt = new Auth.JWT();
        jwt.setSub('sfsc-function-invoker@p-g-martech-salesforce-p.iam.gserviceaccount.com'); 
        jwt.setAud('https://www.googleapis.com/oauth2/v4/token'); 
        jwt.setIss('sfsc-function-invoker@p-g-martech-salesforce-p.iam.gserviceaccount.com');
        
        //Additional claims to set scope
        Map<String, Object> claims = new Map<String, Object>();
        claims.put('scope', 'https://us-central1-p-g-martech-salesforce-p.cloudfunctions.net/bcrypt');
            
        jwt.setAdditionalClaims(claims);
         //   jwt.setAdditionalClaims();

        //Create the object that signs the JWT bearer token
        Auth.JWS jws = new Auth.JWS(jwt, 'bCryptGCPPrivateKey');
        
        //Get the resulting JWS in case debugging is required
        String token = jws.getCompactSerialization();
        
        //Set the token endpoint that the JWT bearer token is posted to
        String tokenEndpoint = 'https://www.googleapis.com/oauth2/v4/token';
        
        //POST the JWT bearer token
        Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, jws);
        
        //Get the access token
        String accessToken = bearer.getAccessToken();
            
        system.debug('### accessToken' + accessToken);

    }

}