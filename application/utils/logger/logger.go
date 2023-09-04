package logger

import (
	"context"
	"log"
	"os"

	"cloud.google.com/go/logging"
)

// NewLogger creates a new Logger instance and initializes the logging mechanism
func NewLogger(projectId string, logName string) (*Logger, error) {
	logger := &Logger{}

	err := logger.initLoggingClient(projectId)
	if err != nil {
		return nil, err
	}

	err = logger.initLogger(logName)
	if err != nil {
		return nil, err
	}

	return logger, nil
}

func (l *Logger) initLoggingClient(projectID string) error {
	loggingClient, err := logging.NewClient(context.Background(), projectID)
	if err != nil {
		return err
	}

	l.client = loggingClient
	return nil
}

func (l *Logger) initLogger(logName string) error {

	if l.detectLoggingMechanism() == "gcp" {
		l.gcpLogger = l.client.Logger(logName)
		l.standardLogger = nil
	} else {
		standardLogger := log.New(os.Stdout, "", log.Ldate|log.Ltime)
		l.standardLogger = &StandardLogger{logger: standardLogger}
		l.gcpLogger = nil
	}

	return nil
}

func (l *Logger) detectLoggingMechanism() string {
	// Check if running on Google Cloud Platform
	if os.Getenv("GAE_USE_LOGGING") != "" {
		return "gcp" // Use Google Cloud Logging
	}

	// Check if running on a specific environment or platform
	// Add detection logic here based on application's environment

	// Default to using standard log package
	return "standard"
}

func (l *Logger) Info(message string) {
	if l.gcpLogger != nil {
		entry := logging.Entry{
			Payload:  message,
			Severity: logging.Info,
		}
		l.gcpLogger.Log(entry)

		return
	}

	l.standardLogger.Info(message)
}

func (l *Logger) Error(err error) {
	if l.gcpLogger != nil {
		entry := logging.Entry{
			Payload:  err.Error(),
			Severity: logging.Error,
		}
		l.gcpLogger.Log(entry)

		return
	}

	l.standardLogger.Error(err)
}

func (l *Logger) Fatal(err error) {
	if l.gcpLogger != nil {
		entry := logging.Entry{
			Payload:  err.Error(),
			Severity: logging.Critical,
		}
		l.gcpLogger.Log(entry)
		log.Fatalln(err)

		return
	}

	l.standardLogger.Fatal(err)
}

// Info logs an informational message using the standard log package
func (sl *StandardLogger) Info(message string) {
	sl.logger.Println("[INFO]", message)
}

// Error logs an error message using the standard log package
func (sl *StandardLogger) Error(err error) {
	sl.logger.Println("[ERROR]", err)
}

// Fatal logs a fatal error message using the standard log package and exits the program
func (sl *StandardLogger) Fatal(err error) {
	sl.logger.Fatalln("[FATAL]", err)
}
