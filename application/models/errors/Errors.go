// Package errors defines the domain errors used in the application.
package errors

import (
	"errors"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
)

// AppError defines an application (domain) error
type AppError struct {
	Err    error
	Type   string
	Logger *logger.Logger
}

// NewAppError initializes a new domain error using an error and its type.
func NewAppError(logger *logger.Logger, err error, errType string) *AppError {
	return &AppError{
		Err:    err,
		Type:   errType,
		Logger: logger,
	}
}

// NewAppErrorWithType initializes a new default error for a given type.
func NewAppErrorWithType(logger *logger.Logger, errType string) *AppError {
	// Add controller error logging here
	// logger.Error(err) // log the exact error

	var err error

	switch errType {
	case NotFound:
		err = errors.New(notFoundMessage)
	case ValidationError:
		err = errors.New(validationErrorMessage)
	case ResourceAlreadyExists:
		err = errors.New(alreadyExistsErrorMessage)
	case RepositoryError:
		err = errors.New(repositoryErrorMessage)
	case NotAuthenticated:
		err = errors.New(notAuthenticatedErrorMessage)
	case NotAuthorized:
		err = errors.New(notAuthorizedErrorMessage)
	case TokenGeneratorError:
		err = errors.New(tokenGeneratorErrorMessage)
	case ExternalServiceError:
		err = errors.New(ExternalServiceErrorMessage)
	default:
		err = errors.New(unknownErrorMessage)
	}

	return &AppError{
		Err:    err,
		Type:   errType,
		Logger: logger,
	}
}

// String converts the app error to a human-readable string.
func (appErr *AppError) Error() string {
	// Add controller error logging here
	if appErr.Logger != nil {
		appErr.Logger.Error(appErr.Err)
	}

	return appErr.Err.Error()
}
