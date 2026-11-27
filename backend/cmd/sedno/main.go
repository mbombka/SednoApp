package main

import (
	"context"
	"encoding/base64"
	"errors"
	"io"
	"log"
	"log/slog"
	"net"
	"net/http"
	"net/mail"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/mbombka/SednoApp/backend/internal/googleapi"
	"github.com/mbombka/SednoApp/backend/internal/httpapi"
	"github.com/mbombka/SednoApp/backend/internal/keyring"
	"github.com/mbombka/SednoApp/backend/internal/simplification"
	"github.com/mbombka/SednoApp/backend/internal/store"
)

func main() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	env := setting("ASPNETCORE_ENVIRONMENT", "Production")
	development := env == "Development"
	cloudRun := os.Getenv("K_SERVICE") != ""
	job := os.Getenv("CLOUD_RUN_JOB") != ""
	if len(os.Args) == 3 && os.Args[1] == "--init-billing-keyring" {
		if !development || cloudRun || job {
			return errors.New("key ring initialization is Development-only")
		}
		return keyring.Initialize(os.Args[2])
	}
	cleanup := len(os.Args) == 2 && os.Args[1] == "--cleanup"
	if len(os.Args) != 1 && !cleanup {
		return errors.New("unsupported command")
	}
	if (cloudRun || job) && env != "Production" || job && !cleanup {
		return errors.New("Cloud Run requires Production and jobs require --cleanup")
	}
	emulator, err := boolSetting("Firestore__UseEmulator", false)
	if err != nil {
		return err
	}
	host := os.Getenv("FIRESTORE_EMULATOR_HOST")
	if !development && (emulator || host != "") {
		return errors.New("Firestore emulator is Development-only")
	}
	if emulator != (host != "") {
		return errors.New("Firestore__UseEmulator and FIRESTORE_EMULATOR_HOST must be configured together")
	}
	project := setting("Firestore__ProjectId", os.Getenv("Firebase__ProjectId"))
	if strings.TrimSpace(project) == "" {
		return errors.New("Firestore__ProjectId is required")
	}
	requireMigration, err := boolSetting("Firestore__RequireMigration", env == "Production")
	if err != nil {
		return err
	}
	serviceIdentity := setting("Google__CredentialProvider", "file")
	if serviceIdentity != "file" && serviceIdentity != "cloud-run" || serviceIdentity == "cloud-run" && !cloudRun && !job {
		return errors.New("invalid Google__CredentialProvider")
	}
	firebaseProject := os.Getenv("Firebase__ProjectId")
	if !development && !cleanup && strings.TrimSpace(firebaseProject) == "" {
		return errors.New("Firebase__ProjectId is required")
	}
	accountCache, err := identityConfiguration(serviceIdentity == "cloud-run", development, setting("Firebase__ProjectId", project))
	if err != nil {
		return err
	}
	db, err := firestore.NewClientWithDatabase(context.Background(), project, setting("Firestore__DatabaseId", "(default)"))
	if err != nil {
		return errors.New("could not initialize Firestore client")
	}
	defer db.Close()
	s := &store.Store{DB: db, Now: time.Now, RequireMigration: requireMigration}
	if cleanup {
		ctx, cancel := context.WithTimeout(context.Background(), time.Hour)
		defer cancel()
		var deleteIdentity func(context.Context, string) error
		if accountCache != nil {
			deleteIdentity = accountCache.Accounts.Delete
		}
		if err := s.Cleanup(ctx, deleteIdentity); err != nil {
			return errors.New("metadata cleanup failed")
		}
		return nil
	}
	api, err := configure(s, development, cloudRun, serviceIdentity == "cloud-run")
	if err != nil {
		return err
	}
	if firebaseProject != "" {
		api.VerifyIdentity = googleapi.FirebaseVerifier(firebaseProject).Firebase
	}
	if accountCache != nil {
		api.AccountAccess, api.FreshAccountAccess, api.DeleteIdentity = accountCache.Allowed, accountCache.Fresh, accountCache.Accounts.Delete
	}
	return serve(api)
}

