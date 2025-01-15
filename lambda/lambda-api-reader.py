import json
import requests
from datetime import datetime
import time
import boto3

sqs = boto3.client('sqs')
QUEUE_URL = 'https://sqs.ap-southeast-2.amazonaws.com/676206904741/stock-price-queue'

def get_stock_quote(symbol):
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    params = {
        'interval': '1m',
        'range': '1d',
        'includePrePost': 'true',  # Include pre/post market data
        'useYfid': 'true',
        'includePreviousClose': 'true'
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        
        data = response.json()
        result = data['chart']['result'][0]
        
        # Get the most recent price from the time series
        timestamps = result['timestamp']
        prices = result['indicators']['quote'][0]['close']
        
        # Find the last valid price (not None)
        latest_price = None
        for i in range(len(prices)-1, -1, -1):
            if prices[i] is not None:
                latest_price = prices[i]
                timestamp = timestamps[i]
                break
                
        if latest_price is None:
            latest_price = result['meta']['regularMarketPrice']
            timestamp = result['meta']['regularMarketTime']
            
        currency = result['meta'].get('currency', 'USD')
        
        return {
            "ticker": symbol,
            "price": latest_price,
            "currency": currency,
            "timestamp": datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d_%H-%M-%S')
        }
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data for {symbol}: {str(e)}")
        return None
    except (KeyError, IndexError) as e:
        print(f"Error parsing data for {symbol}: {str(e)}")
        return None

def send_to_sqs(stock_data):
    try:
        message_body = json.dumps(stock_data)
        response = sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=message_body
        )
        print(f"Message sent to SQS for {stock_data['ticker']}. MessageId: {response['MessageId']}")
        return True
    except Exception as e:
        print(f"Error sending message to SQS: {str(e)}")
        return False

def lambda_handler(event, context):
    tickers = ["AAPL", "GOOG", "MSFT"]
    
    success_count = 0
    failed_count = 0
    
    for ticker in tickers:
        data = get_stock_quote(ticker)
        if data:
            print(f"Retrieved price for {ticker}: {data['price']} at {data['timestamp']}")  # Debug logging
            if send_to_sqs(data):
                success_count += 1
            else:
                failed_count += 1
        time.sleep(0.5)  # Respect rate limits
    
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Processing complete",
            "success_count": success_count,
            "failed_count": failed_count
        })
    }