package main

import (
	"os"
	"net/http"
	"log"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	db := os.Getenv("POSTGRES_DB")
	if db == "" {
		db = "MISSING 'HELLOWORLD' ENV VAR"
	}
	http.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("database name: " + db))
	})

	http.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("OK"))
	})

	log.Println("Starting server on port", port)
	if err := http.ListenAndServe(":" + port, nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}

}
