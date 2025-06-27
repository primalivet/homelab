package auth

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/go-playground/validator/v10"
)

type Controller struct {
	logger *slog.Logger
	service *Service
}

func NewController(logger *slog.Logger, service *Service) *Controller {
	return &Controller{ logger: logger, service: service}
}

func (c *Controller) Register(w http.ResponseWriter, r *http.Request) {
	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		c.logger.Error("parsing request body failed", "error", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)	
		return
	}
	validate := validator.New()
	if err := validate.Struct(req); err != nil {
		c.logger.Error("validating request body failed", "body", req, "error", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	_, err := c.service.Register(req.Email, req.Password)
	if err != nil {
		c.logger.Error("registering user failed", "body", req, "error", err)
		http.Error(w, "Error registering user", http.StatusInternalServerError)
		return
	}
	w.Write([]byte("User registered successfully"))
}

func (c *Controller) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		c.logger.Error("parsing request body failed", "error", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
	}

	u, err := c.service.Login(req.Email, req.Password)
	if err != nil {
		c.logger.Error("logging in user failed", "body", req, "error", err)
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	token, err := GenerateJWT(u, c.service.jwtSecret)
	if err != nil {
		c.logger.Error("generating jwt token failed", "error", err)
		http.Error(w, "Error generating token", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Authorization", "Bearer "+token)
	w.Write([]byte("Login successful"))
	return
}

func (c *Controller) Logout(w http.ResponseWriter, r *http.Request) {
	// TODO: revoke token
	w.Write([]byte("Logout successful"))
}
