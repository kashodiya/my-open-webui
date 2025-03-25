
## This is a quick and non-dirty web app and API server
- The server is run using 2 files (the ultimate minimalism)
    - app.py -> Server
    - index.html -> Client
- What do I mean by 'non-dirty'?
    - The client uses VueJs + Vuetify.
    - Even though it is single HTML file, the app is a rick SPA (Single Page Application)

## To install packages
```bash
pip install -r requirements.txt
```

## To run
```bash
flask run --debug
```

## Notes
- For development run this app on Windows workspace. 
- When testing is over copy and run on server.