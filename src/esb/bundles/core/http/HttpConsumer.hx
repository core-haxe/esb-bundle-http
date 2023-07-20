package esb.bundles.core.http;

import esb.core.IBundle;
import esb.common.Uri;
import esb.core.IConsumer;
import esb.logging.Logger;

using StringTools;

@:keep
class HttpConsumer implements IConsumer {
    private static var log:Logger = new Logger("esb.bundles.core.files.HttpConsumer");

    public var bundle:IBundle;
    public function start(uri:Uri) {
    }
}