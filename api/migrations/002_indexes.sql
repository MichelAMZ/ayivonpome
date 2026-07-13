CREATE INDEX idx_families_code ON families(code);
CREATE INDEX idx_people_family ON people(family_id, deleted_at);
CREATE INDEX idx_people_origin_family ON people(origin_family_id);
CREATE INDEX idx_people_name ON people(last_name, first_name);
CREATE INDEX idx_parent_child_parent ON parent_child_relations(parent_id);
CREATE INDEX idx_parent_child_child ON parent_child_relations(child_id);
CREATE UNIQUE INDEX uq_parent_child_active ON parent_child_relations(parent_id, child_id, parent_role, deleted_at);
CREATE INDEX idx_marriage_person_one ON marriage_relations(person_one_id);
CREATE INDEX idx_marriage_person_two ON marriage_relations(person_two_id);
CREATE INDEX idx_family_tree_links_person ON family_tree_links(person_id, enabled);
CREATE INDEX idx_access_codes_type ON access_codes(code_type, enabled, expires_at);
CREATE UNIQUE INDEX uq_api_sessions_token ON api_sessions(token_hash);
CREATE INDEX idx_notifications_status ON notifications(family_id, status, scheduled_date);
CREATE INDEX idx_bug_reports_status ON bug_reports(family_id, status, priority);
CREATE INDEX idx_audit_logs_family_created ON audit_logs(family_id, created_at);
CREATE UNIQUE INDEX uq_sync_operation ON sync_operations(operation_id);
CREATE INDEX idx_sync_family_status ON sync_operations(family_id, status);

