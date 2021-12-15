"use strict";
var coffeescript = require("coffeescript");
var vscode_1 = require("vscode");
var CoffeeScriptPreviewContentProvider = (function () {
    function CoffeeScriptPreviewContentProvider(windowService) {
        this._onDidChange = new vscode_1.EventEmitter();
        this._windowService = windowService;
    }
    Object.defineProperty(CoffeeScriptPreviewContentProvider.prototype, "onDidChange", {
        get: function () {
            return this._onDidChange.event;
        },
        enumerable: true,
        configurable: true
    });
    CoffeeScriptPreviewContentProvider.prototype.updateContent = function (uri) {
        this._onDidChange.fire(uri);
    };
    CoffeeScriptPreviewContentProvider.prototype.provideTextDocumentContent = function (uri) {
        var editor = this._windowService.getActiveTextEditor();
        if (editor) {
            return this.getDisplayContents(editor);
        }
    };
    CoffeeScriptPreviewContentProvider.prototype.getDisplayContents = function (editor) {
        var output = "";
        try {
            var text = this.getDocumentContent(editor);
            output = coffeescript.compile(text, { bare: true });
        }
        catch (error) {
            output = this.generateErrorMessage(error);
        }
        return output;
    };
    CoffeeScriptPreviewContentProvider.prototype.getDocumentContent = function (editor) {
        return editor.document.getText();
    };
    CoffeeScriptPreviewContentProvider.prototype.generateErrorMessage = function (error) {
        return "Error: " + error.message + "; line: " + (error.location.first_line + 1) + ", column: " + (error.location.first_column + 1) + "]";
    };
    return CoffeeScriptPreviewContentProvider;
}());
exports.CoffeeScriptPreviewContentProvider = CoffeeScriptPreviewContentProvider;
//# sourceMappingURL=coffeeScriptPreviewContentProvider.js.map