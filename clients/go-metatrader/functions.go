package metatrader

import (
	"encoding/json"
	"fmt"
	"net"
	"time"
)

type MTFunctions struct {
	HOST                     string
	PORT                     int
	debug                    bool
	instrumentConversionList []string
	authorizationCode        string
	connected                bool
	socket_error_message     string
	timeout_value            int
	sock                     net.Conn
}

func (mt *MTFunctions) IsConnected() bool {
	return mt.connected
}

func (mt *MTFunctions) _set_timeout(timeout_in_seconds int) {
	mt.timeout_value = timeout_in_seconds
	mt.sock.SetDeadline(time.Now().Add(time.Duration(mt.timeout_value) * time.Second))
	mt.sock.(*net.TCPConn).SetReadBuffer(0)
}

func (mt *MTFunctions) Disconnect() bool {
	mt.sock.Close()
	return true
}

func (mt *MTFunctions) Connect() bool {
	// Connect to the server
	// err := mt.sock.Dial((mt.HOST, mt.PORT))
	// err := mt.sock.("tcp", fmt.Sprintf("%s:%d", mt.HOST, mt.PORT))
	var err error

	mt.sock, err = net.Dial("tcp", fmt.Sprintf("%s:%d", mt.HOST, mt.PORT))
	if err != nil {
		fmt.Printf("Could not connect with the socket-server: %s\n terminating program", err)
		mt.connected = false
		mt.socket_error_message = "Could not connect to server."
		mt.sock.Close()
		return false
	}
	mt.sock.(*net.TCPConn).SetNoDelay(true)
	mt.sock.(*net.TCPConn).SetKeepAlive(true)
	mt.connected = true
	return true
}

func (mt *MTFunctions) sendRequest(data string) {
	mt.sock.Write([]byte(data))
}

func (mt *MTFunctions) recv(bufferSize int) []byte {
	data := make([]byte, bufferSize)
	_, err := mt.sock.Read(data)
	if err != nil {
		panic("Error reading data from the server")
	}
	return data
}

func (mt *MTFunctions) getReply(result interface{}) error {
	buffer := []byte{}
	for {
		data := mt.recv(SOCKET_BUFFER_SIZE)
		if len(data) == 0 {
			return fmt.Errorf("No data received from the server")
		}
		buffer = append(buffer, data...)

		err := json.Unmarshal(buffer, &result)
		if err == nil {
			return nil
		}
	}
}

func (mt *MTFunctions) SendCommand(command string, result interface{}) error {
	request := command + "|" + mt.authorizationCode + "\r\n"
	mt.sendRequest(request)
	return mt.getReply(result)
}

func NewMTFunctions(host string, port int, debug bool, instrumentConversionList []string, authorizationCode string) *MTFunctions {
	mt := &MTFunctions{
		HOST:                     host,
		PORT:                     port,
		debug:                    debug,
		instrumentConversionList: instrumentConversionList,
		authorizationCode:        authorizationCode,
		connected:                false,
		socket_error_message:     "",
		timeout_value:            120,
		sock:                     nil,
	}
	return mt
}
