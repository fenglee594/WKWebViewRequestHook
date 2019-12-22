document.addEventListener( "DOMContentLoaded", function(){
    cachersetting();
});

function cachersetting() {
//    log("hooked!");
    
    var forms = document.forms;
    for (var i=0; i< forms.length; i+=1) {
        form = forms[i];
        form.oldsubmit = form.submit;
        form.submit = function() {
//            log("new submit call!");
            var method = $("form").attr("method").toLowerCase();
            var values = $("form").serialize().split("&");
            var url = $("form").attr("action").toLowerCase();
            if (method == "post") {
                log("url: "+url);
                log("post data:"+values.join("&"));
                sendPostContentToiOS(url, values);
                log("send data end");
            }
            form.oldsubmit();
        }
    }

    hookAjax({
        open: function(arg,xhr) {
             httpMethod = arg[0];
             if (httpMethod.toLowerCase() == "post") {
//                log("post found");
                xhr.requesturl = arg[1];
                if (xhr.requesturl.length <= 4) {
                    xhr.requesturl = window.location.host+xhr.requesturl;
                }

                prefix = xhr.requesturl.substring(0,4);
//                log("prefix: "+prefix);
//                log("request url: "+xhr.requesturl);
                if (prefix != "http") {
                    xhr.requesturl = window.location.origin+xhr.requesturl;
                }
//                log("full path: "+xhr.requesturl);
             };
             return false;
        },
    
        send: function(arg,xhr) {
            if (xhr.requesturl != null && arg.length > 0) {
//                log("arg length:")
//                log(arg.length)
//                log(typeof(arg))
//                log(window.btoa(arg))
                sendPostContentToiOS(xhr.requesturl, arg);
                xhr.requesturl = null;
            };
             return false;
        }
    });
    
}

function unregisterajax() {
    unHookAjax();
}

function log(str) {
    window.webkit.messageHandlers["log"].postMessage(str);
}

function sendPostContentToiOS(url, data) {
//    log("enter send post content to iOS");
    var sendData = {};
    sendData.key = url;
    sendData.value = data;//.join("&");
//    log(data[0].constructor.name)
//    window.webkit.messageHandlers["save"].postMessage(JSON.stringify(sendData));
    window.webkit.messageHandlers["save"].postMessage(sendData);
//    if (url.indexOf("authToken")>=0) {
//        for(var i=0; i<data.length;i++){
//            log("authToken type")
//            log(typeof(data[i]));
////            log(data[i])
//        }
//    }
    
//    log("end send post content to iOS");
}
