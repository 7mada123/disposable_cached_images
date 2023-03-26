let curId = 0;

let promisesMap = {};

window.jsInvokeMethod = async (method, params1, params2) => {
    let resol;

    let res = new Promise((resolve) => {
        resol = resolve;
    });


    promisesMap[curId] = resol;


    sendMessageToWorker(method, params1, params2);

    return res;
}

window.jsInvokeDownloadMethod = async (method, params1, params2) => {
    sendMessageToWorker(method, params1, params2);
}

const worker = new Worker("web_js/worker.js");

function sendMessageToWorker(method, params1, params2) {
    worker.postMessage({ "method": method, "id": curId, "params1": params1, "params2": params2 });

    curId++;
}

worker.addEventListener("message", function (messageEvent) {
    if (messageEvent.data["method"] === "download") {
        let res = messageEvent.data["result"];
        delete messageEvent.data["result"];
        window.downloadStream(JSON.stringify((messageEvent.data)), res);
    } else {
        promisesMap[messageEvent.data["id"]](messageEvent.data);

        delete promisesMap[messageEvent.data["id"]];
    }
});