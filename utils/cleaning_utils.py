# quick check on tables
def quick_check(df):
    print("SHAPE:", df.shape)
    print("\nDTYPES:\n", df.dtypes)
    print("\nSAMPLE:\n")
    print(df.describe(include="all"))
    print("\nNULLS:\n", df.isnull().sum())


# dates
def cast_dates(df, columns):
    for col in columns:
        df[col] = pd.to_datetime(df[col])
    return df


# fill nulls in one go
def fill_nulls(df, text_cols=[], numeric_cols=[]):
    for col in text_cols:
        df[col] = df[col].fillna("Unknown")
    for col in numeric_cols:
        df[col] = df[col].fillna(0)
    return df
