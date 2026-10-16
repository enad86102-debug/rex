package main

import (
	"context"
	"errors"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"rex/production/server/internal/api"
	"rex/production/server/internal/service"
)

func main() {
	if err := run(); err != nil {
		slog.Error("server stopped", "reason", err)
		os.Exit(1)
	}
}

func run() error {
	path := env("REX_STORE", "./data/state.json")
	if err := os.MkdirAll(filepath.Dir(path), 0700); err != nil {
		return err
	}
	// The snapshot adapter permits one writer process, including across restarts.
	// #nosec G304 -- REX_STORE is trusted operator configuration, not client input.
	lock, err := os.OpenFile(path+".lock", os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return err
	}
	defer lock.Close()
	if err = syscall.Flock(int(lock.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		return errors.New("store already locked by another process")
	}
	s, err := service.Open(path)
	if err != nil {
		return err
	}
	address := env("REX_LISTEN", "127.0.0.1:8080")
	cert, key := os.Getenv("REX_TLS_CERT"), os.Getenv("REX_TLS_KEY")
	host, _, err := net.SplitHostPort(address)
	if err != nil {
		return err
	}
	ip := net.ParseIP(host)
	if cert == "" || key == "" {
		if cert != "" || key != "" {
			return errors.New("both TLS certificate and key are required")
		}
		if (ip == nil || !ip.IsLoopback()) && os.Getenv("REX_BEHIND_TLS_PROXY") != "true" {
			return errors.New("non-loopback HTTP requires explicit REX_BEHIND_TLS_PROXY=true and an isolated TLS proxy")
		}
	}
	adminToken := os.Getenv("REX_ADMIN_TOKEN")
	if adminToken != "" && len(adminToken) < 32 {
		return errors.New("REX_ADMIN_TOKEN must contain at least 32 bytes")
	}
	server := &http.Server{Addr: address, Handler: api.New(s, api.Options{AdminToken: adminToken}), ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 10 * time.Second, WriteTimeout: 10 * time.Second, IdleTimeout: 60 * time.Second, MaxHeaderBytes: 8192}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	done := make(chan error, 1)
	go func() {
		if cert != "" {
			done <- server.ListenAndServeTLS(cert, key)
		} else {
			done <- server.ListenAndServe()
		}
	}()
	slog.Info("REX service listening", "address", address, "rules_enabled", false)
	select {
	case err := <-done:
		if errors.Is(err, http.ErrServerClosed) {
			return nil
		}
		return err
	case <-ctx.Done():
		shutdown, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		return server.Shutdown(shutdown)
	}
}

func env(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
