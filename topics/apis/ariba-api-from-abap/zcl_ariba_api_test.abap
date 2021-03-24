CLASS zcl_ariba_api_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS:
      "! Call Analytical Reporting - Synchronous API
      "! @parameter ev_json | JSON API response
      "! @parameter ev_error | Error message returned from Ariba
      analytical_synchronous
        EXPORTING
          ev_json  TYPE string
          ev_error TYPE string.

  PROTECTED SECTION.
    DATA:
      gs_token TYPE zarbapi_token.

  PRIVATE SECTION.
    CONSTANTS:
      gc_api_name           TYPE string VALUE 'ARIBA-API' ##NO_TEXT,
      gc_apikey             TYPE string VALUE 'API-KEY' ##NO_TEXT,
      gc_oauth_secret       TYPE string VALUE 'OAUTH-SECRET' ##NO_TEXT,
      gc_get_token_body     TYPE string VALUE 'grant_type=openapi_2lo' ##NO_TEXT,
      gc_refresh_token_body TYPE string VALUE 'grant_type=refresh_token&refresh_token=' ##NO_TEXT,
      gc_realm              TYPE string VALUE 'yourreaml-T' ##NO_TEXT,
      gc_viewname           TYPE string VALUE 'DocumentFactSystemView' ##NO_TEXT,
      gc_token_destination  TYPE rfcdest VALUE 'ARIBA-TOKEN-RFC' ##NO_TEXT,
      gc_api_destination    TYPE rfcdest VALUE 'ARIBA-API-RFC' ##NO_TEXT.

    METHODS:
      "! Returns an access token.
      "! Validates if there's a token for the API. If not, then it generates a new one.
      "! If there is one, first it checks if it's valid, and if not, it refreshes the token
      "! @parameter ev_error | Error message returned from Ariba
      "! @parameter es_token | A valid token
      get_token
        EXPORTING
          ev_error TYPE string
          es_token TYPE zarbapi_token,

      "! Create a new token
      "! @parameter ev_error | Error message returned from Ariba
      "! @parameter es_token | New token
      get_new_token
        EXPORTING
          ev_error TYPE string
          es_token TYPE zarbapi_token,

      "! Refreshes the token
      "! @parameter is_token | Existing access token
      "! @parameter ev_error | Error message returned from Ariba
      "! @parameter es_token | New refreshed token
      refresh_token
        IMPORTING
          is_token TYPE zarbapi_token
        EXPORTING
          ev_error TYPE string
          es_token TYPE zarbapi_token,

      "! Checks if token is valid depending on the expiration time
      "! @parameter is_token | Existing token
      "! @parameter rv_valid | X: Token valid. Empty: Token not valid
      is_token_valid
        IMPORTING
          is_token        TYPE zarbapi_token
        RETURNING
          VALUE(rv_valid) TYPE boole_d.
ENDCLASS.



CLASS zcl_ariba_api_test IMPLEMENTATION.
  METHOD get_token.
* You must create a Z table to store the Tokens generated for each API.
* These tokens must be refreshed after the expire time; usually 24 minutes.
    SELECT SINGLE * FROM zarbapi_token INTO @DATA(ls_token)
      WHERE api EQ @gc_api_name.

*&-- If there's no token for the API, hen create a new one
    IF sy-subrc NE 0.
      get_new_token(
        IMPORTING
          ev_error = ev_error
          es_token = es_token
      ).
    ELSE.
*&-- If there's a token in the Z table, then check if it's still valid
      IF is_token_valid( ls_token ).
        es_token = ls_token.
      ELSE.
*&-- If it's not valid, then refresh the token
        refresh_token(
          EXPORTING
            is_token = ls_token
          IMPORTING
            ev_error = ev_error
            es_token = es_token
        ).
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD get_new_token.
    DATA:
      lv_response    TYPE string,
      lv_http_code   TYPE i,
      lv_http_reason TYPE string,
      ls_json_token  TYPE ty_s_token,
      lr_data        TYPE REF TO data,
      lo_http        TYPE REF TO if_http_client,
      lo_json        TYPE REF TO cl_trex_json_deserializer.

