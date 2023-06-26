package logger

import (
	"context"
	"log"

	"cloud.google.com/go/logging"
)

var (
	logger *logging.Logger
)

func InitLog(projectID, logName string) {
	loggingClient, err := logging.NewClient(context.Background(), projectID)
	if err != nil {
		log.Fatalf("Failed to create logging client: %v", err)
	}

	logger = loggingClient.Logger(logName)
}

func detectLoggingMechanism() string {
	// Check if running on Google Cloud Platform
	// if os.Getenv("GOOGLE_APPLICATION_CREDENTIALS") != "" {
	// 	return "gcp" // Use Google Cloud Logging
	// }

	// Check if running on a specific environment or platform
	// Add detection logic here based on application's environment

	// Default to using standard log package
	return "standard"
}

// Info logs an informational message
func Info(message string) {
	if detectLoggingMechanism() == "gcp" {
		entry := logging.Entry{
			Payload:  message,
			Severity: logging.Info,
		}
		logger.Log(entry)
	} else {
		log.Println("[INFO]", message)
	}
}

// Error logs an error message
func Error(err error) {
	if detectLoggingMechanism() == "gcp" {
		entry := logging.Entry{
			Payload:  err.Error(),
			Severity: logging.Error,
		}
		logger.Log(entry)
	} else {
		log.Println("[ERROR]", err)
	}
}

// Fatal logs a fatal error message and exits the program
func Fatal(err error) {
	if detectLoggingMechanism() == "gcp" {
		entry := logging.Entry{
			Payload:  err.Error(),
			Severity: logging.Critical,
		}
		logger.Log(entry)
		log.Fatalln(err)
	} else {
		log.Fatalln("[FATAL]", err)
	}
}
