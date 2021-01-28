importClass(com.sap.gateway.ip.core.customdev.util.Message);
importClass(java.util.HashMap);

function processData(message) {
  var messageLog = messageLogFactory.getMessageLog(message);

  //Parsing body to JSON
  var body = JSON.parse(message.getBody(new java.lang.String().getClass()));

  /* ===========
       Handle PageToken
       =============*/

  // Retrieving PageToken from payload if one exists
  if ("PageToken" in body) {
    messageLog.setStringProperty("PageToken", body["PageToken"]);
    message.setHeader("pageToken", body["PageToken"]);
  } else {
    messageLog.setStringProperty("PageToken", "NONE!");
    message.setHeader("pageToken", "STOP");
  }

  /* ===========
       Create payload
       =============*/

  var fileContents = "";

  var i = 0;
  var arr = body["Records"];

  for (var x = 0; x < arr.length; x++) {
    var record = arr[x];

    messageLog.setStringProperty("record", record);
    i += 1;

    // Create JSON line document
    fileContents +=
      '{"ID": "' +
      record["InternalId"] +
      '","Title": "' +
      record["Title"] +
      '",';
    fileContents +=
      '"Status": "' +
      record["Status"] +
      '","ParentDocumentId": "' +
      record["ParentDocument"]["InternalId"] +
      '",';
    fileContents +=
      '"ExternalSystemCorrelationId": "' +
      record["ExternalSystemCorrelationId"] +
      '",';
    fileContents +=
      '"OwnerEmail": "' + record["Owner"]["EmailAddress"] + '"}\n';
  }

  messageLog.setStringProperty("Payload", fileContents);
  messageLog.setStringProperty("TotalRecordsProcessed", i);

  message.setBody(fileContents);

  return message;
}
