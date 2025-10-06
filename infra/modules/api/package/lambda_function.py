import json, os
TABLE = os.environ.get("TABLE_NAME")
def handler(event, context):
    route = event.get("requestContext",{}).get("http",{}).get("path","")
    if route.endswith("/progress"):
        return {"statusCode":200,"body":json.dumps({"ok":True,"message":"progress-stub"})}
    elif route.endswith("/tutor-match"):
        body = {"ok": True, "tutors": [{"name":"Alice","style":"Calm, Visual"},{"name":"Bob","style":"Energetic, Kinesthetic"}]}
        return {"statusCode":200,"body":json.dumps(body)}
    return {"statusCode":404,"body":json.dumps({"ok":False,"error":"Unknown route"})}
