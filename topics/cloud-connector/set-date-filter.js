importClass(com.sap.gateway.ip.core.customdev.util.Message);
importClass(java.util.HashMap);

function processData(message) {
  // Set the value for filters query parameter
  message.setHeader(
    "dateFilter",
    '{"createdDateFrom":"2019-07-01T00:00:00Z","createdDateTo":"2020-06-05T00:00:00Z"}'
  );

  return message;
}
