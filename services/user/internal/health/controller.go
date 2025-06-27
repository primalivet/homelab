package health

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/jackc/pgx/v5"
	"github.com/primalivet/homelab/services/user/internal/db"
)

type Controller struct {
	ctx context.Context
	logger *slog.Logger
	conn *pgx.Conn
	queries *db.Queries
}

func NewController(ctx context.Context, logger *slog.Logger, conn *pgx.Conn) *Controller {
	return &Controller{
		ctx: ctx,
		logger: logger,
		conn: conn,
		queries: db.New(conn),
	}
}

func (c *Controller) Check(w http.ResponseWriter, r *http.Request) {
	err := c.conn.Ping(c.ctx) // TODO: replace with Request context?
	if err != nil {
		c.logger.Error("pinging database failed", "error", err)
		http.Error(w, "Database connection error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{ "status": "ok" })
}

