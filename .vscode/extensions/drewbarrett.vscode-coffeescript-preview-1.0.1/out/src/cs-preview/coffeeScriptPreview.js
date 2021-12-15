'use strict';
var os = require("os");
var vscode_1 = require("vscode");
var utility = require("./utility");
var CoffeeScriptPreview = (function () {
    function CoffeeScriptPreview(provider, workspaceService, windowService) {
        this._delay = 500;
        this.generatePreviewUri = function (baseUrl) {
            var separator = os.platform() === "win32" ? "\\" : "//";
            return vscode_1.Uri.parse("coffeescript-preview:" + separator + baseUrl + ".js");
        };
        this._provider = provider;
        this._workspaceService = workspaceService;
        this._windowService = windowService;
    }
    CoffeeScriptPreview.prototype.start = function () {
        var _this = this;
        var debouncedUpdateContent = utility.debounce(this.updateContent, this._delay, this);
        return this._workspaceService.registerOnDocumentChangeListener(function (event) {
            if (_this.isValidDocument(event.document)) {
                debouncedUpdateContent(event.document.fileName);
            }
        });
    };
    CoffeeScriptPreview.prototype.updateContent = function (fileName) {
        var uri = this.generatePreviewUri(fileName);
        this._provider.updateContent(uri);
    };
    CoffeeScriptPreview.prototype.isValidDocument = function (document) {
        var activeTextEditor = this._windowService.getActiveTextEditor();
        return document.languageId === "coffeescript" && (activeTextEditor && document === activeTextEditor.document);
    };
    CoffeeScriptPreview.prototype.previewDocument = function () {
        var _this = this;
        var editor = this._windowService.getActiveTextEditor();
        var previewUri = this.generatePreviewUri(editor.document.fileName);
        return this._workspaceService.openTextDocument(previewUri).then(function (textDoc) { return _this.showTextDocument(textDoc); });
    };
    CoffeeScriptPreview.prototype.showTextDocument = function (textDoc) {
        var editor = this._windowService.getActiveTextEditor();
        var displayColumn = this.getDisplayColumn(editor.viewColumn);
        return this._windowService.showTextDocument(textDoc, displayColumn, true);
    };
    CoffeeScriptPreview.prototype.getDisplayColumn = function (currentColummn) {
        return (currentColummn === vscode_1.ViewColumn.Three ? vscode_1.ViewColumn.Two : currentColummn + 1);
    };
    return CoffeeScriptPreview;
}());
exports.CoffeeScriptPreview = CoffeeScriptPreview;
//# sourceMappingURL=coffeeScriptPreview.js.map