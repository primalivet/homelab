-- name: ListUsers :many
SELECT * FROM "user" LIMIT $1 OFFSET $2;

-- name: FindUserById :one
SELECT * FROM "user" WHERE id = $1;

-- name: FindUserByEmail :one
SELECT * FROM "user" WHERE email = $1;

-- name: CreateUser :one
INSERT INTO "user" (email, password_hash) VALUES($1, $2) RETURNING *;

-- name: UpdateUser :one
UPDATE "user" SET email = $1, password_hash = $2 WHERE id = $3 RETURNING *;

-- name: DeleteUser :exec
DELETE FROM "user" WHERE id = $1;
