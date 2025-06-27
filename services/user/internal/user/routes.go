package user

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/jackc/pgx/v5"
	"github.com/primalivet/homelab/services/user/internal/auth"
)

func RegisterRoutes(ctx context.Context, logger *slog.Logger, mux *http.ServeMux, conn *pgx.Conn, authMiddleware *auth.Middleware) {
	s := NewService(ctx, conn)
	c := NewController(logger, s)

	mux.Handle("GET /users/me", authMiddleware.Guard(http.HandlerFunc(c.Me)))
	mux.HandleFunc("GET /users", c.ByPage)
	mux.HandleFunc("GET /users/{id}", c.ByID)
}
