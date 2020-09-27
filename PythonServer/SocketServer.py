import socket
import _thread
import sys
import subprocess

# cria o socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    s.bind(('', 8888)) # conecta o socket na porta
except socket.error as e:
    print('Erro ao conectar o socket: ' + str(e))
    sys.exit()

while True:
    s.listen(2)
    print('Socket ouvindo...')

    conn, addr = s.accept()
    print('Socket conectou a ' + addr[0] + ':' + str(addr[1]))  

    msg = conn.recv(1024*10)

    msg = msg.decode("utf-8")
    print("client requested " + msg) 

    out = subprocess.check_output(['spotifycli', '--' + msg])
    out = out.decode("utf-8") 
    print("server will return " + out)
    conn.sendall(str.encode(out))

    conn.close()