func identityConfiguration(cloudRun, development bool, project string) (*googleapi.AccountCache, error) {
	path := os.Getenv("Firebase__DeletionServiceAccountJsonPath")
	if development && !cloudRun && path == "" {
		return nil, nil
	}
	client, err := googleapi.NewClient(cloudRun, path, googleapi.IdentityScope)
	if err != nil {
		return nil, errors.New("Firebase account credentials are unavailable")
	}
	return &googleapi.AccountCache{Accounts: googleapi.Accounts{Client: client, Project: project}}, nil
}

func configure(s *store.Store, development, cloudRun, serviceIdentity bool) (*httpapi.API, error) {
	api := &httpapi.API{Store: s, Development: development, CloudRun: cloudRun}
	var err error
	if api.CredentialKey, err = key("Security__CredentialKey"); err != nil {
		return nil, err
	}
	if api.FingerprintKey, err = key("Security__FingerprintKey"); err != nil {
		return nil, err
	}
	if api.PermitLimit, err = positive("RateLimiting__PermitLimit", 60, 1<<31-1); err != nil {
		return nil, err
	}
	if api.NotificationLimit, err = positive("RateLimiting__NotificationPermitLimit", 600, 1<<31-1); err != nil {
		return nil, err
	}

	switch setting("Model__Provider", "openai") {
	case "mock":
		if !development {
			return nil, errors.New("model mock is Development-only")
		}
		api.RunModel = mockModel
	case "disabled":
		api.RunModel = func(context.Context, simplification.Input) (string, error) { return "", simplification.ErrProvider }
	case "openai":
		for field, want := range map[string]string{"Model": "gpt-6-luna", "ServiceTier": "default", "ReasoningEffort": "none", "MaxOutputTokens": "4096", "TimeoutSeconds": "8"} {
			if setting("Model__OpenAI__"+field, want) != want {
				return nil, errors.New("invalid OpenAI model settings")
			}
		}
		model, err := simplification.NewModel(os.Getenv("OpenAI__ApiKey"), nil)
		if err != nil {
			return nil, err
		}
		api.RunModel = model.Run
	default:
		return nil, errors.New("invalid Model__Provider")
	}

	switch setting("PlayIntegrity__Provider", "google") {
	case "mock":
		if !development {
			return nil, errors.New("Play Integrity mock is Development-only")
		}
		api.VerifyIntegrity = func(context.Context, string, string) bool { return true }
	case "google":
		client, err := googleapi.NewClient(serviceIdentity, os.Getenv("PlayIntegrity__ServiceAccountJsonPath"), googleapi.IntegrityScope)
		if err != nil {
			return nil, errors.New("Play Integrity credentials are unavailable")
		}
		packageName := setting("PlayIntegrity__PackageName", "xyz.sedno.app")
		api.VerifyIntegrity = (googleapi.Integrity{Client: client, Package: packageName}).Verify
	default:
		return nil, errors.New("invalid PlayIntegrity__Provider")
	}

	enabled, err := boolSetting("Billing__Enabled", false)
	if err != nil {
		return nil, err
	}
	if enabled {
		readOnly, err := boolSetting("Billing__ReadOnlyKeyRing", false)
		if err != nil {
			return nil, err
		}
		if cloudRun && !readOnly {
			return nil, errors.New("Cloud Run billing requires a shared read-only key ring")
		}
		path := os.Getenv("Billing__DataProtectionKeyPath")
		audience := os.Getenv("Billing__NotificationAudience")
		email := os.Getenv("Billing__PushServiceAccountEmail")
		if strings.TrimSpace(path) == "" || strings.TrimSpace(audience) == "" || !validEmail(email) {
			return nil, errors.New("complete Google Play Billing configuration is required")
		}
		protection, err := keyring.Open(path)
		if err != nil {
			return nil, err
		}
		client, err := googleapi.NewClient(serviceIdentity, os.Getenv("Billing__ServiceAccountJsonPath"), googleapi.BillingScope)
		if err != nil {
			return nil, errors.New("Google Play Billing credentials are unavailable")
		}
		api.BillingPackage = setting("Billing__PackageName", "xyz.sedno.app")
		play := googleapi.Billing{
			Client: client, Package: api.BillingPackage, Product: setting("Billing__ProductId", "subscription_full"),
		}
		api.Billing = &store.Billing{Store: s, Protection: protection, Play: play}
		api.Packs = &store.Packs{Store: s, Play: play}
		verify := googleapi.PubSubVerifier(audience)
		api.VerifyNotification = func(ctx context.Context, token string) bool { return verify.PubSub(ctx, token, email) }
	}
	defaultEmail := "contact@sedno.xyz"
	if development {
		defaultEmail = ""
	}
	api.DeletionEmail = setting("Privacy__DeletionEmail", defaultEmail)
	if !development && !validEmail(api.DeletionEmail) {
		return nil, errors.New("Privacy__DeletionEmail is required")
	}
	path := setting("SEDNO_PRIVACY_PATH", "../docs/public/prywatnosc/index.html")
	privacy, err := os.ReadFile(path)
	if err != nil || len(privacy) == 0 {
		return nil, errors.New("privacy page is unavailable")
	}
	api.PrivacyHTML = string(privacy)
	return api, nil
}

