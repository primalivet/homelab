package health

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	"github.com/jackc/pgx/v5"
	"github.com/primalivet/homelab/services/user/internal/db"
)

type Controller struct {
	ctx context.Context
	conn *pgx.Conn
	queries *db.Queries
}

func NewController(ctx context.Context, conn *pgx.Conn) *Controller {
	return &Controller{
		ctx: ctx,
		conn: conn,
		queries: db.New(conn),
	}
}

func (c *Controller) Check(w http.ResponseWriter, r *http.Request) {
	err := c.conn.Ping(c.ctx) // TODO: replace with Request context?
	if err != nil {
		log.Printf("Database connection error: %v", err)
		http.Error(w, "Database connection error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{ "status": "ok" })
}

