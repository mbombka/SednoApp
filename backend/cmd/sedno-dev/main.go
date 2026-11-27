// sedno-dev runs the Go API against a local, disposable Firestore emulator.
package main

import (
	"context"
	"encoding/base64"
	"errors"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/mbombka/SednoApp/backend/internal/httpapi"
	"github.com/mbombka/SednoApp/backend/internal/simplification"
	"github.com/mbombka/SednoApp/backend/internal/store"
)

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	if os.Getenv("ASPNETCORE_ENVIRONMENT") != "Development" || os.Getenv("K_SERVICE") != "" || os.Getenv("CLOUD_RUN_JOB") != "" ||
		os.Getenv("Firestore__UseEmulator") != "true" || os.Getenv("PlayIntegrity__Provider") != "mock" {
		return errors.New("local Development with an explicit Firestore emulator and mock Play Integrity is required")
	}
	host, port, err := net.SplitHostPort(os.Getenv("FIRESTORE_EMULATOR_HOST"))
	ip := net.ParseIP(host)
	if err != nil || ip == nil || !ip.IsLoopback() || !validPort(port) {
		return errors.New("FIRESTORE_EMULATOR_HOST must be a numeric loopback address and port")
	}
	project := os.Getenv("Firestore__ProjectId")
	if !regexp.MustCompile(`^demo-[a-z0-9-]+$`).MatchString(project) {
		return errors.New("Firestore__ProjectId must be a demo project")
	}
	if len(os.Args) > 2 || len(os.Args) == 2 && os.Args[1] != "--cleanup" {
		return errors.New("expected no arguments or --cleanup")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	db, err := firestore.NewClient(ctx, project)
	if err != nil {
		return errors.New("could not initialize local Firestore client")
	}
	defer db.Close()
	firestoreStore := &store.Store{DB: db, Now: time.Now}
	if len(os.Args) == 2 {
		cleanupCtx, stop := context.WithTimeout(context.Background(), 60*time.Second)
		defer stop()
		return firestoreStore.Cleanup(cleanupCtx, nil)
	}
	credentialKey, err := key("Security__CredentialKey")
	if err != nil {
		return err
	}
	fingerprintKey, err := key("Security__FingerprintKey")
	if err != nil {
		return err
	}
	runModel := mockModel
	switch os.Getenv("Model__Provider") {
	case "mock":
	case "openai":
		model, err := simplification.NewModel(os.Getenv("OpenAI__ApiKey"), nil)
		if err != nil {
			return err
		}
		runModel = model.Run
	default:
		return errors.New("Model__Provider must be explicitly set to mock or openai")
	}
	port = os.Getenv("PORT")
	if port == "" {
		port = "5000"
	}
	if !validPort(port) {
		return errors.New("PORT must be numeric and between 1 and 65535")
	}
	api := &httpapi.API{
		Store:          firestoreStore,
		CredentialKey:  credentialKey,
		FingerprintKey: fingerprintKey,
		RunModel:       runModel,
	}
	server := &http.Server{
		Addr:              net.JoinHostPort("127.0.0.1", port),
		Handler:           api.Handler(),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       12 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       30 * time.Second,
		ErrorLog:          log.New(io.Discard, "", 0),
	}
	if err := server.ListenAndServe(); err != nil {
		return errors.New("local HTTP server stopped")
	}
	return nil
}

func validPort(value string) bool {
	port, err := strconv.ParseUint(value, 10, 16)
	return err == nil && port > 0
}

func key(name string) ([]byte, error) {
	decoded, err := base64.StdEncoding.DecodeString(os.Getenv(name))
	if err != nil || len(decoded) < 32 {
		return nil, errors.New(name + " must be base64 with at least 32 bytes")
	}
	return decoded, nil
}

func mockModel(_ context.Context, input simplification.Input) (string, error) {
	prefix := "Demo simplification: "
	if input.Mode == "correct" {
		prefix = "Demo correction: "
	}
	if input.Language == "pl" {
		prefix = "Wersja demonstracyjna: "
		if input.Mode == "correct" {
			prefix = "Demonstracja poprawiania: "
		}
	}
	return prefix + strings.TrimSpace(input.Text), nil
}
