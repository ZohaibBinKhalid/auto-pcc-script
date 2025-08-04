# Step 1: Encoded Base64 Script (auto-pcc.rsc content hidden inside)
:local encodedScript "
IyBVc2VyIElucHV0DQo6bG9jYWwgdG90YWxMaW5lcyAiIg0KOmxvY2FsIGJhc2VJbnRlcmZhY2Ug
IiINCjpsb2NhbCByZWFkaW5wdXQgZG89ezpyZXR1cm59DQoNCi9wdXQgIlxuPz8gRW50ZXIgbnVt
YmVyIG9mIGxpbmVzOiINCjpzZXQgdG90YWxMaW5lcyBbJHJlYWRpbnB1dF0NCg0KL3B1dCAiXG4/
PyBFbnRlciBiYXNlIGludGVyZmFjZSAoZS5nLiwgZXRoZXIyKToiDQovc2V0IGJhc2VJbnRlcmZh
Y2UgWyRyZWFkaW5wdXRdDQoNCiMgQ3JlYXRlIFdBTiBpbnRlcmZhY2UgbGlzdCBpZiBub3QgZXhp
c3QNCjppZiAoWzpsZW4gWy9pbnRlcmZhY2UgbGlzdCBmaW5kIG5hbWU9IldBTiJdXSA9IDApIGRv
PXsNCiAgICAvaW50ZXJmYWNlIGxpc3QgYWRkIG5hbWU9IldBTiIgY29tbWVudD0iV0FOIEludGVy
ZmFjZXMgZm9yIFBDQyINCn0NCg0KIyBBZGQgUm91dGluZyBUYWJsZXMNCjpmb3IgaSBmcm9tPTEg
dG89JHRvdGFsTGluZXMgZG89ew0KICAgIDpsb2NhbCBydG5hbWUgKCJ0by13YW4iIC4gKWkNCiAg
ICA6aWYgKFt... (truncated)
"

# Step 2: Decode & Save to File
:local decodedFileName "auto-pcc-decoded.rsc"
/file remove [find name=$decodedFileName]
/tool fetch url=("data:application/octet-stream;base64," . $encodedScript) mode=https output=$decodedFileName

# Step 3: Import & Run Script
/import file-name=$decodedFileName

# Step 4: Show Success Message
:delay 1
/put "\n✅ Script installed successfully!"

# Step 5: Delete the temporary decoded script
:delay 2
/file remove [find name=$decodedFileName]
