package logger

import (
	"log"

	"cloud.google.com/go/logging"
)

// StandardLogger is a struct for the standard log package
type StandardLogger struct {
	logger *log.Logger
}

// Logger is a logging struct that supports different logging mechanisms
type Logger struct {
	client    *logging.Client
	gcpLogger *logging.Logger

	standardLogger *StandardLogger
}
