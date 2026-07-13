SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS families (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  code VARCHAR(80) NOT NULL,
  parent_family_id VARCHAR(36) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_families_parent FOREIGN KEY (parent_family_id) REFERENCES families(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS people (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  origin_family_id VARCHAR(36) NULL,
  first_name VARCHAR(120) NOT NULL,
  last_name VARCHAR(120) NOT NULL DEFAULT '',
  birth_last_name VARCHAR(120) NOT NULL DEFAULT '',
  gender ENUM('male','female','unknown') NOT NULL DEFAULT 'unknown',
  birth_date DATE NULL,
  birth_place VARCHAR(190) NOT NULL DEFAULT '',
  death_date DATE NULL,
  death_place VARCHAR(190) NOT NULL DEFAULT '',
  burial_place VARCHAR(190) NOT NULL DEFAULT '',
  current_address VARCHAR(255) NOT NULL DEFAULT '',
  current_city VARCHAR(120) NOT NULL DEFAULT '',
  current_region VARCHAR(120) NOT NULL DEFAULT '',
  current_country VARCHAR(120) NOT NULL DEFAULT '',
  latitude DECIMAL(10,7) NULL,
  longitude DECIMAL(10,7) NULL,
  email VARCHAR(190) NOT NULL DEFAULT '',
  phone_number VARCHAR(80) NOT NULL DEFAULT '',
  whatsapp_number VARCHAR(80) NOT NULL DEFAULT '',
  photo_url VARCHAR(255) NOT NULL DEFAULT '',
  notes TEXT NULL,
  privacy_json JSON NULL,
  linked_tree_enabled TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_people_family FOREIGN KEY (family_id) REFERENCES families(id),
  CONSTRAINT fk_people_origin_family FOREIGN KEY (origin_family_id) REFERENCES families(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS parent_child_relations (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  parent_id VARCHAR(36) NOT NULL,
  child_id VARCHAR(36) NOT NULL,
  parent_role ENUM('father','mother','parent') NOT NULL DEFAULT 'parent',
  relation_type ENUM('biological','adopted','customary','guardian','unknown') NOT NULL DEFAULT 'unknown',
  is_primary TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_parent_child_family FOREIGN KEY (family_id) REFERENCES families(id),
  CONSTRAINT fk_parent_child_parent FOREIGN KEY (parent_id) REFERENCES people(id),
  CONSTRAINT fk_parent_child_child FOREIGN KEY (child_id) REFERENCES people(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS marriage_relations (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  person_one_id VARCHAR(36) NOT NULL,
  person_two_id VARCHAR(36) NOT NULL,
  marriage_type VARCHAR(60) NOT NULL DEFAULT 'unknown',
  status ENUM('active','separated','divorced','widowed','unknown') NOT NULL DEFAULT 'unknown',
  marriage_date DATE NULL,
  marriage_place VARCHAR(190) NOT NULL DEFAULT '',
  divorce_date DATE NULL,
  end_date DATE NULL,
  order_index INT NOT NULL DEFAULT 0,
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_marriage_family FOREIGN KEY (family_id) REFERENCES families(id),
  CONSTRAINT fk_marriage_one FOREIGN KEY (person_one_id) REFERENCES people(id),
  CONSTRAINT fk_marriage_two FOREIGN KEY (person_two_id) REFERENCES people(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS family_tree_links (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  person_id VARCHAR(36) NOT NULL,
  source_family_id VARCHAR(36) NOT NULL,
  target_family_id VARCHAR(36) NOT NULL,
  target_family_name VARCHAR(190) NOT NULL DEFAULT '',
  relationship_type ENUM('originFamily','maternalBranch','paternalBranch','marriageBranch','linkedFamily','adoptionBranch','custom') NOT NULL DEFAULT 'linkedFamily',
  enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_tree_links_family FOREIGN KEY (family_id) REFERENCES families(id),
  CONSTRAINT fk_tree_links_person FOREIGN KEY (person_id) REFERENCES people(id),
  CONSTRAINT fk_tree_links_source FOREIGN KEY (source_family_id) REFERENCES families(id),
  CONSTRAINT fk_tree_links_target FOREIGN KEY (target_family_id) REFERENCES families(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS person_histories (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  person_id VARCHAR(36) NOT NULL,
  event_date DATE NULL,
  title VARCHAR(190) NOT NULL,
  description TEXT NULL,
  place VARCHAR(190) NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_person_histories_family FOREIGN KEY (family_id) REFERENCES families(id),
  CONSTRAINT fk_person_histories_person FOREIGN KEY (person_id) REFERENCES people(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS family_histories (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  title VARCHAR(190) NOT NULL,
  content MEDIUMTEXT NULL,
  max_characters INT NOT NULL DEFAULT 5000,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_family_histories_family FOREIGN KEY (family_id) REFERENCES families(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS family_council_members (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  person_id VARCHAR(36) NULL,
  first_name VARCHAR(120) NOT NULL DEFAULT '',
  last_name VARCHAR(120) NOT NULL DEFAULT '',
  role_title VARCHAR(120) NOT NULL DEFAULT '',
  residence_place VARCHAR(190) NOT NULL DEFAULT '',
  order_index INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_council_family FOREIGN KEY (family_id) REFERENCES families(id),
  CONSTRAINT fk_council_person FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS admins (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  full_name VARCHAR(190) NOT NULL,
  role ENUM('viewer','editor','admin','super_admin') NOT NULL DEFAULT 'viewer',
  email VARCHAR(190) NOT NULL DEFAULT '',
  phone_number VARCHAR(80) NOT NULL DEFAULT '',
  whatsapp_number VARCHAR(80) NOT NULL DEFAULT '',
  enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_admins_family FOREIGN KEY (family_id) REFERENCES families(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS access_codes (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  label VARCHAR(190) NOT NULL,
  code_hash VARCHAR(255) NOT NULL,
  code_type ENUM('family_access','admin_kpi','modification','linked_family','temporary','super_admin_recovery') NOT NULL,
  role ENUM('viewer','editor','admin','super_admin') NOT NULL DEFAULT 'viewer',
  enabled TINYINT(1) NOT NULL DEFAULT 1,
  expires_at DATETIME NULL,
  max_uses INT NULL,
  used_count INT NOT NULL DEFAULT 0,
  last_used_at DATETIME NULL,
  created_by VARCHAR(36) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  replaced_by_code_id VARCHAR(36) NULL,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_access_codes_family FOREIGN KEY (family_id) REFERENCES families(id),
  CONSTRAINT fk_access_codes_replaced FOREIGN KEY (replaced_by_code_id) REFERENCES access_codes(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS api_sessions (
  id VARCHAR(36) PRIMARY KEY,
  token_hash VARCHAR(128) NOT NULL,
  family_id VARCHAR(36) NOT NULL,
  role ENUM('viewer','editor','admin','super_admin') NOT NULL DEFAULT 'viewer',
  expires_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sessions_family FOREIGN KEY (family_id) REFERENCES families(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  person_id VARCHAR(36) NULL,
  type VARCHAR(80) NOT NULL,
  channel VARCHAR(80) NOT NULL DEFAULT 'local',
  title VARCHAR(190) NOT NULL,
  message TEXT NOT NULL,
  scheduled_date DATETIME NULL,
  status VARCHAR(40) NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_notifications_family FOREIGN KEY (family_id) REFERENCES families(id),
  CONSTRAINT fk_notifications_person FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bug_reports (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  reporter_name VARCHAR(190) NOT NULL DEFAULT '',
  title VARCHAR(190) NOT NULL,
  description TEXT NOT NULL,
  priority VARCHAR(40) NOT NULL DEFAULT 'normal',
  status VARCHAR(40) NOT NULL DEFAULT 'open',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_bug_reports_family FOREIGN KEY (family_id) REFERENCES families(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  action VARCHAR(120) NOT NULL,
  entity_type VARCHAR(80) NOT NULL DEFAULT '',
  entity_id VARCHAR(36) NOT NULL DEFAULT '',
  actor_id VARCHAR(36) NOT NULL DEFAULT '',
  payload_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_audit_logs_family FOREIGN KEY (family_id) REFERENCES families(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_operations (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  device_id VARCHAR(120) NOT NULL DEFAULT '',
  operation_id VARCHAR(120) NOT NULL,
  entity_type VARCHAR(80) NOT NULL,
  entity_id VARCHAR(36) NOT NULL,
  action VARCHAR(40) NOT NULL,
  base_version INT NOT NULL DEFAULT 0,
  payload_json JSON NULL,
  status VARCHAR(40) NOT NULL DEFAULT 'pending',
  error_message TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_sync_family FOREIGN KEY (family_id) REFERENCES families(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS app_settings (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  setting_key VARCHAR(120) NOT NULL,
  setting_value_json JSON NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  UNIQUE KEY uq_app_settings_key (family_id, setting_key, deleted_at),
  CONSTRAINT fk_app_settings_family FOREIGN KEY (family_id) REFERENCES families(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS backups (
  id VARCHAR(36) PRIMARY KEY,
  family_id VARCHAR(36) NOT NULL,
  file_path VARCHAR(255) NOT NULL,
  backup_type VARCHAR(40) NOT NULL DEFAULT 'json',
  notes TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by VARCHAR(36) NULL,
  updated_by VARCHAR(36) NULL,
  version INT NOT NULL DEFAULT 1,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_backups_family FOREIGN KEY (family_id) REFERENCES families(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
