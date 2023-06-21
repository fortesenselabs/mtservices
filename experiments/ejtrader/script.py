from ejtraderMT import Metatrader

'''
to change the host IP example Metatrader("192.168.1.100") ou
you can use doman example  "metatraderserverdomain.com"

for you local time on the Dataframe  Metatrader(tz_local=True)
attention utc time is the default for Dataframe index "date"


for real volume for active like WIN futures ou centralized market use Metatrader(real_volume=True)
attention tick volume is the default


to use more than one option just use , example Metatrader(host='hostIP',tz_local=True)
'''
api = Metatrader(debug=True)


accountInfo = api.accountInfo()
print(accountInfo)
print(accountInfo['broker'])
print(accountInfo['balance'])
