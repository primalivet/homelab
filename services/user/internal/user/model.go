package user

import "github.com/primalivet/homelab/services/user/internal/db"

type UserResponse struct {
	ID int32 `json:"id"`
	Email string `json:"email"`
	CreatedAt string `json:"createdAt"`
	UpdatedAt string `json:"updatedAt"`
}

func ToUserResponse(u db.User) *UserResponse {
	return &UserResponse{
		ID:    u.ID,
		Email: u.Email,
		CreatedAt: u.CreatedAt.Time.Format("2006-01-02 15:04:05"),
		UpdatedAt: u.UpdatedAt.Time.Format("2006-01-02 15:04:05"),
	}
}

func ToUsersResponse(us []db.User) []*UserResponse {
	response := make([]*UserResponse, len(us))
	for i, u := range us {
		response[i] = ToUserResponse(u)
	}
	return response
}
