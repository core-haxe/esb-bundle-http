package esb.bundles.core.http;

import haxe.io.Bytes;
import esb.core.bodies.RawBody;
import promises.Promise;
import haxe.Timer;
import esb.core.IBundle;
import esb.common.Uri;
import esb.core.IProducer;
import esb.logging.Logger;
import http.server.HttpServer;
import esb.core.Bus.*;

using StringTools;

@:keep
class HttpProducer implements IProducer {
    private static var log:Logger = new Logger("esb.bundles.core.http.HttpProducer");

    private var httpServer:HttpServer = null;

    public var bundle:IBundle;
    public function start(uri:Uri) {
        log.info('creating producer for ${uri.toString()}');

        httpServer = new HttpServer();
        httpServer.onRequest = (httpRequest, httpResponse) -> {
            return new Promise((resolve, reject) -> {
                var message = createMessage(RawBody);
                if (httpRequest.body != null) {
                    message.body.fromBytes(Bytes.ofString(Std.string(httpRequest.body)));
                }
                if (httpRequest.headers != null) {
                    for (header in httpRequest.headers.keys()) {
                        var value = httpRequest.headers.get(header);
                        message.headers.set(header, value);
                    }
                }

                message.properties.set("http.path", httpRequest.url.path);
                message.properties.set("http.verb", Std.string(httpRequest.method).toLowerCase());
                if (httpRequest.queryParams != null) {
                    for (param in httpRequest.queryParams.keys()) {
                        var value = httpRequest.queryParams.get(param);
                        message.headers.set(param, value);
                    }
                }

                to(uri, message).then(response -> {
                    var responseBody = response.body.toString();
                    if (responseBody == null) {
                        responseBody = "";
                    }
                    var httpStatus:Null<Int> = null;
                    if (response.properties.exists("http.status")) {
                        httpStatus = response.properties.get("http.status");
                    }
                    if (httpStatus != null) {
                        httpResponse.httpStatus = httpStatus;
                    }
                    httpResponse.write(responseBody);
                    resolve(httpResponse);
                }, error -> {
                    trace("error", error);
                    httpResponse.httpStatus = 500;
                    httpResponse.write("error: ", error);
                    resolve(httpResponse);
                });
            });
        };

        var port:Int = 80;
        if (uri.port != null) {
            port = uri.port;
        }
        log.info('http server listening for incoming messages in port ${port}');
        httpServer.start(port);
    }
}