func serve(api *httpapi.API) error {
	portDefault := 5000
	host := "127.0.0.1"
	portSetting := "PORT"
	if api.CloudRun {
		host, portDefault = "0.0.0.0", 8080
	} else if os.Getenv("PORT") == "" && os.Getenv("ASPNETCORE_HTTP_PORTS") != "" {
		host, portSetting = "0.0.0.0", "ASPNETCORE_HTTP_PORTS"
	}
	port, err := positive(portSetting, portDefault, 65535)
	if err != nil {
		return err
	}
	server := &http.Server{
		Addr: net.JoinHostPort(host, strconv.Itoa(port)), Handler: api.Handler(),
		ReadHeaderTimeout: 3 * time.Second, ReadTimeout: 15 * time.Second, WriteTimeout: 60 * time.Second,
		IdleTimeout: 60 * time.Second, MaxHeaderBytes: 32 << 10, ErrorLog: log.New(io.Discard, "", 0),
	}
	var cert, privateKey string
	if !api.CloudRun && !api.Development {
		cert, privateKey = os.Getenv("SEDNO_TLS_CERT"), os.Getenv("SEDNO_TLS_KEY")
		if cert == "" || privateKey == "" {
			return errors.New("TLS certificate and key are required outside Cloud Run")
		}
	}
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, os.Interrupt)
	defer stop()
	done := make(chan error, 1)
	go func() {
		if cert != "" {
			done <- server.ListenAndServeTLS(cert, privateKey)
		} else {
			done <- server.ListenAndServe()
		}
	}()
	select {
	case err := <-done:
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			return errors.New("HTTP server stopped")
		}
	case <-ctx.Done():
		shutdown, cancel := context.WithTimeout(context.Background(), 8*time.Second)
		defer cancel()
		if err := server.Shutdown(shutdown); err != nil {
			return errors.New("HTTP shutdown timed out")
		}
	}

	return nil
}

func setting(name, fallback string) string {
	if value, ok := os.LookupEnv(name); ok {
		return value
	}
	return fallback
}

func boolSetting(name string, fallback bool) (bool, error) {
	switch strings.ToLower(setting(name, strconv.FormatBool(fallback))) {
	case "true":
		return true, nil
	case "false":
		return false, nil
	default:
		return false, errors.New(name + " must be true or false")
	}
}

func positive(name string, fallback, max int) (int, error) {
	value, err := strconv.Atoi(setting(name, strconv.Itoa(fallback)))
	if err != nil || value < 1 || value > max {
		return 0, errors.New("invalid " + name)
	}
	return value, nil
}

func key(name string) ([]byte, error) {
	value, err := base64.StdEncoding.DecodeString(os.Getenv(name))
	if err != nil || len(value) < 32 {
		return nil, errors.New(name + " must be base64 with at least 32 bytes")
	}
	return value, nil
}

func validEmail(email string) bool {
	address, err := mail.ParseAddress(email)
	return err == nil && address.Address == email
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
