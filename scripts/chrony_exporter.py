#!/usr/bin/env python3
"""
@file chrony_exporter.py
@brief Скрипт для сбора метрик Chrony и их экспорта в формате Prometheus.
@author Участник 3
@date 2026-06-06
"""

import subprocess
import re
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 9123

class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/metrics':
            try:
                result = subprocess.run(['chronyc', 'tracking'], capture_output=True, text=True, check=True)
                output = result.stdout
                stratum = 0
                root_dispersion = 0.0
                skew = 0.0
                
                stratum_line = re.search(r'Stratum\s+:\s+(\d+)', output)
                if stratum_line:
                    stratum = int(stratum_line.group(1))
                
                dispersion_match = re.search(r'Root dispersion\s+:\s+([\d\.]+)', output)
                if dispersion_match:
                    root_dispersion = float(dispersion_match.group(1))
                
                skew_match = re.search(r'System time\s+:\s+([\-\d\.]+)', output)
                if skew_match:
                    skew = float(skew_match.group(1))
                
                metrics = f"""# HELP chrony_stratum Current stratum
# TYPE chrony_stratum gauge
chrony_stratum {stratum}
# HELP chrony_root_dispersion Root dispersion in seconds
# TYPE chrony_root_dispersion gauge
chrony_root_dispersion {root_dispersion}
# HELP chrony_skew_seconds System time skew in seconds
# TYPE chrony_skew_seconds gauge
chrony_skew_seconds {skew}
"""
                self.send_response(200)
                self.send_header('Content-type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write(metrics.encode('utf-8'))
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Error: {e}".encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', PORT), MetricsHandler)
    print(f"Starting Chrony Exporter on port {PORT}...")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.server_close()
