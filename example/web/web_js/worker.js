
const dbName = "app_db.db";
const storeName = "web_images";
let db;

let connections = {};


self.addEventListener("message", async function (messageEvent) {
    let method = messageEvent.data["method"];
    let id = messageEvent.data["id"];

    switch (method) {
        case "init":
            {
                try {
                    const request = indexedDB.open(dbName, 3);

                    request.onerror = (event) => {
                        self.postMessage({ "id": id, "error": `Database error: ${event.target.errorCode}` });
                    };

                    request.onsuccess = (event) => {
                        db = event.target.result;
                        self.postMessage({ "id": id, "result": "db opened", });
                    };

                    request.onupgradeneeded = (event) => {
                        event.target.result.createObjectStore(storeName, { autoIncrement: true });
                    };
                } catch (error) {
                    self.postMessage({ "id": id, "error": error.toString() });
                }
            }
            break;
        case "download":
            {
                let url = messageEvent.data["params1"];
                let headers = messageEvent.data["params2"];

                try {
                    let controller = new AbortController();

                    connections[url] = controller;

                    let fecthRequest = fetch(url, { method: 'GET', cache: 'no-store', signal: controller.signal });

                    if (headers != null) {
                        fecthRequest.headers = JSON.parse(headers);
                    }

                    let response = await fecthRequest;

                    if (!response.ok) {
                        if (response.status === 404) {
                            self.postMessage({ "id": id, "method": "download", "url": url, "error": "Image not found", });
                        } else {
                            self.postMessage({ "id": id, "method": "download", "url": url, "error": response, });
                        }

                        return;
                    }

                    var contentLength = Number(response.headers.get("content-length"));

                    if (contentLength == null) {
                        contentLength = 1;
                    }

                    let reader = response.body.getReader();

                    var res = new Uint8Array(0);

                    return readData();

                    function readData() {
                        return reader.read().then(function ({ value, done }) {

                            if (done) {
                                self.postMessage({ "id": id, "method": "download", "url": url, "result": res, });
                                return;
                            }

                            res = concatTypedArrays(res, value);

                            self.postMessage({ "id": id, "url": url, "method": "download", "result": res.length / contentLength, });

                            return readData();
                        });
                    }
                } catch (error) {
                    self.postMessage({ "id": id, "url": url, "method": "download", "error": error.toString(), });
                }

            }
            break;
        case "cancel_download":
            {
                let url = messageEvent.data["params1"];

                let controller = connections[url];

                if (controller != null) {
                    controller.abort();
                }
            }
            break;
        case "getAllKeys":
            {
                const transaction = db.transaction([storeName], "readonly");

                let store = transaction.objectStore(storeName);

                let res = await store.getAllKeys();

                await transaction.completed;

                res.onsuccess = (data) => {
                    this.self.postMessage({ "id": id, "result": data.target.result, });
                }

                res.onerror = (error) => {
                    this.self.postMessage({ "id": id, "error": error.toString() });
                }

            }
            break;
        case "clearCache":
            {
                const transaction = db.transaction([storeName], "readwrite");

                let store = transaction.objectStore(storeName);

                let res = await store.clear();

                await transaction.completed;

                res.onsuccess = (data) => {
                    this.self.postMessage({ "id": id, "result": data.target.result, });
                }

                res.onerror = (error) => {
                    this.self.postMessage({ "id": id, "error": error.toString() });
                }

            }
            break;
        case "addToCache":
            {
                let imageBytes = messageEvent.data["params1"];
                let key = messageEvent.data["params2"];

                const transaction = db.transaction([storeName], "readwrite");

                let store = transaction.objectStore(storeName);

                let res = await store.put(imageBytes, key);

                await transaction.completed;

                res.onerror = (error) => {
                    this.self.postMessage({ "id": id, "error": error.toString() });
                }
                
                res.onsuccess = (data) => {
                    this.self.postMessage({ "id": id, "result": "success" });
                }
            }
            break;
        case "getImage":
            {
                let key = messageEvent.data["params1"];

                const transaction = db.transaction([storeName], "readonly");

                let store = transaction.objectStore(storeName);

                let res = await store.get(key);

                await transaction.completed;

                res.onsuccess = (data) => {
                    this.self.postMessage({ "id": id, "result": data.target.result });
                }

                res.onerror = (error) => {
                    this.self.postMessage({ "id": id, "error": error.toString() });
                }
            }
            break;
        default:
            self.postMessage({ "id": id, "result": "unhandeled request" });
            break;
    }
});

function concatTypedArrays(a, b) {
    var c = new (a.constructor)(a.length + b.length);
    c.set(a, 0);
    c.set(b, a.length);
    return c;
}