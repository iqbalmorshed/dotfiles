'use strict';
var vscode_1 = require("vscode");
var WindowService = (function () {
    function WindowService() {
    }
    WindowService.prototype.showTextDocument = function (textDoc, column, preserveFocus) {
        return vscode_1.window.showTextDocument(textDoc, column, preserveFocus);
    };
    WindowService.prototype.getActiveTextEditor = function () {
        return vscode_1.window.activeTextEditor;
    };
    return WindowService;
}());
exports.WindowService = WindowService;
//# sourceMappingURL=windowService.js.map