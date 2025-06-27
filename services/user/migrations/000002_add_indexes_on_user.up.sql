BEGIN;

CREATE INDEX IF NOT EXISTS idx_user_email ON "user"(email);

COMMIT;
