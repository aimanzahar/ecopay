import requests
import json

API_KEY = "cooler_test_e00a451a-1321-46fa-ad43-8a2695ea17a2"  # Your Cooler test key
ENDPOINT = "https://api.cooler.dev/v2/footprint/products"

HEADERS = {
    "Content-Type": "application/json",
    "Cooler-Api-Key": API_KEY
}

# Example product categories
items = [
    {
        "productName": "Beef Burger",
        "productDescription": "Grilled beef burger with lettuce and cheese",
        "productPrice": 15.00,
        "postalCode": "50000",  # Kuala Lumpur
        "newProduct": True,
        "externalId": "burger-kl-001"
    },
    {
        "productName": "Tofu",
        "productDescription": "Organic tofu block, 500g",
        "productPrice": 5.00,
        "postalCode": "43000",  # Kajang
        "newProduct": True,
        "externalId": "tofu-kj-002"
    }
]

payload = {
    "items": items
}

print("🔍 Hitting Cooler API v2/footprint/products…\n")

response = requests.post(ENDPOINT, headers=HEADERS, json=payload, timeout=10)

print("Status:", response.status_code)
try:
    print("📝 Raw JSON Response:\n", json.dumps(response.json(), indent=2))
except Exception as e:
    print("Failed to parse JSON:", e)
    print(response.text)
