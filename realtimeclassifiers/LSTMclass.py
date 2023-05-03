import numpy as np
from collections import deque
import pandas as pd
import socket
import threading
import tensorflow
import math
from itertools import islice
import statistics

def normalise(pitch,yaw,roll):
    mean_pitch = np.mean(pitch)
    std_pitch = np.std(pitch)
    if std_pitch == 0:
        print("Warning: Standard deviation is zero. Adding a small constant value to avoid division by zero.")
        std_pitch += 1e-6

    mean_yaw = np.mean(yaw)
    std_yaw = np.std(yaw)
    if std_yaw == 0:
        print("Warning: Standard deviation is zero. Adding a small constant value to avoid division by zero.")
        std_yaw += 1e-6

    mean_roll = np.mean(roll)
    std_roll = np.std(roll)
    if std_roll == 0:
        print("Warning: Standard deviation is zero. Adding a small constant value to avoid division by zero.")
        std_roll += 1e-6

    normalized_pitch = (pitch - mean_pitch) / std_pitch

    normalized_yaw = (yaw - mean_yaw) / std_yaw

    normalized_roll = (roll - mean_roll) / std_roll

    return normalized_pitch,normalized_yaw,normalized_roll

def calcAirpods(df):
    # Extract accelerometer and gyroscope data
    accel_x = df.iloc[:, 0]
    accel_y = df.iloc[:, 1]
    accel_z = df.iloc[:, 2]
    gyro_x = df.iloc[:, 3]
    gyro_y = df.iloc[:, 4]
    gyro_z = df.iloc[:, 5]
    pitch = [0] * len(df)
    yaw = [0] * len(df)
    roll = [0] * len(df)
    # Loop through the data
    for i in range(len(df)):
        # Extract accelerometer and gyroscope readings for the current row
        ax = accel_x.iloc[i]
        ay = accel_y.iloc[i]
        az = accel_z.iloc[i]
        gx = gyro_x.iloc[i]
        gy = gyro_y.iloc[i]
        gz = gyro_z.iloc[i]

        # Calculate pitch, yaw, and roll angles using the formulas
        pitch[i] = np.arctan2(ay, np.sqrt(ax ** 2 + az ** 2))
        roll[i] = np.arctan2(-ax, np.sqrt(ay ** 2 + az ** 2))
        yaw[i] = yaw[-1] + (gx * (1 / 25))  # assuming sampling rate of 25 Hz and dt of 1/25

    pitch, yaw, roll = normalise(pitch, yaw, roll)
    data = {'pitch': pitch, 'roll': roll, 'yaw': yaw}

    # Create a pandas DataFrame from the dictionary
    return data


def calcIphone(df):
# Extract accelerometer and gyroscope data
    accel_x = df.iloc[:, 6]
    accel_y = df.iloc[:, 7]
    accel_z = df.iloc[:, 8]

    gyro_x = df.iloc[:, 9]
    gyro_y = df.iloc[:, 10]
    gyro_z = df.iloc[:, 11]

    mag_x = df.iloc[:, 12]
    mag_y = df.iloc[:, 13]
    mag_z = df.iloc[:, 14]

    pitch = [0] * len(df)
    yaw = [0] * len(df)
    roll = [0] * len(df)
    # Loop through the data
    for i in range(len(df)):
    # Calculate pitch angle
        pitch[i] = math.atan2(accel_y.iloc[i], math.sqrt(accel_x.iloc[i] ** 2 + accel_z.iloc[i] ** 2))

        # Calculate roll angle
        roll[i] = math.atan2(-accel_x.iloc[i], math.sqrt(accel_y.iloc[i] ** 2 + accel_z.iloc[i] ** 2))

        # Calculate yaw angle
        mag_xh = float(mag_x.iloc[i]) * math.cos(roll[i]) + float(mag_y.iloc[i]) * math.sin(pitch[i]) * math.sin(roll[i]) - float(mag_z.iloc[i]) * math.cos(pitch[i]) * math.sin(roll[i])
        mag_yh = float(mag_y.iloc[i]) * math.cos(pitch[i]) + float(mag_z.iloc[i]) * math.sin(pitch[i])
        yaw[i] = math.atan2(-mag_yh, mag_xh)
    pitch, yaw, roll = normalise(pitch,yaw,roll)

    data = {'pitchphone': pitch, 'rollphone': roll, 'yawphone': yaw}
    return data



