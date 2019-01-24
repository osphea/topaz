#!/boot/bin/sh
# Copyright 2018 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -o errexit

# In the event of previous failures from other scripts or other components using
# the GPU, ensure that all components using the display have been shut down.
killall basemgr* || true
killall root_presenter* || true
killall scenic* || true

# TODO(bgoldman): Create a separate test instead of driver_example_mod_target_tests
run_test \
  fuchsia-pkg://fuchsia.com/basemgr#meta/basemgr.cmx --test --enable_presenter \
  --account_provider=fuchsia-pkg://fuchsia.com/dev_token_manager#meta/dev_token_manager.cmx \
  --base_shell=fuchsia-pkg://fuchsia.com/dev_base_shell#meta/dev_base_shell.cmx \
  --base_shell_args=--test_timeout_ms=3600000 \
  --session_shell=fuchsia-pkg://fuchsia.com/dev_session_shell#meta/dev_session_shell.cmx \
  --session_shell_args=--root_module=fuchsia-pkg://fuchsia.com/test_driver_module#meta/test_driver_module.cmx,--module_under_test_url=fuchsia-pkg://fuchsia.com/driver_example_mod_wrapper#meta/driver_example_mod_wrapper.cmx,--test_driver_url=fuchsia-pkg://fuchsia.com/driver_example_mod_target_tests#meta/driver_example_mod_target_tests.cmx \
  --story_shell=fuchsia-pkg://fuchsia.com/dev_story_shell#meta/dev_story_shell.cmx
