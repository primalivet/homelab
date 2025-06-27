package user

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/primalivet/homelab/services/user/internal/auth"
)

type Controller struct {
	service *Service
}

func NewController(service *Service) *Controller {
	return &Controller{ service: service }
}

func (c *Controller) Me(w http.ResponseWriter, r *http.Request) {
	claims := r.Context().Value("user_claims").(*auth.UserClaims)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"id": string(claims.ID),
		"email": claims.Email,
	})
}

func (c *Controller) ByPage(w http.ResponseWriter, r *http.Request) {
	page, err := strconv.ParseInt(r.URL.Query().Get("page"), 10, 32)
	if err != nil { 
		page = 1
	}
	perPage, err := strconv.ParseInt(r.URL.Query().Get("per_page"), 10, 32)
	if err != nil {
		perPage = 10
	}

	if page <= 0 {
		log.Printf("Invalid page number: %d", page)
		http.Error(w, "Invalid page number", http.StatusBadRequest)
		return
	}

	if perPage <= 0 || perPage > 100 {
		log.Printf("Invalid per_page value: %d", perPage)
		http.Error(w, "Invalid per_page value", http.StatusBadRequest)
		return
	}

	offset := int32((page - 1) * perPage)
	limit := int32(perPage)

	users, err := c.service.List(limit, offset)
	if err != nil {
		log.Printf("Error listing users: %v", err)
		http.Error(w, "Error listing users", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(ToUsersResponse(users)); err != nil {
		log.Printf("Error encoding users: %v", err)
		http.Error(w, "Error encoding users", http.StatusInternalServerError)
		return
	}
}

func (c *Controller) ByID(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(r.PathValue("id"), 10, 32)
	if err != nil {
		log.Printf("Invalid user ID: %v", err)
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	user, err := c.service.ById(int32(id)) 

	if err != nil {
		log.Printf("Error fetching user by ID %d: %v", id, err)
		http.Error(w, "Error fetching user", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(ToUserResponse(user)); err != nil {
		http.Error(w, "Error encoding user", http.StatusInternalServerError)
	}
}

