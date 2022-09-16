from catboost import CatBoostClassifier
import pandas as pd
import MetaTrader5 as mt5

from features import get_features

MA_PERIODS = [i for i in range(15, 500, 15)]

def update_rates(old_df, count = 10) -> pd.DataFrame:
    # Update

    if not mt5.initialize():
        print("initialize() failed")
        mt5.shutdown()

    rates = mt5.copy_rates_from_pos("EURUSD", mt5.TIMEFRAME_M5, 0, count)
    mt5.shutdown()

    print(rates)

    rates_frame = pd.DataFrame(columns=['time', 'close'])
    rates_frame['time'] = pd.to_datetime(
        rates['time'] * 1000 * 1000 * 1000)
    rates_frame['close'] = rates['close']
    rates_frame.set_index('time', inplace=True)
    rates_frame.index = pd.to_datetime(rates_frame.index, unit='s')

    print('From mt5')
    print(rates_frame.tail())
    return pd.concat([old_df, rates_frame]).dropna().drop_duplicates()

def calc_features_old(ds) -> pd.Series:
    current_row = ds.iloc[-1]
    dsC = ds.copy()
    X = pd.Series(dtype = float)

    count = 0
    for i in MA_PERIODS:
        # f[str(count)] = dsC - dsC.rolling(i).mean()
        m = dsC - dsC.rolling(i).mean()
        mean = m.iloc[-1]['close']
        X = pd.concat([X,pd.Series([mean])], ignore_index=True)
        count += 1
    print('features')
    print(X)
    return X

def initDataset() -> pd.DataFrame:
    return pd.DataFrame()

def newBar():
    global dataset
    dataset = update_rates(dataset)
    print('Rates updated')
    print(dataset)
    # X = calc_features(dataset)
    X = get_features(dataset)
    signal = model.predict(X.iloc[-1])
    meta_signal = meta_model.predict(X.iloc[-1])
    return signal, meta_signal

def init_for_mt():
    global model
    global meta_model
    global dataset

    print("MetaTrader5 package author: ", mt5.__author__)
    print("MetaTrader5 package version: ", mt5.__version__)

    model = CatBoostClassifier(iterations=1000,
                               depth=6,
                               learning_rate=0.1,
                               custom_loss=['Accuracy'],
                               eval_metric='Accuracy',
                               verbose=False,
                               use_best_model=True,
                               task_type='CPU')
    model.load_model("ml/9138/catmodel.cbm")

    meta_model = CatBoostClassifier(iterations=1000,
                                    depth=6,
                                    learning_rate=0.1,
                                    custom_loss=['Accuracy'],
                                    eval_metric='Accuracy',
                                    verbose=False,
                                    use_best_model=True,
                                    task_type='CPU')
    meta_model.load_model("ml/9138/meta_catmodel.cbm")

    dataset = initDataset()
    dataset = update_rates(dataset, count=4000)
   