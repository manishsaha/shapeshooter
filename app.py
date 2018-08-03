from flask import Flask, render_template, url_for

app = Flask(__name__)

def run():
  app.run(host='0.0.0.0', port=5000, debug=True)

@app.route('/')
def root():
  return render_template('index.html')

if __name__ == '__main__':
  run()
