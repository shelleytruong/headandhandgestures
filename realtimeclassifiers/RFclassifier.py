import numpy as np
from collections import deque
import pandas as pd
import socket
import threading
from itertools import islice
from tsfresh import extract_features
from tsfresh.feature_extraction import EfficientFCParameters
import pickle

#function to process imu data to output predictions from model
def process_data():
    global data_array
    global data_arraypods
    global predictionsarr

    global prediction_results
    while True:
        # Wait for data to be available in buffer

        window = 50

        # data = np.array(data_array, dtype=np.float32)  # Convert mp.Array to NumPy array

        if len(data_arraypods) >= 50:
            for i in range(0, len(data_arraypods) - window, 15):
                window2 = list(islice(data_arraypods, i, i + 50))
                airpodscolumns = ['Time', 'airpodsaccelerationX', 'airpodsaccelerationY', 'airpodsaccelerationZ',
                                  'airpodsgyroX', 'airpodsgyroY', 'airpodsgyroZ']
                airpods = pd.DataFrame(window2, columns=airpodscolumns)
                airpods = airpods.reset_index(drop=True)

                window = list(islice(data_array, i, i + 50))
                iphonecolumns = ['Time', 'iPhoneaccelerationX', 'iPhoneaccelerationY', 'iPhoneaccelerationZ',
                                 'iPhonegyroX', 'iPhonegyroY', 'iPhonegyroZ', 'MagneticFieldX', 'MagneticFieldY',
                                 'MagneticFieldZ']
                iphone = pd.DataFrame(window, columns=iphonecolumns)
                iphone = iphone.reset_index(drop=True)

                df = pd.concat([airpods, iphone], ignore_index=True)
                df['Time'] = df['Time'].str.replace(' ', '')
                # Add a space between the time and date
                df['Time'] = df['Time'].str.replace(r'(\d{4}/\d{2}/\d{2})(\d{2}:\d{2}:\d{2}.\d{3})', r'\1 \2')
                # convert the time column to datetime object
                df['Time'] = pd.to_datetime(df['Time'])
                # sort the dataframe by time column
                df = df.sort_values(by='Time')
                # Fill missing values with the previous non-missing row
                df.fillna(method='bfill', inplace=True)
                # Drop duplicate rows
                df.drop_duplicates(inplace=True)
                df = df.iloc[::2, :]
                df = df.fillna(0)

                df['TrialID'] = 1

                #extract relevant features
                extractedFeatures = extract_features(df, column_id='TrialID', column_sort='Time',default_fc_parameters=EfficientFCParameters(),n_jobs=4)
                extractedFeatures = extractedFeatures.fillna(0)
                extractedFeatures = extractedFeatures.loc[:, relevant_features]

                #input features into model
                predictions = model.predict_proba(extractedFeatures)
                print((predictions))

                #post processing
                threshold = 0.2
                if max(predictions[0]) >= threshold:
                    prediction_results.append(np.argmax(predictions[0]))
                    print((predictionsarr))
                else:
                    prediction_results.append(len(predictions[0])-1)



# function for handling data from sending client
def handle_send_client(client_socket):
    global data_array
    global data_arraypods

    while True:
        # Receive data from sending client
        data = client_socket.recv(1024)  # Placeholder for actual data receiving
        motionData = data.decode().split(',')
        if len(motionData) == 11 or len(motionData) == 8:
            #store imu data in buffer
            if motionData[0] == 'AirPods':
                time = [motionData[1]]
                f = [float(x) for x in motionData[2:]]
                dataarr = (time+ f)
                data_arraypods.append(dataarr)
            if motionData[0] == 'iPhone':
                time = [motionData[1]]
                f2 = [float(x) for x in motionData[2:]]
                dataarr = (time + f2)
                data_array.append(dataarr)


#function for handling data for receiving client
def handle_receive_client(client_socket):
    global prediction_results
    plist = np.zeros(len(classes))

    while True:
        # Wait for prediction result to be available
        if len(prediction_results) >= 1:
            pred = prediction_results.pop()

            plist[pred] = 1
            print(plist)

            predictionstr = np.array2string(plist)
            string = predictionstr + "\n"
            client_socket.send(string.encode())
            plist = np.zeros(len(classes))

            print("Prediction:", classes[pred])




if __name__ == '__main__':
    host = "0.0.0.0"  # Listen on all available network interfaces

    port = 242 #change port number

    threshold = 0.8


    data_array = deque(maxlen=65)  # Circular buffer to store IMU data
    prediction_results = []  # List to store prediction results
    data_arraypods = deque(maxlen=65)  # Circular buffer to store IMU data from airpods
    predictionsarr = []

    with open('rfccat1.pkl', 'rb') as f:
        model = pickle.load(f)
    classes = model.classes_
    print(classes)
    # Load the relevant feature names that were saved during training
    with open("relevant_features.txt", "r") as f:
        relevant_features = f.read().splitlines()

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen(1)

    #connect the sosckets and start threads
    print("Server listening on {}:{}".format(host, port))
    while True:

        client_socket, send_address = server_socket.accept()  # Accept sending client connection
        print("Accepted connection from {}:{}".format(send_address[0], send_address[1]))

        processing_thread = threading.Thread(target=process_data)
        processing_thread.start()

        # Start handling thread for sending client
        send_thread = threading.Thread(target=handle_send_client, args=(client_socket,))
        send_thread.start()

        # Start handling thread for receiving client
        receive_thread = threading.Thread(target=handle_receive_client, args=(client_socket,))
        receive_thread.start()

