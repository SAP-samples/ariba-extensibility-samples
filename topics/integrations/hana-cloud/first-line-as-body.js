importClass(com.sap.gateway.ip.core.customdev.util.Message);
importClass(java.util.HashMap);
function processData(message) {
  var messageLog = messageLogFactory.getMessageLog(message);

  //body
  var body = message.getBody(new java.lang.String().getClass());
  var lines = body.split("\n");

  var sqlStatement = lines[1];

  messageLog.setStringProperty("INSERTStatement", sqlStatement);

  message.setBody(sqlStatement);

  return message;
}
