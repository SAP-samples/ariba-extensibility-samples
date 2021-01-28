$.addGenerator(start);

generateMessage = function () {
  // Process the dates to be used in the API request filter parameter
  var currentDate = new Date();

  var dateTo = new Date();
  dateTo.setDate(currentDate.getDate());

  var dateFrom = new Date();
  dateFrom.setDate(currentDate.getDate() - 30);

  var updatedDateFrom = dateFrom.toISOString().slice(0, 10) + "T00:00:00Z";
  var updatedDateTo = dateTo.toISOString().slice(0, 10) + "T00:00:00Z";

  var msg = {};
  msg.Attributes = {};

  msg.Attributes["openapi.consumes"] = "application/json";
  msg.Attributes["openapi.produces"] = "application/json";
  msg.Attributes["openapi.method"] = "GET";

  // Set API header parameters
  msg.Attributes["openapi.header_params.apiKey"] = "ARIBA_API_KEY";
  msg.Attributes["openapi.path_pattern"] = "/views/InactiveSuppliers";

  // Set API query parameters
  msg.Attributes["openapi.query_params.realm"] = "realm-t";
  msg.Attributes["openapi.query_params.includeInactive"] = "true";
  msg.Attributes["openapi.query_params.filters"] =
    '{"updatedDateFrom":"' +
    updatedDateFrom +
    '","updatedDateTo":"' +
    updatedDateTo +
    '"}';

  msg.Attributes["openapi.form_params.grant_type"] = "openapi_2lo";

  return msg;
};

function start(ctx) {
  $.output(generateMessage());
}
