package esb.bundles.core.http;

import esb.core.bodies.JsonBody;
import haxe.io.Bytes;
import http.HttpMethod;
import http.HttpRequest;
import http.HttpClient;
import promises.Promise;
import esb.core.IBundle;
import esb.common.Uri;
import esb.core.IConsumer;
import esb.logging.Logger;
import esb.core.Bus.*;
import esb.core.BusProperties;

using StringTools;

@:keep
class HttpConsumer implements IConsumer {
    private static var log:Logger = new Logger("esb.bundles.core.files.HttpConsumer");

    public var bundle:IBundle;
    public function start(uri:Uri) {
        log.info('creating consumer for ${uri.toString()}');
        from(uri, (uri, message) -> {
            return new Promise((resolve, reject) -> {
                var requestUrl:String = message.properties.get(BusProperties.DestinationUri);

                var httpRequest:HttpRequest = new HttpRequest(requestUrl);
                httpRequest.method = HttpMethod.Get;

                var httpRequestHeaders:Map<String, Any> = [];
                httpRequestHeaders.set("User-Agent", "esb");

                var httpRequestBody:Any = null;

                var httpClient = new HttpClient();
                httpClient.makeRequest(httpRequest, httpRequestBody, null, httpRequestHeaders).then(result -> {
                    trace(result.response.httpStatus, result.response.bodyAsString);
                    var stringResponse = result.response.bodyAsString;
                    if (stringResponse != null) {
                        message.body.fromBytes(Bytes.ofString(stringResponse));
                    }
                    trace(result.response.headers);
                    var contentType:String = null;
                    if (result.response.headers.exists("content-type")) {
                        contentType = result.response.headers.get("content-type");
                    }

                    if (contentType != null && contentType.contains(";")) {
                        var n = contentType.indexOf(";");
                        contentType = contentType.substring(0, n).trim();
                    }

                    switch (contentType) {
                        case "application/json":
                            var jsonMessage = convertMessage(message, JsonBody);
                            resolve(cast jsonMessage);
                        case _:    
                            resolve(message);
                    }
                    return null;
                }, error -> {
                    trace("error", error);
                    // TODO: handle errors better
                    resolve(message);
                });
            });
        });
    }
}