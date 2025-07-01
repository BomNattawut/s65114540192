import json
import os
from google.oauth2.credentials import Credentials # type: ignore



def load_credentials(user_id):
    """ โหลด Credentials ตาม User ID """
    print(f'userid:{user_id}')
    token_path = f"D:/Seniaproject/backend-django/backend/Smartwityouapp/tokens/user_{user_id}.json"
    
    if os.path.exists(token_path):
        with open(token_path, "r") as token_file:
            token_data = json.load(token_file)
        
        creds = Credentials(
            token=token_data["token"],
            refresh_token=token_data["refresh_token"],
            token_uri=token_data["token_uri"],
            client_id=token_data["client_id"],
            client_secret=token_data["client_secret"],
        )
        return creds
    return None