from flask import Flask
from flask import request
import json
import numpy as np
from sklearn.linear_model import LinearRegression
from catboost import CatBoostClassifier
import pandas as pd

MA_PERIODS = [i for i in range(15, 500, 15)]

app = Flask(__name__)

#/*
#void fill_arays1(double & features[]) {
#    double pr[], ret[]
#    ArrayResize(ret, 1)
#    for (int i=ArraySize(MAs1)-1
#         i >= 0
#         i--) {
#        CopyClose(NULL, PERIOD_CURRENT, 1, MAs1[i], pr)
#        double mean = MathMean(pr)
#        double std = MathStandardDeviation(pr)
#        ret[0] = pr[MAs1[i]-1] - mean
#        ArrayInsert(features, ret, ArraySize(features), 0, WHOLE_ARRAY)
#    }
#    ArraySetAsSeries(features, true)
#}
#*/


def get_prices() -> pd.DataFrame:
    p = pd.read_csv('../EURUSDMT5.csv', delim_whitespace=True)
    pFixed = pd.DataFrame(columns=['time', 'close'])
    pFixed['time'] = p['<DATE>'] + ' ' + p['<TIME>']
    pFixed['time'] = pd.to_datetime(pFixed['time'], infer_datetime_format=True)
    pFixed['close'] = p['<CLOSE>']
    pFixed.set_index('time', inplace=True)
    pFixed.index = pd.to_datetime(pFixed.index, unit='s')
    pFixed = pFixed.dropna()
    pFixedC = pFixed.copy()

    count = 0
    for i in MA_PERIODS:
        pFixed[str(count)] = pFixedC - pFixedC.rolling(i).mean()
        count += 1
    return pFixed.dropna()

def calcregr(chartdata):
    Y = np.array(chartdata).reshape(-1,1)
    X = np.array(np.arange(len(chartdata))).reshape(-1,1)
        
    lr = LinearRegression()
    lr.fit(X, Y)
    Y_pred = lr.predict(X)

    return Y_pred.astype(str).item(-1), Y_pred.astype(str).item(0)


@app.route("/Predict", methods=['GET', 'POST'])
def indx():
    global prices
    if request.method == 'POST':
        if request.data:
            rcv_data = json.loads(request.data.decode(encoding='utf-8'))
            # print(rcv_data['clprArray'])
            # print(rcv_data)
            if rcv_data['isNewBar']:
                print(rcv_data)
            left, right = calcregr(rcv_data['clprArray'])
            now = pd.to_datetime(
                rcv_data['tickTime'], infer_datetime_format=True)

            d = {'time': [now], 'close': [rcv_data['ask']]}
            newLine = pd.DataFrame(data = d)            
            newLine.set_index('time', inplace=True)
            newLine.index = pd.to_datetime(newLine.index, unit='s')

            # print("Recalc")
            count = 0
            for i in MA_PERIODS:
                # print(prices['close'].iloc[-i:].mean())
                newLine[str(count)] = newLine['close'] - \
                    prices['close'].iloc[-i:].mean()
                count += 1

            # print("NewLine 1")
            # print(newLine)
            # print("Prices 0")
            # print(prices)
            prices = pd.concat([prices, newLine])

            # print('Features')
            # last row
            features = prices.iloc[-2,:]
            # print(features)
            features = features.iloc[1:]
            # print(features)
            # features.drop('time')
            # print(features.describe())
            print('Prediction')
            prediction = meta_model.predict(features)
            print(prediction)       

            result = {
                "from": left,
                "to": right,
                "sig": 0.1,
                "meta_sig": 0.2
            }
            print(result)
            if result:
                return json.dumps(result)
            else:
                return '200'
        else:
            return '404'

if __name__ == "__main__":
    model = CatBoostClassifier(iterations=1000,
                               depth=6,
                               learning_rate=0.1,
                               custom_loss=['Accuracy'],
                               eval_metric='Accuracy',
                               verbose=False,
                               use_best_model=True,
                               task_type='CPU')
    model.load_model("catmodel.cbm")

    meta_model = CatBoostClassifier(iterations=1000,
                                    depth=6,
                                    learning_rate=0.1,
                                    custom_loss=['Accuracy'],
                                    eval_metric='Accuracy',
                                    verbose=False,
                                    use_best_model=True,
                                    task_type='CPU')
    meta_model.load_model("meta_catmodel.cbm")

    prices = get_prices()
    print(prices.head())
    print('Features')
    # last row
    features = prices.iloc[-2,:]
    print(features)
    features = features.iloc[1:]
    print(features)
    # features.drop('time')
    print(features.describe())
    print('Prediction')
    print(meta_model.predict(features))

    app.run(host='localhost', port='43560')