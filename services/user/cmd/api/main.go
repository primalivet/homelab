package main

import (
	"context"
	"log"
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
	dbURL := getenv("POSTGRES_URL")
	if dbURL == "" {
		dbURL = "postgres://service_user:postgres@localhost:5432/service_user?sslmode=disable"
	}

	port := getenv("PORT")
	if port == "" {
		log.Fatal("PORT environment variable is not set")
	}

	ctx, cancel := signal.NotifyContext(ctx, os.Interrupt)
	defer cancel()

	conn, err := pgx.Connect(ctx, dbURL)
	if err != nil {
		log.Fatal("Unable to connect to database:", err)
	}

	defer conn.Close(ctx)

	mux := http.NewServeMux()
	jwtSecret :=  "TODO_JWT_SECRET"
	authMiddleware := auth.NewMiddleware(jwtSecret)

	health.RegisterRoutes(ctx, mux, conn)
	auth.RegisterRoutes(ctx, mux, conn, jwtSecret)
	user.RegisterRoutes(ctx, mux, conn, authMiddleware)

	server := &http.Server{
		Addr:    ":" + port,
		Handler: mux,
	}

	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("error listening and serving: %s\n", err)
		}
		log.Printf("Server starting on port %s", port)
	}()

	<-ctx.Done()

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("Server shutdown: %v", err)
	}

}

func main() {
	run(context.Background(), func(key string) string {
		return os.Getenv(key)
	})
}
