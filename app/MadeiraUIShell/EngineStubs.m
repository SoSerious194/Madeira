// Stand-ins for Madeira's engine bridges, so the app's unmodified UI builds and
// runs in the iOS Simulator. Every function reports "not running" or fails, so
// the library, settings and Steam screens work and starting a game does not.

#import <Foundation/Foundation.h>
#import <QuartzCore/CAMetalLayer.h>
#include "../Madeira/FEXBridge.h"
#include "../Madeira/WineServerBridge.h"
#include "../Madeira/WineProcessBridge.h"
#include "../Madeira/IOSDisplayShim.h"
#include "../Madeira/MadeiraRPPairing.h"

// FEXBridge.h
bool fex_initialize(void) { return false; }
void fex_shutdown(void) {}
int64_t fex_test_execute(void) { return -1; }
void fex_set_log_callback(fex_log_callback_t callback) { (void)callback; }
int64_t fex_get_jit_write_offset(void) { return 0; }

// WineServerBridge.h
volatile int ws_log_quiet = 0;
int wineserver_start(const char *prefix_path) { (void)prefix_path; return -1; }
int wineserver_is_running(void) { return 0; }
int wineserver_is_ready(void) { return 0; }
void wineserver_stop(void) {}
void wineserver_inject_client_fd(int fd) { (void)fd; }

// WineProcessBridge.h
int wine_process_start(const char *prefix_path) { (void)prefix_path; return -1; }
int wine_process_is_running(void) { return 0; }
void wine_launched_process_did_exit(int status) { (void)status; }
int wine_crash_exit_status(uint32_t *status) { (void)status; return 0; }
void wine_exit_status_reset(void) {}
int madeira_write_continue_flag(void) { return 0; }
void madeira_seed_prefix_if_needed(const char *prefix_path) { (void)prefix_path; }

// IOSDisplayShim.h
NSString * const MadeiraDisplayModeChangedNotification = @"MadeiraDisplayModeChangedNotification";
void madeira_display_set_layer(CAMetalLayer *layer) { (void)layer; }
void winios_screen_size(int *w, int *h) { if (w) *w = 1280; if (h) *h = 720; }
void winios_display_mode_changed(int w, int h) { (void)w; (void)h; }

// MadeiraRPPairing.h: in-app JIT pairing is unavailable.
MadeiraRPPairing *madeira_rppairing_new(const char *name, char **error) {
    (void)name;
    if (error) *error = strdup("JIT pairing is not available in the UI shell");
    return NULL;
}
uint16_t madeira_rppairing_port(const MadeiraRPPairing *session) { (void)session; return 0; }
const char *madeira_rppairing_service_name(const MadeiraRPPairing *session) { (void)session; return ""; }
size_t madeira_rppairing_txt_count(const MadeiraRPPairing *session) { (void)session; return 0; }
const char *madeira_rppairing_txt_key(const MadeiraRPPairing *session, size_t index) { (void)session; (void)index; return ""; }
const char *madeira_rppairing_txt_value(const MadeiraRPPairing *session, size_t index) { (void)session; (void)index; return ""; }
int32_t madeira_rppairing_accept(const MadeiraRPPairing *session, MadeiraRPPairingPinCallback pin_callback, void *pin_context,
                                 uint8_t **out_plist, size_t *out_len, char **out_device_name, char **error) {
    (void)session; (void)pin_callback; (void)pin_context; (void)out_plist; (void)out_len; (void)out_device_name;
    if (error) *error = strdup("JIT pairing is not available in the UI shell");
    return -1;
}
void madeira_rppairing_cancel(const MadeiraRPPairing *session) { (void)session; }
void madeira_rppairing_free(MadeiraRPPairing *session) { (void)session; }
void madeira_rppairing_bytes_free(uint8_t *bytes, size_t len) { (void)len; free(bytes); }
void madeira_rppairing_string_free(char *string) { free(string); }

// Declared in the bridging header and in Winios.m, lzma_shim.c and
// PadOutput.m; implemented by the engine libraries.
void ios_dump_all_thread_stacks(void) {}
void wine_set_ui_log_callback(void (*cb)(const char *)) { (void)cb; }
void madeira_capture_request(int frames) { (void)frames; }
int madeira_d3d12_canary_run_log(const char *fixture_dir, const char *dylib_path, void (*sink)(const char *),
                                 const char *log_path, const char *build_id) {
    (void)fixture_dir; (void)dylib_path; (void)sink; (void)log_path; (void)build_id;
    return -1;
}
CAMetalLayer *madeira_display_layer(void) { return nil; }
int madeira_dxmt_has_40_cap(void) { return 0; }
int madeira_dxmt_has_display_pacing(void) { return 0; }
int madeira_get_eco(void) { return 0; }
void madeira_set_eco(int on) { (void)on; }
uint64_t madeira_get_present_count(void) { return 0; }
int madeira_get_vsync_locked(void) { return 0; }
void madeira_set_vsync_locked(int locked) { (void)locked; }
double madeira_gpu_meter_busy_seconds(void) { return 0; }
uint64_t madeira_gpu_meter_cmdbufs(void) { return 0; }
void madeira_gpu_meter_enable(int on) { (void)on; }
void madeira_set_diag_enabled(int on) { (void)on; }
void madeira_set_display_max_fps(int panel_hz, int intent_hz) { (void)panel_hz; (void)intent_hz; }
void madeira_set_fence_mode(int mode) { (void)mode; }

// Wine's iOS display driver (winios.drv): no Windows desktop runs here.
int winios_drv_census_owner(void *hwnd, unsigned int *pid, unsigned int *style) { (void)hwnd; (void)pid; (void)style; return 0; }
int winios_drv_foreground_if_owner(void *hwnd) { (void)hwnd; return 0; }
void winios_drv_post_key(unsigned short vk, unsigned int flags) { (void)vk; (void)flags; }
void winios_drv_post_text(unsigned int scalar, unsigned short vk, int shift) { (void)scalar; (void)vk; (void)shift; }
void winios_drv_post_mouse(int x, int y, unsigned int flags, unsigned int mouse_data, void *hwnd) {
    (void)x; (void)y; (void)flags; (void)mouse_data; (void)hwnd;
}
int winios_drv_post_restore(void *hwnd) { (void)hwnd; return 0; }
int winios_drv_process_image(unsigned int pid, char *out, unsigned int size) { (void)pid; if (out && size) out[0] = 0; return 0; }
void winios_dump_window_tree(void) {}

// liblzma (Steam depot chunks): downloads fail in the shell.
int lzma_alone_decoder(void *strm, uint64_t memlimit) { (void)strm; (void)memlimit; return 11; /* LZMA_PROG_ERROR */ }
int lzma_code(void *strm, int action) { (void)strm; (void)action; return 11; }
void lzma_end(void *strm) { (void)strm; }
