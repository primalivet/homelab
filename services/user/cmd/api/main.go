package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/primalivet/homelab/services/user/internal/auth"
	"github.com/primalivet/homelab/services/user/internal/health"
	"github.com/primalivet/homelab/services/user/internal/user"
)

func run(ctx context.Context, getenv func(string) string) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelDebug,
		AddSource: true,
	}))

	dbURL := getenv("POSTGRES_URL")
	if dbURL == "" {
		dbURL = "postgres://service_user:postgres@localhost:5432/service_user?sslmode=disable"
	}

	port := getenv("PORT")
	if port == "" {
		port = "8080"
	}

	ctx, cancel := signal.NotifyContext(ctx, os.Interrupt)
	defer cancel()

	conn, err := pgx.Connect(ctx, dbURL)
	if err != nil {
		logger.Error("connecting to database failed", "error", err)
		os.Exit(1)
	}

	defer conn.Close(ctx)

	mux := http.NewServeMux()
	jwtSecret :=  "TODO_JWT_SECRET"
	authMiddleware := auth.NewMiddleware(jwtSecret)

	health.RegisterRoutes(ctx, logger, mux, conn)
	auth.RegisterRoutes(ctx, logger, mux, conn, jwtSecret)
	user.RegisterRoutes(ctx, logger, mux, conn, authMiddleware)

	server := &http.Server{
		Addr:    ":" + port,
		Handler: mux,
	}

	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("error listening and serving", "error", err)
		}
		logger.Info("listening and serving", "port", port)
	}()

	<-ctx.Done()

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		logger.Error("error shutting down server", "error", err)
	}

}

func main() {
	run(context.Background(), func(key string) string {
		return os.Getenv(key)
	})
}
