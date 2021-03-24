*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
TYPES:
  BEGIN OF ty_s_token,
    api           TYPE string,
    timeupdated   TYPE string,
    access_token  TYPE string,
    refresh_token TYPE string,
    token_type    TYPE string,
    scope         TYPE string,
    expires_in    TYPE string,
  END OF ty_s_token.