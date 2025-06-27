package auth

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/primalivet/homelab/services/user/internal/db"
	"golang.org/x/crypto/bcrypt"
)

type Service struct {
	ctx context.Context
	conn *pgx.Conn
	queries *db.Queries
	jwtSecret string
}

func NewService(ctx context.Context, conn *pgx.Conn, jwtSecret string) *Service {
	return &Service{
		ctx: ctx,
		queries: db.New(conn),
		jwtSecret: jwtSecret,
	}
}

func (s *Service) Login(email, password string) (*db.User, error) {
	user, err := s.queries.FindUserByEmail(s.ctx, email)
	if err != nil {
		return nil, fmt.Errorf("finding user with email %s failed: %w", email, err)
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		return nil, fmt.Errorf("comparing hash and password failed: %w", err)
	}

	return &user, nil
}

func  (s *Service) Register(email, password string) (*db.User, error) {
	passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("generating password failed: %w", err)
	}

	user, err := s.queries.CreateUser(s.ctx, db.CreateUserParams{
		Email: email,
		PasswordHash: string(passwordHash),
	})
	if err != nil {
		return nil, fmt.Errorf("creating user with email %s failed: %w", email, err)
	}

	return &user, nil
}

