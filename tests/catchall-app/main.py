# cf. https://stackoverflow.com/questions/63069190/how-to-capture-arbitrary-paths-at-one-route-in-fastapi

from fastapi import FastAPI, Request

app = FastAPI()

@app.get("/{full_path:path}")
def catch_all(req: Request, full_path: str):
    return {"host" : req._headers.get('host'), "path": full_path}
    #return {"path" : full_path, "query": req._query_params, "headers": req._headers}
