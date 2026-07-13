INSERT INTO families (id, name, code, created_by, updated_by)
VALUES ('family-ayivon', 'Famille AYIVON', 'AYIVON', 'seed', 'seed')
ON DUPLICATE KEY UPDATE name = VALUES(name), code = VALUES(code);

-- Access codes must be inserted with password_hash() through api/scripts/seed_access_codes.php.
-- Never commit clear text code hashes generated from production secrets.

