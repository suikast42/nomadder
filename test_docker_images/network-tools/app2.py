import os
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/', methods=['GET'])
def helloworld():
    a = "Hello from 5001"
    b = os.environ['NOMAD_ALLOC_NAME']
    message = a + " " + b
    return jsonify(message)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)