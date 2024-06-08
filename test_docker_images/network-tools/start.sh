export FLASK_APP=app.py
python3 -m flask run --host=0.0.0.0 --port 5000 &

export FLASK_APP=app2.py
python3 -m flask run --host=0.0.0.0 --port 5001