// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_RUNTIME_DART_UTILS_VMSERVICE_OBJECT_H_
#define TOPAZ_RUNTIME_DART_UTILS_VMSERVICE_OBJECT_H_

#include <lib/vfs/cpp/lazy_dir.h>

namespace dart_utils {

class VMServiceObject : public vfs::LazyDir {
 public:
  static constexpr const char* kDirName = "DartVM";
  static constexpr const char* kPortDirName = "vmservice-port";
  static constexpr const char* kPortDir = "/tmp/dart.services";

  void GetContents(LazyEntryVector* out_vector) const override;
  zx_status_t GetFile(Node** out_node,
                      uint64_t id, std::string name) const override;
};

}  // namespace dart_utils

#endif  // TOPAZ_RUNTIME_DART_UTILS_VMSERVICE_OBJECT_H_
