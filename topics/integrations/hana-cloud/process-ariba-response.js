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

  var sqlContents = "SQL Statement\n";

  var i = 0;
  var arr = body["Records"];

  for (var x = 0; x < arr.length; x++) {
    var record = arr[x];

    messageLog.setStringProperty("record", record);
    i += 1;

    // Create SQL Script
    sqlContents +=
      "INSERT INTO ARIBA_AR.SOURCING_PROJECTS (REALM, PROJECT_ID, TITLE) VALUES ('myrealm-T', '" +
      record["InternalId"] +
      "', '" +
      record["Title"] +
      "');\n";
  }

  messageLog.setStringProperty("TotalRecordsProcessed", i);
  messageLog.setStringProperty("Query", sqlContents);

  message.setBody(sqlContents);

  return message;
}
