# Standard library imports
from datetime import datetime

# Third party imports
from flask import Flask
from flask import request
from logging.config import dictConfig
import json
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression

# Local application imports
from handler import newBar, init_for_mt

dictConfig({
    'version': 1,
    'formatters': {'default': {
        'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    }},
    'handlers': {'wsgi': {
        'class': 'logging.StreamHandler',
        'stream': 'ext://flask.logging.wsgi_errors_stream',
        'formatter': 'default'
    }},
    'root': {
        'level': 'INFO',
        'handlers': ['wsgi']
    }
})

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
            if rcv_data['isNewBar']:
                print(rcv_data)
                signal, meta_signal = newBar()
            else:
                signal = 2
                meta_signal = 2
            left, right = calcregr(rcv_data['clprArray'])
            tickTime = pd.to_datetime(
                rcv_data['tickTime'], infer_datetime_format=True)

            result = {
                "from": left,
                "to": right,
                "sig": signal,
                "meta_sig": meta_signal
            }
            if rcv_data['isNewBar']:
                print(result)
            if result:
                return json.dumps(result)
            else:
                return '200'
        else:
            return '404'

if __name__ == "__main__":
    init_for_mt()

    app.run(host='localhost', port='43560')