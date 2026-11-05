/* Converts one sample DOCX to HWP with the rhwp engine (macOS static lib), then reopens it.
 * Build (engine repo rhwp_editor_mobile, branch iOS, after `cargo build --release` for aarch64-apple-darwin):
 *   clang -I<kit>/RhwpNative.xcframework/macos-arm64/Headers docx-to-hwp.c \
 *     <engine>/native-hwp/bindings/Native/target/aarch64-apple-darwin/release/librhwp_native_ffi.a \
 *     -framework CoreFoundation -framework Security -framework CoreText -framework CoreGraphics \
 *     -framework SystemConfiguration -liconv -lc++ -o docx-to-hwp
 * Run: ./docx-to-hwp BusinessReport.docx BusinessReport.hwp  (DOCX from make-sample-docx.py)
 * Output goes to HWPViewer/HWPViewer/Resources/SampleDocuments/ (seeded on first launch). */
#include <stdio.h>
#include <stdlib.h>
#include "rhwp_native_ffi.h"
int main(int argc, char **argv) {
  if (argc < 3) return 2;
  FILE *f = fopen(argv[1], "rb"); if (!f) return 3;
  fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
  unsigned char *buf = malloc(n); fread(buf, 1, n, f); fclose(f);
  char *err = NULL;
  RhwpDoc *doc = rhwp_doc_import_docx(buf, n, &err);
  if (!doc) { fprintf(stderr, "import failed: %s\n", err ? err : "?"); return 4; }
  printf("%s: %u pages\n", argv[1], rhwp_doc_page_count(doc));
  int64_t r = rhwp_doc_save_hwp_to_path(doc, argv[2]);
  printf("save -> %lld\n", (long long)r);
  RhwpDoc *back = rhwp_doc_open_path(argv[2], &err);
  if (!back) { fprintf(stderr, "reopen failed: %s\n", err ? err : "?"); return 5; }
  printf("reopen: %u pages\n", rhwp_doc_page_count(back));
  rhwp_doc_free(back); rhwp_doc_free(doc);
  return 0;
}
