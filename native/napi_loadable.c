/* Minimal N-API addon: dlopen succeeds, no exports.
 * Used for private Windows-only Cursor modules that have no Linux source.
 */
#include <node_api.h>

static napi_value Init(napi_env env, napi_value exports) { return exports; }

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)
