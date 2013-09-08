<?php
/**
 * @file
 * Contains some hooks that are used during installation.
 */

/**
 * Implements hook_form_FORM_ID_alter().
 *
 * Allows the profile to alter the site configuration form.
 */
function hr_tools_form_install_configure_form_alter(&$form, $form_state) {
  // Pre-populate some fields.
  $form['site_information']['site_name']['#default_value'] = t('HR Tools');
  $form['site_information']['site_mail']['#default_value'] = 'gerrit@hedgecomm.be';

  $form['admin_account']['account']['name']['#default_value'] = 'admin';
  $form['admin_account']['account']['mail']['#default_value'] = 'gerrit@hedgecomm.be';

  $form['server_settings']['site_default_country']['#default_value'] = 'BE';

  $form['update_notifications']['update_status_module']['#default_value'] = array(1);

  // Private file directory
  $form['file_system'] = array(
    '#type' => 'fieldset',
    '#collapsible' => FALSE,
    '#title' => t('File system'),
  );
  $form['file_system']['file_private_path'] = array(
    '#type' => 'textfield',
    '#title' => t('Private file system path'),
    '#default_value' => variable_get('file_private_path', 'sites/default/files/private'),
    '#maxlength' => 255,
    '#description' => t('An existing local file system path for storing private files which is needed by the resume feature and during the import of demo data. It should be writable by Drupal and not accessible over the web. Note that non-Apache web servers may need additional configuration to secure private file directories. See the online handbook for <a href="@handbook">more information about securing private files</a>.', array('@handbook' => 'http://drupal.org/documentation/modules/file')),
    '#after_build' => array('system_check_directory'),
    '#required' => TRUE,
  );

  $form['#submit'][] = 'hr_tools_install_configure_form_submit';
}

/**
 * Submit callback.
 */
function hr_tools_install_configure_form_submit(&$form, &$form_state) {

  // Set the private files directory variable.
  variable_set('file_private_path', $form_state['values']['file_private_path']);
}

/**
 * Implements hook_install_tasks().
 */
function hr_tools_install_tasks($install_state) {
  $tasks = array(
    'hr_tools_install_additional_modules' => array(
      'display_name' => st('Install additional modules'),
      'type' => 'batch',
    ),
    'hr_tools_enable_theme' => array(
      'display_name' => st('Enable default themes'),
    ),
    'hr_tools_import_vocabularies_batch' => array(
      'display_name' => st('Import terms'),
      'type' => 'batch',
    ),
  );
  return $tasks;
}

/**
 * Task callback for installing additional modules
 */
function hr_tools_install_additional_modules() {

  $modules = array(

    // Install default core modules.
    'contextual',
    'dashboard',
    'dblog',
    'shortcut',
    'overlay',
    'field_ui',

    // Install default contrib modules.
    'admin_menu_toolbar',
    'rules_admin',
    'views_ui',
    'taxonomy_manager',
    'colorbox',
    'context_ui',
    'pathauto',
    'facetapi_pretty_paths',
    'colorbox',
    'context_ui',
    'rules_admin',
    'views_ui',
    'semanticviews',
    'ckeditor',
    'ckeditor_link',
    'imce',
    'block_class',
    'migrate',
    'migrate_extras',
    'profile2_page',    
    
    // HR Tools Features
    'hr_tools_vocabularies',
    'hr_tools_search_database_server',
    'hr_tools_job',
    'hr_tools_job_application',
    'hr_tools_job_search',
    'hr_tools_content_authoring',
    'hr_tools_demo',
    'hr_tools_menus',
    'hr_tools_frontpage',
    'hr_tools_register',
    'hr_tools_resume',
    'hr_tools_resume_search',
    // Search Solr Server: will not be enabled by default
    // 'hr_tools_search_solr_server'
  );

  // Resolve the dependencies now, so that module_enable() doesn't need
  // to do it later for each individual module (which kills performance).
  $files = system_rebuild_module_data();
  $modules_sorted = array();
  foreach ($modules as $module) {
    if ($files[$module]->requires) {
      // Create a list of dependencies that haven't been installed yet.
      $dependencies = array_keys($files[$module]->requires);
      $dependencies = array_filter($dependencies, '_hr_tools_filter_dependencies');
      // Add them to the module list.
      $modules = array_merge($modules, $dependencies);
    }
  }
  $modules = array_unique($modules);
  foreach ($modules as $module) {
    $modules_sorted[$module] = $files[$module]->sort;
  }
  arsort($modules_sorted);

  $operations = array();
  // Enable the selected modules.
  foreach ($modules_sorted as $module => $weight) {
    $operations[] = array('_hr_tools_enable_module', array($module, $files[$module]->info['name']));
  }

  $batch = array(
    'title' => t('Installing additional modules'),
    'operations' => $operations,
    'file' => drupal_get_path('profile', 'hr_tools') . '/hr_tools.install_callbacks.inc',
  );

  return $batch;

}

/**
 * array_filter() callback used to filter out already installed dependencies.
 */
function _hr_tools_filter_dependencies($dependency) {
  return !module_exists($dependency);
}


/**
 * Task callback for installing vocabularies
 */
function hr_tools_import_vocabularies_batch() {
  $batch = array(
    'title' => t('Importing taxonomy terms'),
    'operations' => array(
      array('hr_tools_import_vocabularies', array()),
    ),
    'finished' => 'hr_tools_import_vocabularies_finished',
    'title' => t('Import terms'),
    'init_message' => t('Starting import.'),
    'progress_message' => t('Processed @current out of @total.'),
    'error_message' => t('HR Tools vocabularies import batch has encountered an error.'),
    'file' => drupal_get_path('profile', 'hr_tools') . '/hr_tools.install_vocabularies.inc',
  );
  return $batch;
}


/**
 * Task callback for enabling theme.
 */
function hr_tools_enable_theme() {
  // Any themes without keys here will get numeric keys and so will be enabled,
  // but not placed into variables.
  $enable = array(
    'theme_default' => 'hearts',
    'admin_theme' => 'seven',
    //'zen'
  );
  theme_enable($enable);

  foreach ($enable as $var => $theme) {
    if (!is_numeric($var)) {
      variable_set($var, $theme);
    }
  }

  // Disable the default Bartik theme
  theme_disable(array('bartik'));
}