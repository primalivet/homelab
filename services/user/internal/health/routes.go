package health

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/jackc/pgx/v5"
)

func RegisterRoutes(ctx context.Context, logger *slog.Logger, mux *http.ServeMux, conn *pgx.Conn) {
	c := NewController(ctx, logger, conn)
	mux.HandleFunc("GET /health", c.Check)
}
