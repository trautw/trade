import pandas as pd

MA_PERIODS = [i for i in range(15, 500, 15)]
SYMBOL = 'EURUSD'
FEATURE_COUNT = len(MA_PERIODS) + 2

print('Hello from features')


def get_features(the_data) -> pd.DataFrame:
    pTable = the_data.copy()
    pFixedC = the_data.copy()
    count = 0
    for i in MA_PERIODS:
        pTable[str(count)] = pFixedC - pFixedC.rolling(i).mean()
        count += 1

    # Standard deviation 20
    pTable['std'] = pFixedC.rolling(20).std(ddof=0)
    # Moving Average 20
    pTable['MA-TP'] = pFixedC.rolling(20).mean()
    # Bollinge Band Upper
    pTable['BOLU'] = pTable['MA-TP'] + 2*pTable['std']
    # Bollinge Band Lower
    pTable['BOLD'] = pTable['MA-TP'] - 2*pTable['std']

    # above bollinger band
    # pTable['BBAbove'] = pTable['MA-TP'] > pTable['BOLU']
    pTable['BBAbove'] = pTable['MA-TP'] - pTable['BOLU']

    # below bollinger band
    # pTable['BBBelow'] = pTable['MA-TP'] < pTable['BOLD']
    pTable['BBBelow'] = pTable['MA-TP'] - pTable['BOLD']

    pTable.drop('std', axis=1, inplace=True)
    pTable.drop('MA-TP', axis=1, inplace=True)
    pTable.drop('BOLU', axis=1, inplace=True)
    pTable.drop('BOLD', axis=1, inplace=True)

    # print(pTable)
    # print(pTable.describe())

    return pTable


def get_X(df) -> pd.DataFrame:
    return df[df.columns[1:FEATURE_COUNT+1]]


def get_historic_prices() -> pd.DataFrame:
    p = pd.read_csv('EURUSDMT5.csv', delim_whitespace=True)
    pFixed = pd.DataFrame(columns=['time', 'close'])
    pFixed['time'] = p['<DATE>'] + ' ' + p['<TIME>']
    pFixed['time'] = pd.to_datetime(pFixed['time'], infer_datetime_format=True)
    pFixed['close'] = p['<CLOSE>']
    pFixed.set_index('time', inplace=True)
    pFixed.index = pd.to_datetime(pFixed.index, unit='s')
    pFixed = pFixed.dropna()

    # pFixed = update_features(pFixed)
    return pFixed.dropna()
