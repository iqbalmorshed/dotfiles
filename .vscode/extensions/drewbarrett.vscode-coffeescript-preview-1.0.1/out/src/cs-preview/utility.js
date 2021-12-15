'use strict';
function debounce(func, wait, context) {
    var timeout;
    var result;
    var delayedCall = function (args) {
        timeout = null;
        result = func.apply(context, args);
    };
    var debounced = function (any) {
        if (timeout)
            clearTimeout(timeout);
        timeout = setTimeout(delayedCall, wait, arguments);
        return result;
    };
    return debounced;
}
exports.debounce = debounce;
;
//# sourceMappingURL=utility.js.map