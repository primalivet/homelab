package health

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5"
)

func RegisterRoutes(ctx context.Context, mux *http.ServeMux, conn *pgx.Conn) {
	c := NewController(ctx, conn)
	mux.HandleFunc("GET /health", c.Check)
}
