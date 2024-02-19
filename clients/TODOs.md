# TODO

## 1

- Check if the difference is more than 5 years (5 _ 365 _ 24 _ 60 _ 60 seconds):
  12hrs => 12 _ 60 _ 60
  if (diffInSeconds > 12 _ 60 _ 60):
  Adjust toDate to be 5 years after fromDate
  toDate = TimeAdd(fromDate, PERIOD_YEARS, 5)

## 2:

1. The server does not cancel all orders (done by the client)
2. The server does not close all positions (done by the client)

## 3:

Add database storage support

## Resources and Other talks

- https://tradersconnect.com/
- https://hdfxtrade.com/
- https://github.com/AdamTibi/LSTM-FX/

- for the AI we can use an indicator approach or a separate service approach
- https://www.luxalgo.com/
- ict trading AI [Google Search]
- ict trading strategy [Google Search]
