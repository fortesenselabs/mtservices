// Package errors defines the domain errors used in the application.
package errors

const (
	// NotFound error indicates a missing / not found record
	NotFound        = "NotFound"
	notFoundMessage = "record not found"

	// ValidationError indicates an error in input validation
	ValidationError        = "ValidationError"
	validationErrorMessage = "validation error"

	// ResourceAlreadyExists indicates a duplicate / already existing record
	ResourceAlreadyExists     = "ResourceAlreadyExists"
	alreadyExistsErrorMessage = "resource already exists"

	// RepositoryError indicates a repository (e.g database) error
	RepositoryError        = "RepositoryError"
	repositoryErrorMessage = "error in repository operation"

	// NotAuthenticated indicates an authentication error
	NotAuthenticated             = "NotAuthenticated"
	notAuthenticatedErrorMessage = "not Authenticated"

	// TokenGeneratorError indicates an token generation error
	TokenGeneratorError        = "TokenGeneratorError"
	tokenGeneratorErrorMessage = "error in token generation"

	// TokenValidationError indicates an token validation error
	// TokenValidationError        = "TokenValidationError"
	// tokenValidationErrorMessage = "error in token validation"

	// NotAuthorized indicates an authorization error
	NotAuthorized             = "NotAuthorized"
	notAuthorizedErrorMessage = "not authorized"

	// UnknownError indicates an error that the app cannot find the cause for
	UnknownError        = "UnknownError"
	unknownErrorMessage = "something went wrong"

	// ExternalServiceError indicates an external api service error
	ExternalServiceError        = "ExternalServiceError"
	ExternalServiceErrorMessage = "something went wrong while communicating with the external service"

	// InvalidURLError indicates an invalid URL error
	InvalidURLError        = "InvalidURLError"
	invalidURLErrorMessage = "invalid URL"
)