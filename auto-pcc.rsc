# Step 1: Base64-encoded script
:local encodedScript "
IyBVc2VyIElucHV0DQo6bG9jYWwgdG90YWxMaW5lcyAiIg0KOmxvY2FsIGJhc2VJbnRlcmZhY2Ug
IiINCjpsb2NhbCByZWFkaW5wdXQgZG89ezpyZXR1cm59DQoNCi9wdXQgIlxuPz8gRW50ZXIgbnVt
YmVyIG9mIGxpbmVzOiINCjpzZXQgdG90YWxMaW5lcyBbJHJlYWRpbnB1dF0NCg0KL3B1dCAiXG4/
PyBFbnRlciBiYXNlIGludGVyZmFjZSAoZS5nLiwgZXRoZXIyKToiDQovc2V0IGJhc2VJbnRlcmZh
Y2UgWyRyZWFkaW5wdXRdDQo=  ; <<=== SHORTENED EXAMPLE, use full encoded script here
"

# Step 2: Decode using fetch with output=user
:local decodedFileName "auto-pcc-decoded.rsc"
/file remove [find name=$decodedFileName]

:local result [/tool fetch url=("data:application/octet-stream;base64," . $encodedScript) mode=https output=user as-value]
:local content ($result->"data")

/file print file=$decodedFileName
:delay 1
/file set [find name=$decodedFileName] contents=$content

# Step 3: Import the script
/import file-name=$decodedFileName

# Step 4: Success message
:delay 1
/put "\n Script installed successfully!"

# Step 5: Cleanup
:delay 2
/file remove [find name=$decodedFileName]
