package auth

import "github.com/golang-jwt/jwt/v5"

type UserClaims struct {
	Email string `json:"email"`
	ID int32 `json:"id"`
	jwt.RegisteredClaims
}

type LoginRequest struct {
	Email string `json:"email"`
	Password string `json:"password"`
}

type RegisterRequest struct {
	Email string `json:"email"`
	Password string `json:"password"`
}
