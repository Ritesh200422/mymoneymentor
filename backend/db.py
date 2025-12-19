import os
import firebase_admin
from firebase_admin import credentials, firestore

# Dynamically build path relative to this file’s location
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
cred_path = os.path.join(BASE_DIR, "my-money-mentor-1a14f-firebase-adminsdk-fbsvc-a8206eb4a4.json")

# Initialize Firebase only once
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

# Firestore client
db = firestore.client()
