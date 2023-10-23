// Package errors contains the error handler controller
package errors

import (
	"net/http"

	errorsModel "github.com/FortesenseLabs/wisefinance-mtservices/application/models/errors"
	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	"github.com/gin-gonic/gin"
)

// MessagesResponse is a struct that contains the response body for the message
type MessagesResponse struct {
	Message string `json:"message"`
}

// Handler is Gin middleware to handle errors.
func Handler(logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Execute request handlers and then handle any errors
		c.Next()
		errs := c.Errors

		if len(errs) > 0 {
			err, ok := errs[0].Err.(*errorsModel.AppError)
			if ok {
				logger.Error(err.Err)

				resp := MessagesResponse{Message: err.Error()}
				switch err.Type {
				case errorsModel.NotFound:
					c.JSON(http.StatusNotFound, resp)
					return
				case errorsModel.ValidationError:
					c.JSON(http.StatusBadRequest, resp)
					return
				case errorsModel.TokenGeneratorError:
					c.JSON(http.StatusUnauthorized, resp)
					return
				case errorsModel.ResourceAlreadyExists:
					c.JSON(http.StatusConflict, resp)
					return
				case errorsModel.NotAuthenticated:
					c.JSON(http.StatusUnauthorized, resp)
					return
				case errorsModel.NotAuthorized:
					c.JSON(http.StatusForbidden, resp)
					return
				case errorsModel.ExternalServiceError:
					c.JSON(http.StatusServiceUnavailable, resp)
					return
				case errorsModel.RepositoryError:
					c.JSON(http.StatusInternalServerError, MessagesResponse{Message: "We are working to improve the flow of this request."})
					return
				default:
					c.JSON(http.StatusInternalServerError, MessagesResponse{Message: "We are working to improve the flow of this request."})
					return
				}
			}

			return
		}
	}

}
