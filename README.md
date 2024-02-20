## MetaTrader API Interface (Server)

This program(s) helps you connect to the MetaTrader desktop application programmatically, even if you're new to MQL programming.

**What is this Program(s)?**

Think of it like a special tool that lets your programs talk to MetaTrader. This means you can build apps that:

- Get live market data
- Get historical market data
- Get historical trade data (can be used to analyze your trading performance)
- Send trade orders

**What do I need?**

- **MetaTrader 5:** Make sure you have this trading platform installed on your computer.
- **Basic computer skills:** You'll need to copy and paste files, and run simple commands in your terminal.

**Step 1: Download the files**

1. Click the link below to download the necessary files(you can clone the repo or download as zip):
   [https://github.com/FortesenseLabs/wisefinance-mtservices.git](https://github.com/FortesenseLabs/wisefinance-mtservices.git)

2. Extract the downloaded file (usually by right-clicking and choosing "Extract").

**Step 2: Set up MetaTrader**

1. Open MetaTrader 5.
2. Go to "File" > "Open Data Folder". This shows where MetaTrader stores your files.
3. Inside the data folder, find the "MQL5" folder.
4. Open the "MQL5" folder.
5. Copy all the folders and files you downloaded earlier(step 1) from the "services/MQL5" folder into the "MQL5" folder you opened previously.

**Step 3: Connect to the server**

1. Open MetaTrader 5.
2. Go to "Experts" > "Expert Advisors".
3. Find the file called "mt-server.ex5" or "mt-server" in the downloaded files.
4. Drag and drop "mt-server.ex5" or "mt-server" onto any chart in MetaTrader.
5. The server is now running!

There are two ways to connect:

**A. Using another program:**

1. Open a terminal window (search for "Terminal" or "Command Prompt" on your computer).
2. Type `pip install -r requirements.txt` and press Enter. This installs the needed libraries.
3. Type `python client_example.py` and press Enter. This runs a program that connects to the API.

**B. Manually (for advanced users)**

**Step 4: Send requests (optional)**

The example program shows how to send requests to the server (the program you ran in step 3). This lets you control things like getting data or placing orders.

**Known Clients:**

1. [Python](https://github.com/FortesenseLabs/metatrader-py)
2. [Go](https://github.com/FortesenseLabs/go-metatrader)

**Important notes:**

- This guide is for MetaTrader 5 only, MetaTrader 4 is not supported.
- This is a basic guide, and the downloaded files may have additional features not covered here.
- For more advanced usage, refer to the project's documentation on GitHub.

**Known Errors:**

- cannot load custom indicator 'mtTools/ChartSpyControlpanelMCM':
  recompile ChartSpyControlpanelMCM in "MQL5" > "Indicators" > "mtTools"
- Cannot see symbol or symbol not found:
  try it with a deriv synthetic market account (support for others coming soon)
