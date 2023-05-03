
import csv
import threading
import socket
import os

def handle_client(client_socket):
    global isWriting

    global airpodsFile
    global iphoneFile
    global airpodsCsv
    global iphoneCsv
    global iphonesensordata
    global airpodssensordata
    global airpodsArray
    global iphoneArray

    global device
    global info
    print(f"New client connected: {client_socket}")
    while True:
        data = client_socket.recv(1024)
        if not data:
            print(f"Client disconnected: {client_socket}")
            break

        datamessage = data.decode().split(' ')
        motionData = data.decode().split(',')

        #send IMU data to client to preint graphs
        client_socket.send(iphonesensordata.encode())
        client_socket.send(",".encode())
        client_socket.send(airpodssensordata.encode())
        client_socket.send("\n".encode())

        if ((motionData[0] == 'iPhone')):
            iphonesensordata = data.decode()
        elif(motionData[0] == 'AirPods'):
            airpodssensordata = data.decode()

        if datamessage[0] == "start":
            #retrive info from client
            isWriting = True
            device = datamessage[-1]
            userdata = datamessage[1:3]
            joined_item= [""]
            joined_item[0] = " ".join(datamessage[3:-1])
            info = userdata + joined_item
            print(info)

        elif isWriting:
            #clear data to save if redo is passed in
            if data.decode() == 'redo':
                airpodsArray=[]
                iphoneArray=[]

            elif data.decode() == 'stop':
                #save data into csv files
                for row in airpodsArray:
                    if len(row) == 11:
                        airpodsCsv.writerow(row)
                        print(airpodsArray)

                for rows in iphoneArray:
                    if len(rows) == 14:
                        print(iphoneArray)
                        iphoneCsv.writerow(rows)

                isWriting = False
                airpodsArray = []
                iphoneArray = []
            else:
                #record IMU data for devices
                if (device == 'AirPods') or (device == 'Both'):
                    if motionData[0] == 'AirPods':
                        airpodsArray.append(info + [device]+ motionData[1:])
                if device == 'iPhone' or (device == 'Both'):
                    if motionData[0] == 'iPhone':
                        iphoneArray.append(info +[device]+motionData[1:])

    client_socket.close()
    airpodsFile.close()
    iphoneFile.close()


if __name__ == '__main__':

    isWriting = False
    airpodsCsv = None
    iphoneCsv = None

    device = ' '
    info = ['N/A', 'N/A ', 'N/A']

    host = "0.0.0.0"  # Listen on all available network interfaces
    port = 139 #change port number


    #headers for files
    iphoneheader = ['ParticipantID', 'TrialID', 'Label', 'Device', 'Time','AccelerationX','AccelerationY'
        ,'AccelerationZ','RotationRateX','RotationRateY','RotationRateZ','MagneticFieldX','MagneticFieldY'
        ,'MagneticFieldZ']
    airpodsheader = ['ParticipantID', 'TrialID', 'Label', 'Device', 'Time','AccelerationX','AccelerationY'
        ,'AccelerationZ','RotationRateX','RotationRateY','RotationRateZ']


    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen(1)

    airpodsArray = []
    iphoneArray = []
    iphonesensordata = ''
    airpodssensordata = ''

    #create/open existing csv files
    if os.path.exists("airpodsdata.csv"):
        airpodsFile = open('airpodsdata.csv', 'a', newline='')
        airpodsCsv = csv.writer(airpodsFile)
    else:
        airpodsFile = open('airpodsdata.csv', 'a', newline='')
        airpodsCsv = csv.writer(airpodsFile)
        airpodsCsv.writerow(airpodsheader)

    if os.path.exists("iphonedata.csv"):
        airpodsFile = open('iphonedata.csv', 'a', newline='')
        airpodsCsv = csv.writer(iphoneFile)
    else:
        airpodsFile = open('iphonedata.csv', 'a', newline='')
        airpodsCsv = csv.writer(iphoneFile)
        airpodsCsv.writerow(iphoneheader)


    print("Server listening on {}:{}".format(host, port))

    #connect clients to server and start threads
    while True:
        client_socket, address = server_socket.accept()
        print("Accepted connection from {}:{}".format(address[0], address[1]))
        client_thread = threading.Thread(target=handle_client, args=(client_socket,))
        client_thread.start()
