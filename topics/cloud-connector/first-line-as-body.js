importClass(com.sap.gateway.ip.core.customdev.util.Message);
importClass(java.util.HashMap);
function processData(message) {
  var messageLog = messageLogFactory.getMessageLog(message);

  //body
  var body = message.getBody(new java.lang.String().getClass());
  var lines = body.split("\n");

  var jsonRequest = lines[1];

  messageLog.setStringProperty("JSONPayload", jsonRequest);

  message.setBody(jsonRequest);

  return message;
}
