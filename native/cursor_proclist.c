/* Linux stand-in for Cursor's private cursor_proclist.node.
 * The JS wrapper (dist/deps/cursor-proclist/index.js) requires:
 *   cursor_proclist_scan_async
 *   cursor_proclist_system_memory
 * There is no public Linux source. We export no-ops so require() succeeds.
 */
#include <node_api.h>

static napi_value ScanAsync(napi_env env, napi_callback_info info) {
  napi_deferred deferred;
  napi_value promise;
  napi_value empty;
  if (napi_create_promise(env, &deferred, &promise) != napi_ok) {
    return NULL;
  }
  if (napi_create_array_with_length(env, 0, &empty) != napi_ok) {
    napi_value err;
    napi_create_string_utf8(env, "array alloc failed", NAPI_AUTO_LENGTH, &err);
    napi_reject_deferred(env, deferred, err);
    return promise;
  }
  napi_resolve_deferred(env, deferred, empty);
  return promise;
}

static napi_value SystemMemory(napi_env env, napi_callback_info info) {
  napi_value result;
  napi_get_null(env, &result);
  return result;
}

static napi_value Init(napi_env env, napi_value exports) {
  napi_value fn_scan;
  napi_value fn_mem;
  napi_create_function(env, "cursor_proclist_scan_async", NAPI_AUTO_LENGTH,
                       ScanAsync, NULL, &fn_scan);
  napi_create_function(env, "cursor_proclist_system_memory", NAPI_AUTO_LENGTH,
                       SystemMemory, NULL, &fn_mem);
  napi_set_named_property(env, exports, "cursor_proclist_scan_async", fn_scan);
  napi_set_named_property(env, exports, "cursor_proclist_system_memory",
                          fn_mem);
  return exports;
}

NAPI_MODULE(cursor_proclist, Init)