# function for processing data and generating predictions
def process_data():
    global data_array
    global data_arraypods
    global predictionsarr

    global prediction_results
    while True:

        window = 50

        if len(data_arraypods) >= 50:

            for i in range(0, len(data_arraypods)-window,8):
                #format data
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
                # Save the cleaned dataframe to a new CSV file
                df = df.iloc[::2, :]
                df = df.fillna(0)

                df = df.drop('Time', axis=1)

                #preprocessing
                airpodsdata = calcAirpods(df)
                iphonedata = calcIphone(df)
                data2 = {'airpodsgyroX': df.iloc[:, 3], 'airpodsgyroY': df.iloc[:, 4],
                         'airpodsgyroZ': df.iloc[:, 5], 'iPhonegyroX': df.iloc[:, 9],
                         'iPhonegyroY': df.iloc[:, 10], 'iPhonegyroZ': df.iloc[:, 11]}

                combined_dict = {}
                combined_dict.update(airpodsdata)
                combined_dict.update(iphonedata)
                combined_dict.update(data2)
                df = pd.DataFrame(combined_dict)

                u = df.copy()
                df['varpitch'] = u['pitch'].rolling(window=10).var()
                df['varyaw'] = u['yaw'].rolling(window=10).var()
                df['varroll'] = u['roll'].rolling(window=10).var()
                df['varpitchphone'] = u['pitchphone'].rolling(window=10).var()
                df['varyawphone'] = u['yawphone'].rolling(window=10).var()
                df['varrollphone'] = u['rollphone'].rolling(window=10).var()

                df['airpodsgyroX'] = u['airpodsgyroX'].rolling(window=10).median()
                df['airpodsgyroY'] = u['airpodsgyroY'].rolling(window=10).median()
                df['airpodsgyroZ'] = u['airpodsgyroZ'].rolling(window=10).median()
                df['iPhonegyroX'] = u['iPhonegyroX'].rolling(window=10).median()
                df['iPhonegyroY'] = u['iPhonegyroY'].rolling(window=10).median()
                df['iPhonegyroZ'] = u['iPhonegyroZ'].rolling(window=10).median()

                df = df[9:]
                df = df.fillna(0)
                df2 = np.array([df])

                print(df2.shape[0], df2.shape[1], df2.shape[2])
                # Make a prediction using the input data
                input_data = tensorflow.constant(df2, dtype=tensorflow.float64)
                # Cast the tensor to type float
                input_data = tensorflow.cast(input_data, dtype=tensorflow.float32)

                output = predict_fn(input_data)
                print(output)


                predictions = output['dense_115'].numpy().tolist()[0]
                print(classes[np.argmax((output['dense_115'].numpy())[0], axis=0)])

                #postprocessing
                threshold = 0.6
                if max(predictions) >= threshold:
                    predictionsarr.append(np.argmax(predictions))
                    print((predictionsarr))
                if len(predictionsarr)>=3:
                    arr = predictionsarr
                    print((predictionsarr))

                    predictionsarr = []
                    try:
                        print((predictionsarr))
                        mode = statistics.mode(arr)
                        prediction_results.append(mode)
                        print("Mode: ", mode)
                    except statistics.StatisticsError:
                        print("Error: No mode for empty data")
                        prediction_results.append(len(predictions) - 1)  # deleter for nostand

# function for handling data from sending client
def handle_send_client(client_socket):
    global data_array
    global data_arraypods

    while True:
        # Receive data from sending client
        data = client_socket.recv(1024)  # Placeholder for actual data receiving

        motionData = data.decode().split(',')

        #record IMU data
        if len(motionData) == 11 or len(motionData) == 8:
            if motionData[0] == 'AirPods':
                time = [motionData[1]]
                f = [float(x) for x in motionData[2:]]
                dataarr = (time + f)
                data_arraypods.append(dataarr)

                # Wrap around to the beginning of the circular buffer if needed

            if motionData[0] == 'iPhone':
                time = [motionData[1]]
                f2 = [float(x) for x in motionData[2:]]
                dataarr = (time + f2)
                data_array.append(dataarr)
                # Wrap around to the beginning of the circular buffer if needed


# function for handling data for receiving client
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
            string = predictionstr+"\n"

            #send prediction to client
            client_socket.send(string.encode())
            plist = np.zeros(len(classes))

            print("Prediction:",classes[pred])




if __name__ == '__main__':
    host = "0.0.0.0"
    port = 373

    # Define global variables for data buffer and prediction results
    data_array = deque(maxlen=65)  # Circular buffer to store IMU data
    prediction_results = []  # List to store prediction results
    # Start processing thread
    data_arraypods = deque(maxlen=65)  # Circular buffer to store IMU data for airpods
    predictionsarr = []
    #classes = ['hand clockwise circle', 'hand clockwise circle, head clockwise circle', 'hand down'
   #    ,'hand down, head down', 'hand left', 'hand left, head left',
    # 'hand right', 'hand right, head right' ,'hand up' ,'hand up, head up',
    # 'head clockwise circle' ,'head down' ,'head left', 'head right', 'head up',
    # 'standing still']
    classes = ['hand clockwise circle', 'hand down', 'hand left', 'hand right', 'hand up',
               'standing still']
   # classes =  ['head clockwise circle', 'head down' ,'head left' ,'head right' ,'head up',
    # 'standing still']
    # classes = ['hand clockwise circle, head clockwise circle', 'hand down, head down',
    # 'hand left, head left' ,'hand right, head right', 'hand up, head up',
    # 'standing still']

    #load pretrained model
    loaded_model = tensorflow.saved_model.load("modelcat1")
    predict_fn = loaded_model.signatures['serving_default']
    print(loaded_model)

    #connect clients
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen(1)


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




