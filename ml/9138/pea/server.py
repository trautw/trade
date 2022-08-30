from flask import Flask
from flask import request
import json
import numpy as np
from sklearn.linear_model import LinearRegression

app = Flask(__name__)

def calcregr(chartdata):
    Y = np.array(chartdata).reshape(-1,1)
    X = np.array(np.arange(len(chartdata))).reshape(-1,1)
        
    lr = LinearRegression()
    lr.fit(X, Y)
    Y_pred = lr.predict(X)

    return Y_pred.astype(str).item(-1), Y_pred.astype(str).item(0)


@app.route("/Predict", methods=['GET', 'POST'])
def indx():
    if request.method == 'POST':
        if request.data:
            rcv_data = json.loads(request.data.decode(encoding='utf-8'))
            # print(rcv_data['clprArray'])
            left, right = calcregr(rcv_data['clprArray'])
            result = {
                "from": left,
                "to": right 
            }
            print(result)
            if result:
                return json.dumps(result)
            else:
                return '200'
        else:
            return '404'

if __name__ == "__main__":
    app.run(host='localhost', port='43560')