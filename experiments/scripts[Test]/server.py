import http.server
import socketserver

PORT = 8000

class GetHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(b"<html><head><title>Python Server</title></head>")
        self.wfile.write(b"<body><p>This is a simple Python server.</p>")
        self.wfile.write(b"</body></html>")

Handler = GetHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print("serving at port", PORT)
    httpd.serve_forever()
