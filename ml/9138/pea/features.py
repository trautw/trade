import pandas as pd

FEATURE_COUNT = 0

MA_PERIODS = [i for i in range(15, 500, 15)]

print('Hello from features')


def calc_bollinger(the_data, feature) -> pd.DataFrame:
    global FEATURE_COUNT

    # Standard deviation 20
    feature['std'] = the_data.rolling(20).std(ddof=0)
    # Moving Average 20
    feature['MA-TP'] = the_data.rolling(20).mean()
    # Bollinge Band Upper
    feature['BOLU'] = feature['MA-TP'] + 2*feature['std']
    # Bollinge Band Lower
    feature['BOLD'] = feature['MA-TP'] - 2*feature['std']

    # above bollinger band
    # pTable['BBAbove'] = pTable['MA-TP'] > pTable['BOLU']
    feature['BBAbove'] = feature['MA-TP'] - feature['BOLU']
    FEATURE_COUNT += 1

    # below bollinger band
    # pTable['BBBelow'] = pTable['MA-TP'] < pTable['BOLD']
    feature['BBBelow'] = feature['MA-TP'] - feature['BOLD']
    FEATURE_COUNT += 1

    feature.drop('std', axis=1, inplace=True)
    feature.drop('MA-TP', axis=1, inplace=True)
    feature.drop('BOLU', axis=1, inplace=True)
    feature.drop('BOLD', axis=1, inplace=True)

    return feature


def calc_mean(the_data, feature) -> pd.DataFrame:
    global FEATURE_COUNT
    count = 0
    for i in MA_PERIODS:
        feature[str(count)] = the_data - the_data.rolling(i).mean()
        count += 1
    FEATURE_COUNT += len(MA_PERIODS)

    return feature


def get_features(the_data) -> pd.DataFrame:
    global FEATURE_COUNT
    pTable = the_data.copy()

    pTable = calc_mean(the_data, pTable)
    pTable = calc_bollinger(the_data, pTable)

    return pTable


def get_X(df) -> pd.DataFrame:
    return df[df.columns[1:FEATURE_COUNT+1]]


def get_historic_prices(CSVFILE) -> pd.DataFrame:
    p = pd.read_csv(CSVFILE, delim_whitespace=True)
    pFixed = pd.DataFrame(columns=['time', 'close'])
    pFixed['time'] = p['<DATE>'] + ' ' + p['<TIME>']
    pFixed['time'] = pd.to_datetime(pFixed['time'], infer_datetime_format=True)
    pFixed['close'] = p['<CLOSE>']
    pFixed.set_index('time', inplace=True)
    pFixed.index = pd.to_datetime(pFixed.index, unit='s')
    pFixed = pFixed.dropna()

    # pFixed = update_features(pFixed)
    return pFixed.dropna()
