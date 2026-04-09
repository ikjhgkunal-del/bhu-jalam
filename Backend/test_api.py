import requests

BASE_URL = "http://localhost:8000"   # change if using ngrok or emulator

def test_extras(district, block):
    url = f"{BASE_URL}/extras"
    params = {"district": district, "block": block}
    try:
        resp = requests.get(url, params=params, timeout=10)
        print(f"\n🔹 GET {url} with {params}")
        print(f"Status: {resp.status_code}")
        if resp.status_code == 200:
            data = resp.json()
            # only print keys, not full data
            print("✅ Keys returned:", list(data.keys()))
            # preview values
            for k, v in data.items():
                print(f"  {k}: {str(v)[:80]}{'...' if len(str(v)) > 80 else ''}")
        else:
            print("❌ Error response:", resp.text)
    except Exception as e:
        print("❌ Request failed:", e)


if __name__ == "__main__":
    # try with one known block in your DB
    test_extras("Badaun", "Ambiapur Block Development Office")
