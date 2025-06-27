package auth

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5"
)

func RegisterRoutes(ctx context.Context, mux *http.ServeMux, conn *pgx.Conn, jwtSecret string) {
	s := NewService(ctx, conn, jwtSecret)
	c := NewController(s)

	mux.HandleFunc("POST /auth/register", c.Register)
	mux.HandleFunc("POST /auth/login", c.Login)
	mux.HandleFunc("GET /auth/logout", c.Logout)
}
