// Package utils contains the common functions and structures for the application
package utils

import (
	"fmt"
	"math/rand"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
)

// Get GCP Project ID
func GetGCPProjectID() string {
	//
	var GCPKeyName = map[string]string{
		"ProjectID": "Services.GCP.ProjectID",
	}

	viper.SetConfigFile("config.json")
	if err := viper.ReadInConfig(); err != nil {
		_ = fmt.Errorf("fatal error in config file: %s", err.Error())
	}

	projectID := viper.GetString(GCPKeyName["ProjectID"])
	return projectID
}

// Get Timezone
func GetTimezone() (*time.Location, error) {
	//
	var TimezoneKeyName = map[string]string{
		"Timezone": "Timezone",
	}

	viper.SetConfigFile("config.json")
	if err := viper.ReadInConfig(); err != nil {
		_ = fmt.Errorf("fatal error in config file: %s", err.Error())
	}

	tz := viper.GetString(TimezoneKeyName["Timezone"])
	return time.LoadLocation(tz)
}

// Parse params includes context keys, and route path  e.g /user/:userId
func ParseParams(ctx *gin.Context, paramName string, isRoute bool) string {
	val, _ := ctx.Keys[paramName].(string)
	if len(val) == 0 && isRoute {
		val = strings.TrimSpace(ctx.Param(paramName)) // Get the value of ":<val>" parameter from the URL path
	}

	return val
}

// Normalize Phone Number to any country's local format
func NormalizePhoneNumber(phoneNumber string, numberLength int) (string, error) {
	nigerianFormats := []string{"080", "081", "070", "090"}
	//
	// Replace the plus sign with zero
	normalizedNumber := strings.ReplaceAll(phoneNumber, "+", "0")

	// Remove the first three digits and replace them with a random value
	rand.NewSource(time.Now().UnixNano())
	replacement := nigerianFormats
	if len(normalizedNumber) > 3 {
		normalizedNumber = replacement[rand.Intn(len(replacement))] + normalizedNumber[3:]
	}

	// Check if the resulting string is N digits long
	if len(normalizedNumber) < numberLength {
		normalizedNumber = fmt.Sprintf("%-*s", numberLength, normalizedNumber)
	} else if len(normalizedNumber) > numberLength {
		normalizedNumber = normalizedNumber[:numberLength]
	}
	return normalizedNumber, nil
}

// delete a field from a map if exists
func DeleteMapFieldIfExists(m map[string]interface{}, field string) map[string]interface{} {
	_, exists := m[field]
	if exists {
		delete(m, field)
	}

	return m
}

// check if a map has any value
func MapHasValues(txFilter map[string]interface{}) bool {
	for _, value := range txFilter {
		if value != nil {
			return true
		}
	}
	return false
}

// get map values
func GetMapValues(m map[string]interface{}) []interface{} {
	values := make([]interface{}, 0, len(m))
	for _, value := range m {
		values = append(values, value)
	}
	return values
}

// extract non-empty keys/values from map
func ExtractNonEmptyMapKeys(filter map[string]interface{}) map[string]interface{} {
	tempMap := map[string]interface{}{}
	for key, value := range filter {
		if value != nil {
			fmt.Println(value)
			tempMap[key] = value
		}
	}
	return tempMap
}

// KoboToNGN converts a kobo amount to naira.
func KoboToNGN(kobo int) float64 {
	return float64(kobo) / 100
}

// NGNToKobo converts a naira amount to kobo.
func NGNToKobo(naira float64) int {
	return int(naira * 100)
}
