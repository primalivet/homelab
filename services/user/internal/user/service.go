package user

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/primalivet/homelab/services/user/internal/db"
)

type Service struct {
	ctx     context.Context
	conn    *pgx.Conn
	queries *db.Queries
}

func NewService(ctx context.Context, conn *pgx.Conn) *Service {
	return &Service{
		ctx:     ctx,
		queries: db.New(conn),
	}
}

func (s *Service) List(limit, offset int32) ([]db.User, error) {
	return s.queries.ListUsers(s.ctx, db.ListUsersParams{Limit: limit, Offset: offset})
}

func (s *Service) ById(id int32) (db.User, error) {
	return s.queries.FindUserById(s.ctx, id)
}
