import json
import urllib.request
import urllib.parse
import os

def lambda_handler(event, context):
    
    bot_token = os.environ['TELEGRAM_BOT_TOKEN']
    chat_id = os.environ['TELEGRAM_CHAT_ID']

    sns_message = event['Records'][0]['Sns']['Message']
    
    parsed_message = json.loads(sns_message)
    
    alarm_name = parsed_message.get('AlarmName', 'Alarma Desconocida')
    new_state = parsed_message.get('NewStateValue', 'ALARM')
    reason = parsed_message.get('NewStateReason', 'Sin detalles detectados')

    texto_telegram = f"🚨 *AWS ALERTA CRÍTICA: {alarm_name}* 🚨\n\n*Estado:* {new_state}\n*Motivo:* {reason}"

    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    
    data = urllib.parse.urlencode({
        'chat_id': chat_id,
        'text': texto_telegram,
        'parse_mode': 'Markdown'
    }).encode('utf-8')

    try:
        req = urllib.request.Request(url, data=data, method='POST')
        with urllib.request.urlopen(req) as response:
            print(f"Éxito. Telegram respondió: {response.status}")
    except Exception as e:
        print(f"Error crítico conectando con Telegram: {e}")
        raise e
    
    return {
        'statusCode': 200,
        'body': json.dumps('Alerta procesada y disparada por Lambda.')
    }