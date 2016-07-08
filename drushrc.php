<?php

/**
 * Command argument complete callback.
 */
function features_features_export_complete() {
  return features_complete_features();
}

/**
 * Command argument complete callback.
 */
function features_features_update_complete() {
  return features_complete_features();
}

/**
 * Command argument complete callback.
 */
function features_features_update_all_complete() {
  return features_complete_features();
}

/**
 * Command argument complete callback.
 */
function features_features_revert_complete() {
  return features_complete_features();
}

/**
 * Command argument complete callback.
 */
function features_features_revert_all_complete() {
  return features_complete_features();
}

/**
 * Command argument complete callback.
 */
function features_features_diff_complete() {
  return features_complete_features();
}

/**
 * List features for completion.
 *
 * @return
 *  Array of available features.
 */
function features_complete_features() {
  if (drush_bootstrap_max(DRUSH_BOOTSTRAP_DRUPAL_FULL)) {
    return array('values' => array_keys(features_get_features(NULL, TRUE)));
  }
}
