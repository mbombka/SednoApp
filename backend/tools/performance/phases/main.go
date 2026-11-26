package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"sync"
	"syscall"
	"time"
)

func mark(phase string) {
	fmt.Printf("sedno-phase %s %d\n", phase, time.Now().UnixMicro())
}

func main() {
	mark("entrypoint")
	if len(os.Args) != 2 {
		log.Fatal("choose sedno or go")
	}
	switch os.Args[1] {
	case "sedno":
		mark("dotnet_exec")
		log.Fatal(syscall.Exec("/usr/share/dotnet/dotnet", []string{"dotnet", "Sedno.Api.dll"}, os.Environ()))
	case "go":
		runServer()
	default:
		log.Fatal("unknown mode")
	}
}

func runServer() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	listener, err := net.Listen("tcp", "0.0.0.0:"+port)
	if err != nil {
		log.Fatal(err)
	}
	var firstProbe sync.Once
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health/live", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.RawQuery == "" {
			firstProbe.Do(func() { mark("probe_arrived") })
		}
		_, _ = fmt.Fprintln(w, "OK")
	})
	server := &http.Server{Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	mark("http_ready")
	log.Fatal(server.Serve(listener))
}
