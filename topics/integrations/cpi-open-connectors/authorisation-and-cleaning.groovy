import com.sap.gateway.ip.core.customdev.util.Message;
import com.sap.it.api.ITApiFactory;
import com.sap.it.api.securestore.SecureStoreService;
import com.sap.it.api.securestore.UserCredential;
import com.sap.it.api.securestore.exception.SecureStoreException;

def Message processData(Message message) {
    
        def messageLog = messageLogFactory.getMessageLog(message);
        
        /* ============
         Set Authorization header
        =============== */
        
        def service = ITApiFactory.getApi(SecureStoreService.class, null);
        
        if( service != null)
        {
            // Retrieve credential name from property
            def credentialName = message.getProperties()["OC_Credential"];
            
            //Get UserCredential containing user credential details
            def credential = service.getUserCredential(credentialName);
            message.setHeader("Authorization", new String(credential.getPassword()));
            
        }
        
        /* ============
         Modify payload
        =============== */
        
        def bodyStr = message.getBody(java.lang.String) as String;
        
        messageLog.setStringProperty("beforeBody", bodyStr);
        
        // Replacing problematic characters
        body = bodyStr.replaceAll("\n", "\r\n");
        
        messageLog.setStringProperty("afterBody", body);
        
        message.setBody(body);
        
       return message;
}