*&-- Creates an HTTP client based on a RFC destination with the Get Token API URL (https://api.ariba.com/v2/oauth/token)
    cl_http_client=>create_by_destination(
      EXPORTING
        destination              = gc_token_destination
      IMPORTING
        client                   = lo_http
      EXCEPTIONS
        argument_not_found       = 1
        destination_not_found    = 2
        destination_no_authority = 3
        plugin_not_active        = 4
        internal_error           = 5
        OTHERS                   = 6
    ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            INTO ev_error.
    ENDIF.

    DATA(lo_rest) = NEW cl_rest_http_client( io_http_client = lo_http ).
    DATA(lo_request) = lo_rest->if_rest_client~create_request_entity( ).

    lo_request->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_www_form_url_encoded ).
    lo_request->set_string_data( gc_get_token_body ).

    lo_rest->if_rest_client~set_request_header(
        iv_name  = 'Authorization'
        iv_value = |'Basic { gc_oauth_secret }'| ).

    lo_rest->if_rest_resource~post( lo_request ).

    DATA(lo_response) = lo_rest->if_rest_client~get_response_entity( ).
    lv_http_code = lo_response->get_header_field( '~status_code' ).
    lv_http_reason = lo_response->get_header_field( '~status_reason' ).
    lv_response = lo_response->get_string_data( ).

    IF lv_http_code EQ '200'.
      cl_fdt_json=>json_to_data(
        EXPORTING
          iv_json = lv_response
        CHANGING
          ca_data = ls_json_token ).

*&-- Stores the new token in the Z table for future executions
      MOVE-CORRESPONDING ls_json_token TO es_token.
      es_token-api = gc_api_name.

      MODIFY zarbapi_token FROM es_token.
      IF sy-subrc EQ 0.
        COMMIT WORK AND WAIT.
      ENDIF.
    ELSE.
      ev_error = lv_response.
    ENDIF.
  ENDMETHOD.


  METHOD is_token_valid.
    DATA:
      lv_epoch      TYPE string,
      lv_expires_in TYPE i,
      lv_timestamp  TYPE timestamp,
      lv_date       TYPE sydate,
      lv_time       TYPE sytime.

    lv_epoch      = is_token-timeupdated.
    lv_expires_in = is_token-expires_in.

    cl_pco_utility=>convert_java_timestamp_to_abap(
      EXPORTING
        iv_timestamp = lv_epoch
      IMPORTING
        ev_date      = lv_date
        ev_time      = lv_time ).

    CONVERT DATE lv_date TIME lv_time INTO TIME STAMP lv_timestamp TIME ZONE sy-zonlo.

    TRY.
        DATA(lv_tstmp_expires) = cl_abap_tstmp=>add(
            tstmp = lv_timestamp
            secs  = lv_expires_in ).
      CATCH cx_root.
    ENDTRY.

    IF lv_tstmp_expires GT lv_timestamp.
      rv_valid = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD refresh_token.
    DATA:
      lv_response    TYPE string,
      lv_body        TYPE string,
      lv_http_code   TYPE i,
      lv_http_reason TYPE string,
      ls_json_token  TYPE ty_s_token,
      lr_data        TYPE REF TO data,
      lo_http        TYPE REF TO if_http_client,
      lo_json        TYPE REF TO cl_trex_json_deserializer.

*&-- Creates an HTTP client based on a RFC destination with the Get Token API URL (https://api.ariba.com/v2/oauth/token)
    cl_http_client=>create_by_destination(
      EXPORTING
        destination              = gc_token_destination
      IMPORTING
        client                   = lo_http
      EXCEPTIONS
        argument_not_found       = 1
        destination_not_found    = 2
        destination_no_authority = 3
        plugin_not_active        = 4
        internal_error           = 5
        OTHERS                   = 6
    ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            INTO ev_error.
    ENDIF.

    CONCATENATE gc_refresh_token_body is_token-refresh_token INTO lv_body.

    DATA(lo_rest) = NEW cl_rest_http_client( io_http_client = lo_http ).
    DATA(lo_request) = lo_rest->if_rest_client~create_request_entity( ).

    lo_request->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_www_form_url_encoded ).
    lo_request->set_string_data( lv_body ).
    break dtsdev.
    lo_rest->if_rest_client~set_request_header(
        iv_name  = 'Authorization'
        iv_value = |'Basic { gc_oauth_secret }'| ).

    TRY.
        lo_rest->if_rest_resource~post( lo_request ).
      CATCH cx_root INTO DATA(lo_error).
        ev_error = lo_error->get_longtext( ).
        RETURN.
    ENDTRY.

    DATA(lo_response) = lo_rest->if_rest_client~get_response_entity( ).
    lv_http_code = lo_response->get_header_field( '~status_code' ).
    lv_http_reason = lo_response->get_header_field( '~status_reason' ).
    lv_response = lo_response->get_string_data( ).

    IF lv_http_code EQ '200'.
      cl_fdt_json=>json_to_data(
        EXPORTING
          iv_json = lv_response
        CHANGING
          ca_data = ls_json_token ).

*&-- Stores the new token in the Z table for future executions
      MOVE-CORRESPONDING ls_json_token TO es_token.
      es_token-api = gc_api_name.

      MODIFY zarbapi_token FROM es_token.
      IF sy-subrc EQ 0.
        COMMIT WORK AND WAIT.
      ENDIF.
    ELSE.
      ev_error = lv_response.
    ENDIF.
  ENDMETHOD.

  METHOD analytical_synchronous.
    DATA:
      ls_token                   TYPE zarbapi_token,
      lv_apikey                  TYPE zarbapi_param-low,
      lv_string_apikey           TYPE string,
      lv_query                   TYPE string,
      lv_body                    TYPE string,
      lv_realm_from_apiparam     TYPE zarbapi_param-low,
      lv_name_from_apiparam      TYPE zarbapi_param-low,
      lv_api_query_from_apiparam TYPE zarbapi_param-low,
      lv_http_code               TYPE i,
      lv_http_reason             TYPE string,
      lv_response                TYPE string,
      lv_error_message           TYPE string,
      lo_rest                    TYPE REF TO cl_rest_http_client,
      lo_http                    TYPE REF TO if_http_client.

*&-- Creates an HTTP client based on a RFC destination with the Analytical Reporting - Synchronous API URL
*&-- (https://openapi.ariba.com/api/analytics-reporting-details/v1/prod)
    cl_http_client=>create_by_destination(
      EXPORTING
        destination              = gc_api_destination
      IMPORTING
        client                   = lo_http
      EXCEPTIONS
        argument_not_found       = 1
        destination_not_found    = 2
        destination_no_authority = 3
        plugin_not_active        = 4
        internal_error           = 5
        OTHERS                   = 6 ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

*&-- Set query
    lv_query = |/viewName/{ gc_viewname }?realm={ gc_realm }|.

    cl_http_utility=>set_request_uri(
        request = lo_http->request
        uri     = lv_query ).

*&-- Create request
    lo_rest = NEW cl_rest_http_client( io_http_client = lo_http ).
    lo_http->propertytype_logon_popup = lo_http->co_disabled.

*&-- Get a valid Token
    get_token(
      IMPORTING
        es_token   = ls_token ).

*&-- Set Header
    lo_rest->if_rest_client~set_request_header(
        iv_name  = 'Authorization'
        iv_value = |Bearer { ls_token-access_token }| ).

    lo_rest->if_rest_client~set_request_header(
        iv_name  = 'apiKey'
        iv_value = gc_apikey ).

*&-- Call the API
    TRY.
        lo_rest->if_rest_resource~get( ).
      CATCH cx_root INTO DATA(lo_error).
        ev_error = lo_error->get_longtext( ).
    ENDTRY.

*&-- Gets the response from the API
    DATA(lo_response) = lo_rest->if_rest_client~get_response_entity( ).
    lv_http_code      = lo_response->get_header_field( '~status_code' ).
    lv_http_reason    = lo_response->get_header_field( '~status_reason' ).
    lv_response       = lo_response->get_string_data( ).

    IF lv_http_code = '200'.
      ev_json = lv_response.
    ELSE.
      ev_error = |{ lv_http_code } - { lv_response }|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.