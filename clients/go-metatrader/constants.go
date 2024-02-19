package metatrader

const SOCKET_BUFFER_SIZE = 8192 // * 8192 * 8192 //8192  // Adjust the buffer size as needed (4096)

var TIME_FRAMES = map[string]string{ // Timeframes
	"CURRENT": "TICK",
	"M1":      "M1",
	"M5":      "M5",
	"M15":     "M15",
	"M30":     "M30",
	"H1":      "H1",
	"H2":      "H2",
	"H3":      "H3",
	"H4":      "H4",
	"H6":      "H6",
	"H8":      "H8",
	"H12":     "H12",
	"D1":      "D1",
	"W1":      "W1",
	"MN1":     "MN1",
}
