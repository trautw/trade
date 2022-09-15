import pandas as pd

MA_PERIODS = [i for i in range(15, 500, 15)]
SYMBOL = 'EURUSD'
FEATURE_COUNT = len(MA_PERIODS) + 2

print('Hello from features')


def update_features(pTable) -> pd.DataFrame:
    pFixedC = pTable.copy()
    count = 0
    for i in MA_PERIODS:
        pTable[str(count)] = pFixedC - pFixedC.rolling(i).mean()
        count += 1

    pTable['std'] = pFixedC.rolling(20).std(ddof=0)
    pTable['MA-TP'] = pFixedC.rolling(20).mean()
    pTable['BOLU'] = pTable['MA-TP'] + 2*pTable['std']
    pTable['BOLD'] = pTable['MA-TP'] - 2*pTable['std']

    pTable[str(count)] = pTable['MA-TP'] > pTable['BOLU']
    count += 1
    pTable[str(count)] = pTable['MA-TP'] < pTable['BOLD']
    count += 1

    pTable.drop('std', axis=1, inplace=True)
    pTable.drop('MA-TP', axis=1, inplace=True)

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

    pFixed = update_features(pFixed)
    return pFixed.dropna()
