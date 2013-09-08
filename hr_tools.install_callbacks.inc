<?php
/**
 * @file
 * Contains Batch API callbacks used during installation.
 */

/**
 * BatchAPI callback.
 *
 * Enables a single module.
 *
 * @see hr_tools_install_additional_modules()
 */
function _hr_tools_enable_module($module, $module_name, &$context) {

  module_enable(array($module), FALSE);
  $context['message'] = st('Installed %module module.', array('%module' => $module_name));
}

/**
 * BatchAPI callback.
 *
 * Flushes all caches.
 *
 * @see hr_tools_cleanup()
 */
function _hr_tools_flush_caches($operation, &$context) {
  $context['message'] = t('@operation', array('@operation' => $operation));
  drupal_flush_all_caches();
}

/**
 * Batch API callback.
 *
 * Reverts all installed HR Tools features.
 *
 * @see hr_tools_cleanup()
 */
function _hr_tools_revert_all_features($operation, &$context) {
  $context['message'] = t('@operation', array('@operation' => $operation));
  features_revert();
}

/**
 * BatchAPI callback.
 *
 * Rolls back a migration.
 *
 * @see hr_tools_core_demo_rollback()
 */
function _hr_tools_rollback($operation, $type, &$context) {
  $context['message'] = t('@operation', array('@operation' => $type));
  $migration =  Migration::getInstance($operation);
  $migration->processRollback();
}


/**
 * Batch API finished callback.
 *
 * @see hr_tools_cleanup()
 */
function hr_tools_cleanup_finished($success, $results) {
  // Remove any lingering messages.
  // drupal_get_messages(NULL, TRUE);

  if ($success) {
    drupal_set_message(t('Post-install cleanup successful.'), 'status', FALSE);
  }
  else {
    drupal_set_message(t('Error perfoming post-install cleanup.'), 'error', FALSE);
  }
}