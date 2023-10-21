// Package config provides the database connection
package config

import (
	"fmt"
	// driver mysql on this implementation
	_ "github.com/go-sql-driver/mysql"
	"github.com/mitchellh/mapstructure"
)

func (infoDB *infoDatabaseSQL) getDiverConn(dbKeyName interface{}) (err error) {
	err = mapstructure.Decode(dbKeyName, infoDB)
	if err != nil {
		return
	}

	if infoDB.UseSocket {
		// dbURI := fmt.Sprintf("%s:%s@unix(%s)/%s?parseTime=true",
		// 	dbUser, dbPwd, unixSocketPath, dbName)
		infoDB.DriverConn = fmt.Sprintf("%s:%s@unix(%s)/%s?parseTime=true",
			infoDB.Username, infoDB.Password, infoDB.SocketPath, infoDB.Name)

		infoDB.DriverConn = fmt.Sprintf("%s:%s@unix(%s)/%s?parseTime=true",
			infoDB.Username, infoDB.Password, infoDB.SocketPath, infoDB.Name)
	} else {
		// "%s:%s@tcp(%s:%s)/%s?parseTime=true"
		infoDB.DriverConn = fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true",
			infoDB.Username, infoDB.Password, infoDB.Hostname, infoDB.Port, infoDB.Name)
		//
		infoDB.DriverConn = fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true",
			infoDB.Username, infoDB.Password, infoDB.Hostname, infoDB.Port, infoDB.Name)
	}

	return
}
